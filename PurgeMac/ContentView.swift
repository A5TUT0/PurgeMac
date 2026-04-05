//
//  ContentView.swift
//  PurgeMac
//
//  Created by Noah Lezama on 05.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selected: AppSection = .dashboard
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selected: $selected)
        } detail: {
            Group {
                switch selected {
                case .dashboard:  DashboardView(selected: $selected)
                case .duplicates: DuplicatesView()
                case .loginItems: LoginItemsView()
                case .downloads:  DownloadsView()
                case .storage:    StorageView()
                case .developer:  DeveloperView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purgeBackground(scheme))
        }
        .navigationSplitViewStyle(.prominentDetail)
    }
}

// MARK: - SidebarView

struct SidebarView: View {
    @Binding var selected: AppSection
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            // ── App header ──────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.purgePrimary)
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("PurgeMac")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("System Cleaner")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 10)

            // ── Nav items ────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(AppSection.allCases) { section in
                        SidebarRow(section: section, isSelected: selected == section) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selected = section
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            Spacer()

            // ── Swiss footer ─────────────────────────────────────────
            VStack(spacing: 0) {
                Divider().padding(.horizontal, 10)
                VStack(spacing: 2) {
                    Text("Made in Switzerland 🇨🇭")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.65))
                    Text("FADP & GDPR Compliant · v1.0")
                        .font(.system(size: 8, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
            }
        }
        .frame(minWidth: 195, idealWidth: 205)
        .background(Color.purgeSurface(scheme))
    }
}

// MARK: - SidebarRow

struct SidebarRow: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .purgePrimary : .secondary)
                    .frame(width: 20, alignment: .center)

                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.purgePrimary)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        isSelected  ? Color.purgePrimary.opacity(0.1) :
                        hovering    ? Color.primary.opacity(0.05) :
                                      Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.12)) { hovering = h }
        }
    }
}

#Preview {
    ContentView()
}
