//
//  Components.swift
//  PurgeMac
//
//  Premium reusable UI components v2 — rich animations, refined design.
//

import SwiftUI

// MARK: - Section Header

struct PMHeader: View {
    var title: String
    var icon: String
    var gradient: LinearGradient = PMGradients.brand
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(gradient.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.pmTextMuted)
                }
            }
        }
    }
}

// MARK: - Toolbar

struct PMToolbar<Actions: View>: View {
    var title: String
    var icon: String
    var gradient: LinearGradient = PMGradients.brand
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(spacing: 12) {
            PMHeader(title: title, icon: icon, gradient: gradient)
            Spacer()
            actions()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color.pmBg.opacity(0.8)
                // Subtle gradient glow at top
                LinearGradient(
                    colors: [Color.white.opacity(0.02), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
            }
        )
    }
}

// MARK: - Stat Card

struct PMStatCard: View {
    var value: String
    var label: String
    var icon: String
    var gradient: LinearGradient = PMGradients.brand
    var trend: String? = nil
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(gradient.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(gradient)
                }
                Spacer()
                if let trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.pmGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.pmGreen.opacity(0.1)))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.pmTextSecondary)
            }
        }
        .glassCard(padding: 16, cornerRadius: 14, glow: hovering ? .pmRed : nil)
        .scaleEffect(hovering ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        .onHover { h in hovering = h }
    }
}

// MARK: - Inline Stat

struct PMInlineStat: View {
    var value: String
    var label: String
    var color: Color = .pmTextSecondary

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.pmTextMuted)
        }
    }
}

// MARK: - Animated Checkbox

struct PMCheckbox: View {
    var isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(isSelected ? Color.pmRed : Color.white.opacity(0.2), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if isSelected {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(PMGradients.brand)
                    .frame(width: 18, height: 18)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Progress Ring (v2)

struct PMProgressRing: View {
    var progress: Double
    var size: CGFloat = 80
    var lineWidth: CGFloat = 5
    var icon: String? = nil
    var gradient: LinearGradient = PMGradients.brand
    var glowColor: Color = .pmRed

    @State private var animate = false

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: lineWidth)
                .frame(width: size, height: size)
            // Active ring
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor.opacity(0.4), radius: 8)
                .animation(.easeInOut(duration: 0.6), value: progress)
            // Icon
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.28, weight: .medium))
                    .foregroundStyle(gradient)
            }
        }
    }
}

// MARK: - Empty State

struct PMEmptyState: View {
    var icon: String
    var title: String
    var subtitle: String
    var gradient: LinearGradient = PMGradients.brand
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    @State private var pulse = false
    @State private var floatY: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Outer orbital ring
                Circle()
                    .stroke(gradient.opacity(0.06), lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.1 : 0.95)

                Circle()
                    .fill(gradient.opacity(0.04))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.05 : 0.98)

                Circle()
                    .fill(gradient.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(gradient)
                    .offset(y: floatY)
            }
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.pmTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .lineSpacing(3)
            }

            if let label = actionLabel, let action {
                Button(label, action: action)
                    .buttonStyle(PurgePrimaryButton())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            pulse = true
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatY = -6
            }
        }
    }
}

// MARK: - Loading State

struct PMLoadingState: View {
    var message: String = "Loading…"
    var gradient: LinearGradient = PMGradients.brand
    @State private var rotation: Double = 0
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(gradient.opacity(0.04))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulse ? 1.15 : 0.95)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 3)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: Color.pmRed.opacity(0.3), radius: 6)
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pulse = true }
    }
}

// MARK: - Icon Badge

struct PMIconBadge: View {
    var icon: String
    var color: Color = .pmRed
    var size: CGFloat = 40
    var gradient: LinearGradient? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill((gradient ?? LinearGradient(colors: [color], startPoint: .top, endPoint: .bottom)).opacity(0.12))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(gradient ?? LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - Search Field

struct PMSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search…"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.pmTextMuted)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 140)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pmTextMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Animated Number

struct PMAnimatedNumber: View {
    var value: Int
    var font: Font = .system(size: 28, weight: .bold, design: .rounded)
    var color: Color = .white

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

// MARK: - Glow Background (v2)

struct PMGlowBackground: View {
    var color1: Color = .pmRed
    var color2: Color = .pmPurple
    var color3: Color = .pmBlue
    @State private var animate = false
    @State private var orbPhase: Double = 0

    var body: some View {
        ZStack {
            Color.pmBg.ignoresSafeArea()

            // Large ambient glow — top-left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color1.opacity(0.08), .clear],
                        center: .center, startRadius: 20, endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: -200, y: -200)
                .scaleEffect(animate ? 1.1 : 0.9)
                .blur(radius: 40)

            // Bottom-right glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color2.opacity(0.06), .clear],
                        center: .center, startRadius: 20, endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: 200, y: 200)
                .scaleEffect(animate ? 0.9 : 1.1)
                .blur(radius: 30)

            // Center accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color3.opacity(0.03), .clear],
                        center: .center, startRadius: 10, endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(animate ? 1.05 : 0.95)
                .blur(radius: 25)

            // Floating particles
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(color1.opacity(0.03))
                    .frame(width: CGFloat(20 + i * 12))
                    .offset(
                        x: CGFloat(cos(orbPhase / 40 + Double(i) * 1.3)) * CGFloat(60 + i * 35),
                        y: CGFloat(sin(orbPhase / 40 + Double(i) * 1.3)) * CGFloat(40 + i * 25)
                    )
                    .blur(radius: 10)
            }
        }
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                orbPhase = 360
            }
        }
    }
}

// MARK: - Feature Tag

struct PMFeatureTag: View {
    var text: String
    var gradient: LinearGradient = PMGradients.brand

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(gradient)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(gradient.opacity(0.1))
                    .overlay(
                        Capsule().stroke(gradient.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Section Label

struct PMSectionLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.pmTextMuted)
            .tracking(1.2)
    }
}

// MARK: - Divider with gradient

struct PMDivider: View {
    var body: some View {
        PMSeparator()
    }
}

// MARK: - Stats Bar (summary row)

struct PMStatsBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 16) {
            content()
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.pmSurface.opacity(0.6))
    }
}

// MARK: - Notification Badge

struct PMNotificationBadge: View {
    var count: Int
    var color: Color = .pmRed

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(color))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Ambient Mesh Background for sections

struct PMSectionBackground: View {
    var color1: Color = .pmRed
    var color2: Color = .pmPurple

    var body: some View {
        ZStack {
            Color.pmBg
            RadialGradient(
                colors: [color1.opacity(0.04), .clear],
                center: .topLeading, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [color2.opacity(0.02), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
}
