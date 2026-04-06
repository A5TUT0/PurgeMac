//
//  DownloadsViewModel.swift
//  PurgeMac
//
//  Lists and deletes files from Downloads folder.
//

import Foundation
import AppKit

@Observable
@MainActor
final class DownloadsViewModel {
    var files: [DownloadFile] = []
    var isLoading = false
    var downloadsURL: URL?
    var sortOrder: SortOrder = .dateDescending

    enum SortOrder: String, CaseIterable, Identifiable {
        case dateDescending  = "Newest First"
        case dateAscending   = "Oldest First"
        case sizeDescending  = "Largest First"
        case sizeAscending   = "Smallest First"
        case name            = "Name A–Z"
        var id: String { rawValue }
    }

    var sorted: [DownloadFile] {
        switch sortOrder {
        case .dateDescending: return files.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAscending:  return files.sorted { $0.dateAdded < $1.dateAdded }
        case .sizeDescending: return files.sorted { $0.size > $1.size }
        case .sizeAscending:  return files.sorted { $0.size < $1.size }
        case .name:           return files.sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }

    var selected: [DownloadFile] { files.filter(\.isSelected) }
    var totalSize: Int64  { files.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { selected.reduce(0) { $0 + $1.size } }
    var allSelected: Bool { !files.isEmpty && files.allSatisfy(\.isSelected) }

    // MARK: - Public

    func loadDefaults() {
        if let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            load(from: url)
        }
    }

    func load(from url: URL) {
        isLoading = true
        downloadsURL = url
        files = []

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.readFiles(at: url)
                    continuation.resume(returning: r)
                }
            }
            self.files = result
            self.isLoading = false
        }
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories   = true
        panel.canChooseFiles         = false
        panel.message = "Choose your Downloads folder"
        panel.prompt  = "Open"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        load(from: url)
    }

    func toggleFile(_ file: DownloadFile) {
        guard let i = files.firstIndex(where: { $0.id == file.id }) else { return }
        files[i].isSelected.toggle()
    }

    func toggleAll() {
        let target = !allSelected
        for i in files.indices { files[i].isSelected = target }
    }

    func deleteSelected() {
        let fm = FileManager.default
        for f in selected { try? fm.trashItem(at: f.url, resultingItemURL: nil) }
        files.removeAll { $0.isSelected }
    }

    func revealInFinder(_ file: DownloadFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    // MARK: - Private

    nonisolated static func readFiles(at url: URL) -> [DownloadFile] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .addedToDirectoryDateKey, .isRegularFileKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents.compactMap { fileURL in
            guard
                let rv = try? fileURL.resourceValues(forKeys: [
                    .fileSizeKey, .addedToDirectoryDateKey, .isRegularFileKey
                ]),
                rv.isRegularFile == true
            else { return nil }
            return DownloadFile(
                url: fileURL,
                size: Int64(rv.fileSize ?? 0),
                dateAdded: rv.addedToDirectoryDate ?? Date(),
                fileExtension: fileURL.pathExtension
            )
        }
    }
}
