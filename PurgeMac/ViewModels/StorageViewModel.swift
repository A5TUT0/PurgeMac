//
//  StorageViewModel.swift
//  PurgeMac
//
//  Reads system volume stats, estimates per-category usage, and finds large files.
//

import Foundation

@Observable
@MainActor
final class StorageViewModel {
    var totalBytes: Int64     = 0
    var usedBytes: Int64      = 0
    var availableBytes: Int64 = 0
    var categories: [StorageCategory] = []
    var largeFiles: [LargeFile] = []
    var isLoading = false

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    // MARK: - Public

    func load(scanURL: URL? = nil) {
        isLoading = true

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.computeStorage(scanURL: scanURL)
                    continuation.resume(returning: r)
                }
            }
            self.totalBytes     = result.total
            self.usedBytes      = result.used
            self.availableBytes = result.available
            self.categories     = result.categories
            self.largeFiles     = result.largeFiles
            self.isLoading      = false
        }
    }

    // MARK: - Private

    nonisolated static func computeStorage(scanURL: URL?) -> (
        total: Int64, used: Int64, available: Int64,
        categories: [StorageCategory], largeFiles: [LargeFile]
    ) {
        let volumeURL = URL(fileURLWithPath: "/")
        guard
            let rv = try? volumeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ]),
            let total     = rv.volumeTotalCapacity,
            let available = rv.volumeAvailableCapacityForImportantUsage
        else { return (0, 0, 0, [], []) }

        let totalBytes     = Int64(total)
        let availableBytes = available
        let usedBytes      = totalBytes - availableBytes

        // Scan user-accessible directories for category breakdown
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser

        let appsBytes    = quickSize(URL(fileURLWithPath: "/Applications"), fm: fm)
        let docsBytes    = quickSize(home.appendingPathComponent("Documents"), fm: fm)
            + quickSize(home.appendingPathComponent("Desktop"), fm: fm)
        let downloadsBytes = quickSize(home.appendingPathComponent("Downloads"), fm: fm)
        let libBytes     = quickSize(home.appendingPathComponent("Library"), fm: fm, maxFiles: 5000)

        let accountedFor = appsBytes + docsBytes + downloadsBytes + libBytes
        let otherBytes   = max(0, usedBytes - accountedFor)

        let cats: [StorageCategory] = [
            StorageCategory(name: "Applications", bytes: appsBytes,      colorHex: "EE3627", icon: "app.fill"),
            StorageCategory(name: "Documents",    bytes: docsBytes,      colorHex: "4A6FA5", icon: "doc.fill"),
            StorageCategory(name: "Downloads",    bytes: downloadsBytes, colorHex: "FF6B5B", icon: "arrow.down.circle.fill"),
            StorageCategory(name: "Library",      bytes: libBytes,       colorHex: "d29d98", icon: "books.vertical.fill"),
            StorageCategory(name: "Other",        bytes: otherBytes,     colorHex: "7F8C8D", icon: "folder.fill"),
            StorageCategory(name: "Available",    bytes: availableBytes, colorHex: "3B9450", icon: "checkmark.circle.fill"),
        ]

        // Large files scan
        var large: [LargeFile] = []
        if let scanDir = scanURL ?? Optional(home) {
            large = findLargeFiles(in: scanDir, fm: fm, minSize: 50_000_000, limit: 25)
        }

        return (totalBytes, usedBytes, availableBytes, cats, large)
    }

    nonisolated static func quickSize(_ url: URL, fm: FileManager, maxFiles: Int = 8000) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        var total: Int64 = 0
        var count = 0
        for case let f as URL in enumerator {
            guard count < maxFiles else { break }
            if let rv = try? f.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               rv.isRegularFile == true {
                total += Int64(rv.fileSize ?? 0)
                count += 1
            }
        }
        return total
    }

    nonisolated static func findLargeFiles(
        in directory: URL, fm: FileManager,
        minSize: Int64, limit: Int
    ) -> [LargeFile] {
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var files: [LargeFile] = []
        var count = 0

        for case let fileURL as URL in enumerator {
            guard count < 50_000 else { break }
            guard
                let rv = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]),
                rv.isRegularFile == true,
                let size = rv.fileSize,
                Int64(size) >= minSize
            else {
                count += 1
                continue
            }
            files.append(LargeFile(
                url: fileURL,
                size: Int64(size),
                dateModified: rv.contentModificationDate ?? Date()
            ))
            count += 1
        }

        return Array(files.sorted { $0.size > $1.size }.prefix(limit))
    }
}
