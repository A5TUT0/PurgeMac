//
//  SidebarView.swift
//  PurgeMac
//
//  Premium dark sidebar v2 — animated selection with glow, grouped sections, refined styling.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selected: AppSection
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            // App header
            appHeader
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 14)

            PMSeparator()

            // Nav items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Main sections
                    VStack(spacing: 2) {
                        ForEach(AppSection.mainSections) { section in
                            PMSidebarRow(
                                section: section,
                                isSelected: selected == section,
                                gradient: gradientFor(section)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selected = section
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)

                    // Utilities label
                    HStack {
                        PMSectionLabel(text: "UTILITIES")
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    // Utility sections
                    VStack(spacing: 2) {
                        ForEach(AppSection.utilitySections) { section in
                            PMSidebarRow(
                                section: section,
                                isSelected: selected == section,
                                gradient: gradientFor(section)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selected = section
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }

            Spacer()

            // Scan path
            if appState.scanURL != nil {
                scanPathInfo
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            PMSeparator()

            // Settings
            PMSidebarRow(
                section: .settings,
                isSelected: selected == .settings,
                gradient: PMGradients.brand
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selected = .settings
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Version
            Text("v1.0 • PurgeMac")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.pmTextDim)
                .padding(.bottom, 10)
        }
        .frame(width: 230)
        .background(
            ZStack {
                Color(hex: "0A0A11")
                PMGradients.sidebar.opacity(0.8)

                // Subtle ambient glow from selected section
                RadialGradient(
                    colors: [selectedColor.opacity(0.03), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
    }

    // MARK: - Selected color

    private var selectedColor: Color {
        switch selected {
        case .dashboard:     return .pmRed
        case .duplicates:    return .pmRose
        case .loginItems:    return .pmAmber
        case .downloads:     return .pmBlue
        case .storage:       return .pmPurple
        case .developer:     return .pmTeal
        case .keyboardLock:  return .pmPink
        case .trash:         return .pmOrange
        case .settings:      return .pmRed
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PMGradients.brand)
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.pmRed.opacity(0.35), radius: 8)
                // Inner highlight
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.clear],
                            startPoint: .topLeading, endPoint: .center
                        )
                    )
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("PurgeMac")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("System Cleaner")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.pmTextMuted)
                    .tracking(0.5)
            }
            Spacer()
        }
    }

    // MARK: - Scan Path

    private var scanPathInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("SCAN PATH")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.pmTextMuted)
                .tracking(0.8)

            Button { appState.pickScanFolder() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(PMGradients.brand)
                    Text(appState.scanPathDisplay)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.pmTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.pmTextMuted)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Gradient mapping

    private func gradientFor(_ section: AppSection) -> LinearGradient {
        switch section {
        case .dashboard:     return PMGradients.brand
        case .duplicates:    return PMGradients.sunset
        case .loginItems:    return PMGradients.amber
        case .downloads:     return PMGradients.ocean
        case .storage:       return PMGradients.purple
        case .developer:     return PMGradients.forest
        case .keyboardLock:  return PMGradients.keyboard
        case .trash:         return PMGradients.trashGrad
        case .settings:      return PMGradients.brand
        }
    }
}

// MARK: - Sidebar Row

struct PMSidebarRow: View {
    let section: AppSection
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Active indicator bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(gradient) : AnyShapeStyle(Color.clear))
                    .frame(width: 3, height: 20)
                    .shadow(color: isSelected ? Color.pmRed.opacity(0.5) : .clear, radius: 5)

                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? AnyShapeStyle(gradient) : AnyShapeStyle(Color.pmTextMuted))
                    .frame(width: 22, alignment: .center)

                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .pmTextSecondary)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.white.opacity(0.06)
                            : hovering
                                ? Color.white.opacity(0.03)
                                : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.white.opacity(0.06)
                            : Color.clear,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { hovering = h }
        }
    }
}
