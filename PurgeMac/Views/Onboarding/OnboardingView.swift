//
//  OnboardingView.swift
//  PurgeMac
//
//  Multi-step onboarding v2 — richer animations, larger feature cards, premium feel.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @State private var appeared = false
    @State private var glowPulse = false
    @State private var floatY: CGFloat = 0

    var body: some View {
        ZStack {
            // Animated background
            PMGlowBackground(color1: .pmRed, color2: .pmPurple, color3: .pmBlue)

            VStack(spacing: 0) {
                Spacer()

                // Hero
                heroSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: appeared)

                Spacer().frame(height: 36)

                // Features
                featuresRow
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

                Spacer().frame(height: 40)

                // Actions
                actionsSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appeared)

                Spacer()

                // Skip
                Button("Skip — Use Home Folder") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.useHomeDirectory()
                    }
                }
                .buttonStyle(PurgeGhostButton())
                .opacity(appeared ? 0.6 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.7), value: appeared)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 60)
        }
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatY = -8
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 28) {
            // Logo
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(PMGradients.brand.opacity(0.1), lineWidth: 1)
                    .frame(width: 150, height: 150)
                    .scaleEffect(glowPulse ? 1.12 : 0.92)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .stroke(PMGradients.brand.opacity(0.06), lineWidth: 0.5)
                    .frame(width: 125, height: 125)

                Circle()
                    .fill(Color.pmRed.opacity(0.04))
                    .frame(width: 110, height: 110)

                Circle()
                    .fill(Color.pmRed.opacity(0.07))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(PMGradients.brand)
                    .offset(y: floatY)
            }
            .onAppear { glowPulse = true }

            VStack(spacing: 12) {
                Text("Welcome to PurgeMac")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "FFB5AF")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text("Your Mac deserves to breathe.\nSelect a folder to start cleaning.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Features Row

    private var featuresRow: some View {
        HStack(spacing: 14) {
            featureCard(icon: "doc.on.doc.fill", title: "Duplicates", gradient: PMGradients.sunset)
            featureCard(icon: "internaldrive.fill", title: "Storage", gradient: PMGradients.purple)
            featureCard(icon: "arrow.down.circle.fill", title: "Downloads", gradient: PMGradients.ocean)
            featureCard(icon: "terminal.fill", title: "Developer", gradient: PMGradients.forest)
            featureCard(icon: "keyboard.fill", title: "Keyboard Lock", gradient: PMGradients.keyboard)
        }
    }

    private func featureCard(icon: String, title: String, gradient: LinearGradient) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradient.opacity(0.08))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(gradient.opacity(0.1), lineWidth: 0.5)
                    )
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(gradient)
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.pmTextSecondary)
        }
        .frame(width: 85)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Button {
            let didPick = appState.pickScanFolder()
            if !didPick {
                // User cancelled — that's OK, don't advance
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 16))
                Text("Select Folder to Scan")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 16)
        }
        .buttonStyle(PurgePrimaryButton())
    }
}
