//
//  LoginItemsViewModel.swift
//  PurgeMac
//
//  Reads login items from LaunchAgents plists and resolves proper app names from their bundles.
//

import Foundation
import AppKit
import ServiceManagement

@Observable
@MainActor
final class LoginItemsViewModel {
    var items: [LoginItem] = []
    var isLoading = false
    var accessDenied = false

    func load() {
        isLoading = true
        accessDenied = false

        Task {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let r = Self.readAll()
                    continuation.resume(returning: r)
                }
            }
            if result.accessDenied {
                self.accessDenied = true
            } else {
                self.items = result.items.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            }
            self.isLoading = false
        }
    }

    func toggle(item: LoginItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isEnabled.toggle()
    }

    func remove(item: LoginItem) {
        items.removeAll { $0.id == item.id }
    }

    // MARK: - Private

    nonisolated static func readAll() -> (items: [LoginItem], accessDenied: Bool) {
        let fm = FileManager.default
        let dirs: [URL] = [
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchDaemons")
        ]
        var result: [LoginItem] = []
        var denied = true

        for dir in dirs {
            guard let contents = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) else { continue }
            denied = false
            for url in contents where url.pathExtension == "plist" {
                if let item = parseAgent(url) { result.append(item) }
            }
        }

        // De-duplicate by label
        var seen = Set<String>()
        result = result.filter { seen.insert($0.label).inserted }

        return (result, denied)
    }

    /// Walks up the path components to find the enclosing `.app` bundle.
    nonisolated static func findAppBundle(for execPath: String) -> Bundle? {
        guard !execPath.isEmpty else { return nil }
        var url = URL(fileURLWithPath: execPath)
        while url.pathComponents.count > 1 {
            if url.pathExtension == "app" {
                return Bundle(url: url)
            }
            url = url.deletingLastPathComponent()
        }
        return nil
    }

    nonisolated static func parseAgent(_ url: URL) -> LoginItem? {
        guard let dict = NSDictionary(contentsOf: url) as? [String: Any] else { return nil }
        let label = (dict["Label"] as? String) ?? url.deletingPathExtension().lastPathComponent
        let disabled = (dict["Disabled"] as? Bool) ?? false

        // Resolve executable path
        var execPath = ""
        if let p = dict["Program"] as? String { execPath = p }
        else if let args = dict["ProgramArguments"] as? [String], let first = args.first { execPath = first }

        // Try to resolve display name from the .app bundle
        var displayName = ""
        var bundlePath = ""

        if let bundle = findAppBundle(for: execPath) {
            bundlePath = bundle.bundlePath
            displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? ""
        }

        // Fallback: derive from label  (e.g. "com.apple.notion.helper" → "Notion Helper")
        if displayName.isEmpty {
            let parts = label.components(separatedBy: ".")
            // Skip common prefixes (com, org, io, net, app, co)
            let skip: Set<String> = ["com", "org", "io", "net", "app", "co", "de", "fr", "uk"]
            let meaningful = parts.drop(while: { skip.contains($0.lowercased()) })
            displayName = meaningful
                .joined(separator: " ")
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }

        return LoginItem(
            label: label,
            displayName: displayName.isEmpty ? label : displayName,
            executablePath: bundlePath.isEmpty ? execPath : bundlePath,
            isEnabled: !disabled,
            plistURL: url
        )
    }
}
