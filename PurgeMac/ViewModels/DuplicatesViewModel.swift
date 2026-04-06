//
//  DuplicatesViewModel.swift
//  PurgeMac
//
//  Scans for duplicate files using SHA-256 hashing.
//

import Foundation
import CryptoKit
import AppKit

@Observable
@MainActor
final class DuplicatesViewModel {
    var groups: [DuplicateGroup] = []
    var isScanning = false
    var scanProgress: Double = 0
    var statusMessage = "Ready to scan."
    var filesScanned = 0
    var scannedDirectory: URL?

    var totalSavings: Int64 { groups.reduce(0) { $0 + $1.potentialSavings } }
    var selectedCount: Int  { groups.reduce(0) { $0 + $1.selectedCount } }

    // MARK: - Public

    func scan(directory: URL) {
        scannedDirectory = directory
        startScan(directory)
    }

    func rescan() {
        guard let url = scannedDirectory else { return }
        startScan(url)
    }

    func toggleFile(groupIndex: Int, fileIndex: Int) {
        groups[groupIndex].files[fileIndex].isSelected.toggle()
    }

    func deleteSelected() {
        let fm = FileManager.default
        var indicesToRemove: [Int] = []

        for (gi, group) in groups.enumerated() {
            let toDelete = group.files.filter { $0.isSelected }
            for f in toDelete { try? fm.trashItem(at: f.url, resultingItemURL: nil) }

            let remaining = group.files.filter { !$0.isSelected }
            if remaining.count <= 1 {
                indicesToRemove.append(gi)
            } else {
                groups[gi].files = remaining
            }
        }
        for i in indicesToRemove.sorted().reversed() { groups.remove(at: i) }
        statusMessage = "Deleted. \(groups.count) group(s) remain."
    }

    // MARK: - Private

    private func startScan(_ url: URL) {
        isScanning = true
        groups      = []
        filesScanned = 0
        scanProgress = 0
        statusMessage = "Scanning…"

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.perform(scanAt: url)
                    continuation.resume(returning: r)
                }
            }
            self.groups       = result.groups
            self.filesScanned = result.count
            self.isScanning   = false
            self.scanProgress = 1.0
            self.statusMessage = result.groups.isEmpty
                ? "No duplicates found in \(url.lastPathComponent)."
                : "Found \(result.groups.count) duplicate group(s) — \(formatBytes(result.groups.reduce(0) { $0 + $1.potentialSavings })) recoverable."
        }

        Task {
            while isScanning {
                try? await Task.sleep(for: .milliseconds(80))
                if scanProgress < 0.9 { scanProgress += 0.012 }
            }
        }
    }

    nonisolated static func perform(scanAt directory: URL) -> (groups: [DuplicateGroup], count: Int) {
        let fm = FileManager.default
        var sizeMap: [Int64: [URL]] = [:]
        var count = 0

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return ([], 0) }

        for case let fileURL as URL in enumerator {
            guard
                let rv   = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                rv.isRegularFile == true,
                let size = rv.fileSize, size > 512
            else { continue }
            sizeMap[Int64(size), default: []].append(fileURL)
            count += 1
        }

        var resultGroups: [DuplicateGroup] = []

        for (size, urls) in sizeMap where urls.count > 1 {
            var hashMap: [String: [URL]] = [:]
            for url in urls {
                if let h = computeHash(url) { hashMap[h, default: []].append(url) }
            }
            for (_, dupeURLs) in hashMap where dupeURLs.count > 1 {
                var files: [DuplicateFile] = dupeURLs.map { url in
                    var f = DuplicateFile(url: url)
                    f.size = Int64(size)
                    let rv2 = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                    f.dateModified = rv2?.contentModificationDate ?? Date()
                    return f
                }
                files.sort { $0.dateModified > $1.dateModified }
                for i in 1..<files.count { files[i].isSelected = true }
                resultGroups.append(DuplicateGroup(files: files, fileSize: Int64(size)))
            }
        }

        resultGroups.sort { $0.potentialSavings > $1.potentialSavings }
        return (resultGroups, count)
    }

    nonisolated static func computeHash(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while
            let chunk = try? handle.read(upToCount: 65_536),
            !chunk.isEmpty
        {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
