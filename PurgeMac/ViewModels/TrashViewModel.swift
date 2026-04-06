//
//  TrashViewModel.swift
//  PurgeMac
//
//  Reads and manages the user's Trash contents.
//

import Foundation
import AppKit

@Observable
@MainActor
final class TrashViewModel {

    var items: [TrashItem] = []
    var isLoading = false
    var totalSize: Int64 = 0
    var itemCount: Int = 0

    // MARK: - Public

    func load() {
        isLoading = true

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.readTrash()
                    continuation.resume(returning: r)
                }
            }
            self.items = result.items
            self.totalSize = result.totalSize
            self.itemCount = result.items.count
            self.isLoading = false
        }
    }

    func emptyTrash() {
        // Use NSWorkspace to perform the operation
        let script = NSAppleScript(source: "tell application \"Finder\" to empty trash")
        var error: NSDictionary?
        script?.executeAndReturnError(&error)

        // Reload
        load()
    }

    func toggleItem(_ item: TrashItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isSelected.toggle()
    }

    var selectedCount: Int { items.filter(\.isSelected).count }
    var selectedSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }

    // MARK: - Private

    nonisolated static func readTrash() -> (items: [TrashItem], totalSize: Int64) {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let trashURL = home.appendingPathComponent(".Trash")

        guard let contents = try? fm.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return ([], 0) }

        var items: [TrashItem] = []
        var totalSize: Int64 = 0

        for url in contents {
            let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
            let isDir = rv?.isDirectory ?? false
            let size: Int64

            if isDir {
                // Calculate directory size
                size = directorySize(at: url, fm: fm)
            } else {
                size = Int64(rv?.fileSize ?? 0)
            }

            totalSize += size
            items.append(TrashItem(
                url: url,
                size: size,
                dateModified: rv?.contentModificationDate ?? Date()
            ))
        }

        items.sort { $0.size > $1.size }
        return (items, totalSize)
    }

    nonisolated static func directorySize(at url: URL, fm: FileManager) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let rv = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  rv.isRegularFile == true,
                  let size = rv.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }
}
