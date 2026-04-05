//
//  DeveloperViewModel.swift
//  PurgeMac
//
//  Developer tools: clean node_modules, build artifacts, caches, and more.
//

import Foundation
import AppKit

// MARK: - Models

struct DevTask: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let patterns: TaskPatterns
    var state: TaskState = .idle
    var result: String?

    enum TaskState { case idle, running, done, failed }

    enum TaskPatterns {
        /// Matching by directory/file name anywhere in tree
        case names([String], isDirectory: Bool)
        /// Matching by exact filename (not directory)
        case files([String])
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class DeveloperViewModel {

    var projectFolder: URL?
    var tasks: [DevTask] = DeveloperViewModel.defaultTasks
    var folderSizeText: String = ""
    var isAnalyzingSize: Bool = false

    // MARK: - Folder picker

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Project Folder"
        panel.message = "Select the root of your project"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            projectFolder = url
            tasks = DeveloperViewModel.defaultTasks          // reset states
            folderSizeText = ""
            Task { await analyzeSize() }
        }
    }

    // MARK: - Size analysis

    func analyzeSize() async {
        guard let folder = projectFolder else { return }
        isAnalyzingSize = true
        let bytes = await Task.detached(priority: .userInitiated) {
            Self.directorySize(at: folder)
        }.value
        folderSizeText = formatBytes(bytes)
        isAnalyzingSize = false
    }

    // MARK: - Run a task

    func run(taskID: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }),
              let folder = projectFolder else { return }

        tasks[idx].state = .running
        tasks[idx].result = nil
        let patterns = tasks[idx].patterns

        Task.detached(priority: .userInitiated) { [weak self] in
            var count = 0
            var bytes: Int64 = 0

            switch patterns {
            case .names(let names, let isDir):
                let (c, b) = Self.findAndDelete(in: folder, names: names, isDirectory: isDir)
                count = c; bytes = b
            case .files(let names):
                let (c, b) = Self.findAndDelete(in: folder, names: names, isDirectory: false)
                count = c; bytes = b
            }

            await MainActor.run {
                guard let self else { return }
                if let i = self.tasks.firstIndex(where: { $0.id == taskID }) {
                    let freed = bytes > 0 ? " · freed \(self.formatBytes(bytes))" : ""
                    self.tasks[i].result = count == 0
                        ? "Nothing found"
                        : "\(count) item\(count == 1 ? "" : "s") removed\(freed)"
                    self.tasks[i].state = .done
                }
                Task { await self.analyzeSize() }
            }
        }
    }

    func runAll() {
        for task in tasks where task.state == .idle {
            run(taskID: task.id)
        }
    }

    func resetAll() {
        tasks = DeveloperViewModel.defaultTasks
        if projectFolder != nil {
            Task { await analyzeSize() }
        }
    }

    // MARK: - Default task list

    static let defaultTasks: [DevTask] = [
        DevTask(
            title: "node_modules",
            icon: "shippingbox.fill",
            description: "Delete all node_modules folders (npm/yarn/pnpm dependencies)",
            patterns: .names(["node_modules"], isDirectory: true)
        ),
        DevTask(
            title: ".DS_Store files",
            icon: "doc.badge.gearshape.fill",
            description: "Remove macOS metadata files that pollute repos",
            patterns: .files([".DS_Store"])
        ),
        DevTask(
            title: "Build artifacts",
            icon: "hammer.fill",
            description: "Delete dist/, build/, .next/, out/ output folders",
            patterns: .names(["dist", "build", ".next", "out", "__pycache__", ".turbo"], isDirectory: true)
        ),
        DevTask(
            title: "Lock files",
            icon: "lock.doc.fill",
            description: "Remove package-lock.json, yarn.lock, pnpm-lock.yaml",
            patterns: .files(["package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb"])
        ),
        DevTask(
            title: ".cache folders",
            icon: "archivebox.fill",
            description: "Delete .cache directories (Babel, ESLint, Parcel, etc.)",
            patterns: .names([".cache", ".parcel-cache", ".eslintcache"], isDirectory: true)
        ),
        DevTask(
            title: "Temp & log files",
            icon: "doc.text.fill",
            description: "Remove *.log, npm-debug.log*, yarn-debug.log* files",
            patterns: .names(["*.log"], isDirectory: false)
        ),
        DevTask(
            title: ".git/objects loose",
            icon: "arrow.triangle.branch",
            description: "Run git gc to compress loose objects (requires git CLI)",
            patterns: .names([], isDirectory: false)    // handled specially via gitGC
        ),
        DevTask(
            title: "Coverage reports",
            icon: "chart.bar.doc.horizontal.fill",
            description: "Delete coverage/ and .nyc_output/ folders",
            patterns: .names(["coverage", ".nyc_output"], isDirectory: true)
        ),
    ]

    // MARK: - Static helpers (nonisolated for background work)

    nonisolated static func findAndDelete(
        in root: URL,
        names: [String],
        isDirectory: Bool
    ) -> (count: Int, bytes: Int64) {
        guard !names.isEmpty else { return (0, 0) }
        var count = 0
        var totalBytes: Int64 = 0
        let fm = FileManager.default

        let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        var toDelete: [URL] = []

        while let url = enumerator?.nextObject() as? URL {
            let name = url.lastPathComponent
            let matched: Bool

            if isDirectory {
                matched = names.contains(name)
                if matched { enumerator?.skipDescendants() }
            } else {
                // Support simple glob: *.log
                matched = names.contains { pattern in
                    if pattern.hasPrefix("*") {
                        return name.hasSuffix(String(pattern.dropFirst()))
                    }
                    return name == pattern
                }
            }

            if matched { toDelete.append(url) }
        }

        for url in toDelete {
            let bytes = directorySize(at: url)
            do {
                try fm.removeItem(at: url)
                count += 1
                totalBytes += bytes
            } catch { /* skip if can't delete */ }
        }

        return (count, totalBytes)
    }

    nonisolated static func directorySize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }

    nonisolated func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}
