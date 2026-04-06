//
//  KeyboardLockViewModel.swift
//  PurgeMac
//
//  Captures keystrokes within the app window so the user can safely clean their keyboard.
//

import Foundation
import AppKit
import SwiftUI

@Observable
@MainActor
final class KeyboardLockViewModel {

    var isLocked = false
    var lockDuration: TimeInterval = 0
    var keyPressCount: Int = 0
    var lastKeyFlash: Bool = false

    // Internal state
    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    private var flagsMonitor: Any?
    private var timer: Timer?
    private var escPressStart: Date?
    private let escHoldDuration: TimeInterval = 3.0

    // MARK: - Public

    func toggleLock() {
        if isLocked {
            unlock()
        } else {
            lock()
        }
    }

    func lock() {
        guard !isLocked else { return }
        isLocked = true
        lockDuration = 0
        keyPressCount = 0

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.lockDuration += 1
            }
        }

        // Capture key events within the app
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                guard let self, self.isLocked else { return }
                self.keyPressCount += 1
                self.lastKeyFlash = true
                // Reset flash
                Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    await MainActor.run { self.lastKeyFlash = false }
                }

                // Check for Esc hold
                if event.keyCode == 53 { // Escape key
                    if self.escPressStart == nil {
                        self.escPressStart = Date()
                    }
                } else {
                    self.escPressStart = nil
                }

                // Check if Esc held long enough
                if let start = self.escPressStart,
                   Date().timeIntervalSince(start) >= self.escHoldDuration {
                    self.unlock()
                }
            }
            return nil // Consume the event
        }

        keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            Task { @MainActor in
                if event.keyCode == 53 {
                    self?.escPressStart = nil
                }
            }
            return nil // Consume the event
        }

        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { _ in
            return nil // Consume modifier key events too
        }
    }

    func unlock() {
        guard isLocked else { return }
        isLocked = false
        timer?.invalidate()
        timer = nil
        escPressStart = nil

        if let m = keyDownMonitor { NSEvent.removeMonitor(m); keyDownMonitor = nil }
        if let m = keyUpMonitor   { NSEvent.removeMonitor(m); keyUpMonitor = nil }
        if let m = flagsMonitor   { NSEvent.removeMonitor(m); flagsMonitor = nil }
    }

    // MARK: - Formatted duration

    var formattedDuration: String {
        let mins = Int(lockDuration) / 60
        let secs = Int(lockDuration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // Note: cleanup is handled in unlock().
    // Timer and monitors will be cleaned up when the app terminates if not explicitly unlocked.
}
