//
//  StorageViewModel.swift
//  PurgeMac
//
//  Reads system volume stats and estimates per-category usage.
//

import Foundation

@Observable
@MainActor
final class StorageViewModel {
    var totalBytes: Int64    = 0
    var usedBytes: Int64     = 0
    var availableBytes: Int64 = 0
    var categories: [StorageCategory] = []
    var isLoading = false

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    // MARK: - Public

    func load() {
        isLoading = true

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.computeStorage()
                    continuation.resume(returning: r)
                }
            }
            self.totalBytes     = result.total
            self.usedBytes      = result.used
            self.availableBytes = result.available
            self.categories     = result.categories
            self.isLoading      = false
        }
    }

    // MARK: - Private

    nonisolated static func computeStorage() -> (
        total: Int64, used: Int64, available: Int64, categories: [StorageCategory]
    ) {
        let volumeURL = URL(fileURLWithPath: "/")
        guard
            let rv = try? volumeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ]),
            let total     = rv.volumeTotalCapacity,
            let available = rv.volumeAvailableCapacityForImportantUsage
        else { return (0, 0, 0, []) }

        let totalBytes     = Int64(total)
        let availableBytes = Int64(available)
        let usedBytes      = totalBytes - availableBytes

        // Quick directory-size estimates (bounded scan depth)
        let fm = FileManager.default
        let systemBytes  = quickSize(URL(fileURLWithPath: "/System"), fm: fm)
        let appsBytes    = quickSize(URL(fileURLWithPath: "/Applications"), fm: fm)
            + quickSize(fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications"), fm: fm)
        let docsBytes    = quickSize(fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents"), fm: fm)
            + quickSize(fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"), fm: fm)
        let libBytes     = quickSize(fm.homeDirectoryForCurrentUser.appendingPathComponent("Library"), fm: fm)

        let accountedFor = systemBytes + appsBytes + docsBytes + libBytes
        let otherBytes   = max(0, usedBytes - accountedFor)

        let cats: [StorageCategory] = [
            StorageCategory(name: "System",       bytes: systemBytes,    colorHex: "EE3627", icon: "apple.logo"),
            StorageCategory(name: "Applications", bytes: appsBytes,      colorHex: "ca726a", icon: "app.fill"),
            StorageCategory(name: "Documents",    bytes: docsBytes,      colorHex: "4A6FA5", icon: "doc.fill"),
            StorageCategory(name: "Library",      bytes: libBytes,       colorHex: "d29d98", icon: "books.vertical.fill"),
            StorageCategory(name: "Other",        bytes: otherBytes,     colorHex: "7F8C8D", icon: "folder.fill"),
            StorageCategory(name: "Available",    bytes: availableBytes, colorHex: "3B9450", icon: "checkmark.circle.fill"),
        ]

        return (totalBytes, usedBytes, availableBytes, cats)
    }

    nonisolated static func quickSize(_ url: URL, fm: FileManager) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        var total: Int64 = 0
        var count = 0
        for case let f as URL in enumerator {
            guard count < 8_000 else { break }
            if let rv = try? f.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               rv.isRegularFile == true {
                total += Int64(rv.fileSize ?? 0)
                count += 1
            }
        }
        return total
    }
}
