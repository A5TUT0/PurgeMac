//
//  Theme.swift
//  PurgeMac
//
//  Color palette, design tokens, shared styles.
//

import SwiftUI

// MARK: - Hex Color

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Brand Palette

extension Color {
    /// #14100f  — near-black, brand text
    static let purgeText       = Color(hex: "14100f")
    /// #fdfbfb  — warm off-white background (light mode)
    static let purgeBg         = Color(hex: "fdfbfb")
    /// #EE3627  — primary red
    static let purgePrimary    = Color(hex: "EE3627")
    /// #d29d98  — secondary muted rose
    static let purgeSecondary  = Color(hex: "d29d98")
    /// #ca726a  — accent salmon
    static let purgeAccent     = Color(hex: "ca726a")

    static func purgeCard(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1e1e1e") : .white
    }
    static func purgeBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "141414") : Color(hex: "fdfbfb")
    }
    static func purgeSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "252525") : Color(hex: "f5efef")
    }
    static func purgeStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }
}

// MARK: - Card Modifier

struct PurgeCardModifier: ViewModifier {
    @Environment(\.colorScheme) var scheme
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.purgeCard(scheme))
                    .shadow(
                        color: scheme == .dark
                            ? Color.black.opacity(0.35)
                            : Color.black.opacity(0.07),
                        radius: 12, x: 0, y: 4
                    )
            )
    }
}

extension View {
    func purgeCard(padding: CGFloat = 20) -> some View {
        modifier(PurgeCardModifier(padding: padding))
    }
}

// MARK: - Primary Button

struct PurgePrimaryButton: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isDestructive ? Color.red : Color.purgePrimary)
                    .opacity(configuration.isPressed ? 0.82 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button

struct PurgeSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.purgePrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.purgeAccent.opacity(0.5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.purgePrimary.opacity(0.06))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shared Components

struct PurgeEmptyState: View {
    var icon: String
    var title: String
    var subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.purgeSecondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            if let label = actionLabel, let action {
                Button(label, action: action)
                    .buttonStyle(PurgePrimaryButton())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct PurgeSectionHeader: View {
    var title: String
    var icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.purgePrimary)
            Text(title)
                .font(.system(size: 18, weight: .bold))
        }
    }
}

// MARK: - Util

func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

func formatRelativeDate(_ date: Date) -> String {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f.localizedString(for: date, relativeTo: Date())
}
