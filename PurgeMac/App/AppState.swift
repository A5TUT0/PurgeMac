//
//  AppState.swift
//  PurgeMac
//
//  Global app state: persists user's chosen scan path via security-scoped bookmarks.
//

import Foundation
import AppKit
import SwiftUI

@Observable
@MainActor
final class AppState {

    // MARK: - Stored Properties (Observable tracks these)

    var hasCompletedOnboarding: Bool = false
    var scanURL: URL? = nil

    /// Human-readable path string for display.
    var scanPathDisplay: String {
        guard let url = scanURL else { return "No folder selected" }
        return url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    // MARK: - Init

    init() {
        // Restore persisted state
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "pm_onboarded")
        restoreBookmark()
    }

    // MARK: - Public

    /// Opens an NSOpenPanel so the user can pick their scan root.
    @discardableResult
    func pickScanFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.title                   = "Choose Your Scan Folder"
        panel.message                 = "PurgeMac will use this folder across all features."
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories    = false
        panel.prompt                  = "Select"

        guard panel.runModal() == .OK, let url = panel.url else { return false }
        setScanURL(url)
        return true
    }

    /// Set scan URL and mark onboarding complete
    func setScanURL(_ url: URL) {
        saveBookmark(for: url)
        _ = url.startAccessingSecurityScopedResource()
        self.scanURL = url
        self.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "pm_onboarded")
    }

    /// Use home directory as default
    func useHomeDirectory() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.scanURL = home
        self.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "pm_onboarded")
        UserDefaults.standard.set(home.path, forKey: "pm_scanPath")
    }

    /// Reset onboarding
    func resetOnboarding() {
        self.hasCompletedOnboarding = false
        self.scanURL = nil
        UserDefaults.standard.set(false, forKey: "pm_onboarded")
        UserDefaults.standard.removeObject(forKey: "pm_bookmark")
        UserDefaults.standard.removeObject(forKey: "pm_scanPath")
    }

    // MARK: - Bookmark Persistence

    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: "pm_bookmark")
            UserDefaults.standard.set(url.path, forKey: "pm_scanPath")
        } catch {
            // Fallback: just save the path
            UserDefaults.standard.set(url.path, forKey: "pm_scanPath")
        }
    }

    private func restoreBookmark() {
        // Try security-scoped bookmark first
        if let data = UserDefaults.standard.data(forKey: "pm_bookmark") {
            do {
                var stale = false
                let url = try URL(
                    resolvingBookmarkData: data,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )
                _ = url.startAccessingSecurityScopedResource()
                if stale { saveBookmark(for: url) }
                self.scanURL = url
                return
            } catch { /* fall through */ }
        }

        // Fallback: try saved path
        if let path = UserDefaults.standard.string(forKey: "pm_scanPath") {
            self.scanURL = URL(fileURLWithPath: path)
        }
    }
}
