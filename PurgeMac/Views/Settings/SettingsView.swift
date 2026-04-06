//
//  SettingsView.swift
//  PurgeMac
//
//  App preferences v2 with premium branded styling.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var appeared = false
    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Settings", icon: "gearshape.fill") {
                // empty
            }
            PMSeparator()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    scanPathSection
                    appInfoSection
                    keyboardSection
                    advancedSection
                }
                .padding(28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmRed, color2: .pmPurple))
        .onAppear { withAnimation { appeared = true } }
        .confirmationDialog("Reset Onboarding?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { appState.resetOnboarding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear your saved scan path and show the welcome screen again.")
        }
    }

    // MARK: - Scan Path

    private var scanPathSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PMSectionLabel(text: "SCAN PATH")
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    PMIconBadge(icon: "folder.fill", size: 42, gradient: PMGradients.brand)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current Scan Folder").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                        Text(appState.scanPathDisplay)
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(.pmTextSecondary).lineLimit(1)
                    }
                    Spacer()
                    Button("Change") { appState.pickScanFolder() }
                        .buttonStyle(PurgePrimaryButton(isSmall: true))
                }
                Text("This folder is used by Duplicates, Storage, and Developer tools. You only need to set it once.")
                    .font(.system(size: 11)).foregroundColor(.pmTextMuted).lineSpacing(2)
            }
            .glassCard(padding: 18, cornerRadius: 14)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.05), value: appeared)
    }

    // MARK: - Keyboard Lock info

    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PMSectionLabel(text: "KEYBOARD LOCK")
            HStack(spacing: 14) {
                PMIconBadge(icon: "keyboard.fill", size: 42, gradient: PMGradients.keyboard)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Keyboard Lock Mode").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    Text("Captures all keystrokes within PurgeMac so you can safely clean your keyboard. Hold Esc for 3 seconds to unlock.")
                        .font(.system(size: 11)).foregroundColor(.pmTextMuted).lineSpacing(2)
                }
                Spacer()
            }
            .glassCard(padding: 18, cornerRadius: 14)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PMSectionLabel(text: "ABOUT")
            VStack(spacing: 0) {
                infoRow("App", "PurgeMac", icon: "sparkles.square.filled.on.square", gradient: PMGradients.brand)
                PMSeparator().padding(.horizontal, 16)
                infoRow("Version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0", icon: "tag.fill", gradient: PMGradients.purple)
                PMSeparator().padding(.horizontal, 16)
                infoRow("macOS", ProcessInfo.processInfo.operatingSystemVersionString, icon: "desktopcomputer", gradient: PMGradients.ocean)
                PMSeparator().padding(.horizontal, 16)
                infoRow("Developer", "LNLK", icon: "person.fill", gradient: PMGradients.forest)
            }
            .glassCard(padding: 0, cornerRadius: 14)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)
    }

    private func infoRow(_ label: String, _ value: String, icon: String, gradient: LinearGradient) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(gradient).frame(width: 16)
            Text(label).font(.system(size: 13)).foregroundColor(.pmTextSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PMSectionLabel(text: "ADVANCED")
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reset Onboarding").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    Text("Clear saved scan path and show welcome screen again.")
                        .font(.system(size: 11)).foregroundColor(.pmTextMuted)
                }
                Spacer()
                Button("Reset") { showResetConfirm = true }
                    .buttonStyle(PurgePrimaryButton(isDestructive: true, isSmall: true))
            }
            .glassCard(padding: 18, cornerRadius: 14)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
    }
}
