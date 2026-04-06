//
//  Theme.swift
//  PurgeMac
//
//  Premium design system — vibrant gradients, glassmorphism, rich palette.
//  v2.0 — Full visual overhaul with mesh gradients, shimmer effects, and premium styling.
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

// MARK: - Rich Color Palette

extension Color {
    // Brand core
    static let pmRed         = Color(hex: "FF4136")
    static let pmCoral       = Color(hex: "FF6B5B")
    static let pmOrange      = Color(hex: "FF8A65")
    static let pmRose        = Color(hex: "FF5C8A")

    // Accent spectrum
    static let pmPurple      = Color(hex: "A855F7")
    static let pmIndigo      = Color(hex: "6366F1")
    static let pmBlue        = Color(hex: "3B82F6")
    static let pmCyan        = Color(hex: "22D3EE")
    static let pmTeal        = Color(hex: "14B8A6")
    static let pmGreen       = Color(hex: "22C55E")
    static let pmAmber       = Color(hex: "F59E0B")
    static let pmPink        = Color(hex: "EC4899")
    static let pmLime        = Color(hex: "84CC16")

    // Backgrounds — deeper, richer
    static let pmBg          = Color(hex: "08080E")
    static let pmBgAlt       = Color(hex: "0B0B14")
    static let pmSurface     = Color(hex: "111119")
    static let pmCard        = Color(hex: "16161F")
    static let pmCardHover   = Color(hex: "1E1E2C")
    static let pmBorder      = Color.white.opacity(0.06)

    // Text
    static let pmTextPrimary   = Color.white
    static let pmTextSecondary = Color.white.opacity(0.55)
    static let pmTextMuted     = Color.white.opacity(0.3)
    static let pmTextDim       = Color.white.opacity(0.15)
}

// MARK: - Gradient Presets

struct PMGradients {
    static let brand = LinearGradient(
        colors: [Color(hex: "FF4136"), Color(hex: "FF6B5B"), Color(hex: "FF8A65")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let warmGlow = LinearGradient(
        colors: [Color(hex: "FF4136"), Color(hex: "FF8A65")],
        startPoint: .leading, endPoint: .trailing
    )
    static let sunset = LinearGradient(
        colors: [Color(hex: "FF5C8A"), Color(hex: "FF8A65")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let purple = LinearGradient(
        colors: [Color(hex: "A855F7"), Color(hex: "6366F1")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let ocean = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "22D3EE")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let forest = LinearGradient(
        colors: [Color(hex: "14B8A6"), Color(hex: "22C55E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let amber = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "FF8A65")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let keyboard = LinearGradient(
        colors: [Color(hex: "EC4899"), Color(hex: "A855F7")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let trashGrad = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "F97316")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let night = LinearGradient(
        colors: [Color(hex: "0A0A14"), Color(hex: "12121E"), Color(hex: "0A0A14")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sidebar = LinearGradient(
        colors: [Color(hex: "0D0D14"), Color(hex: "090910")],
        startPoint: .top, endPoint: .bottom
    )
    static let mesh = LinearGradient(
        colors: [Color.pmRed.opacity(0.12), Color.pmPurple.opacity(0.08), Color.pmBg],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let subtle = LinearGradient(
        colors: [Color.white.opacity(0.04), Color.white.opacity(0.01)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Glass Card Modifier (v2)

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 16
    var glowColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.35)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: (glowColor ?? .clear).opacity(0.08), radius: 20, y: 8)
    }
}

extension View {
    func glassCard(padding: CGFloat = 20, cornerRadius: CGFloat = 16, glow: Color? = nil) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius, glowColor: glow))
    }
}

// MARK: - Premium Hover Card Modifier

struct PMHoverCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var glowColor: Color = .pmRed
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        glowColor.opacity(hovering ? 0.2 : 0),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: glowColor.opacity(hovering ? 0.08 : 0),
                radius: hovering ? 16 : 0,
                y: hovering ? 6 : 0
            )
            .scaleEffect(hovering ? 1.015 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
            .onHover { h in hovering = h }
    }
}

extension View {
    func premiumHover(cornerRadius: CGFloat = 16, glowColor: Color = .pmRed) -> some View {
        modifier(PMHoverCardModifier(cornerRadius: cornerRadius, glowColor: glowColor))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.06),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.25 + geo.size.width * 1.5 * phase)
                    .animation(
                        .linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
                .mask(content)
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Gradient Border

struct PMGradientBorderModifier: ViewModifier {
    var gradient: LinearGradient
    var cornerRadius: CGFloat = 16
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(gradient, lineWidth: lineWidth)
            )
    }
}

extension View {
    func gradientBorder(_ gradient: LinearGradient, cornerRadius: CGFloat = 16, lineWidth: CGFloat = 1) -> some View {
        modifier(PMGradientBorderModifier(gradient: gradient, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}

// MARK: - Primary Button (v2)

struct PurgePrimaryButton: ButtonStyle {
    var isDestructive: Bool = false
    var isSmall: Bool = false
    var gradient: LinearGradient? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isSmall ? 12 : 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, isSmall ? 14 : 22)
            .padding(.vertical, isSmall ? 7 : 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isDestructive
                                ? AnyShapeStyle(LinearGradient(colors: [Color.red, Color(hex: "DC2626")], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(gradient ?? PMGradients.brand)
                        )
                    // Inner highlight
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                startPoint: .top, endPoint: .center
                            )
                        )
                }
                .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .shadow(
                color: (isDestructive ? Color.red : .pmRed).opacity(
                    configuration.isPressed ? 0.1 : 0.3
                ),
                radius: configuration.isPressed ? 4 : 16,
                y: configuration.isPressed ? 1 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (v2)

struct PurgeSecondaryButton: ButtonStyle {
    var color: Color = .pmCoral

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button

struct PurgeGhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.pmTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.06 : 0.03))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

// MARK: - Pill Button

struct PurgePillButton: ButtonStyle {
    var gradient: LinearGradient = PMGradients.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(gradient)
            )
            .shadow(color: Color.pmRed.opacity(configuration.isPressed ? 0.05 : 0.2), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Gradient Separator

struct PMSeparator: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.0), Color.white.opacity(0.06), Color.white.opacity(0.0)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Utilities

func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

func formatRelativeDate(_ date: Date) -> String {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f.localizedString(for: date, relativeTo: Date())
}
