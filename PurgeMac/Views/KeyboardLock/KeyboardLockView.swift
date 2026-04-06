//
//  KeyboardLockView.swift
//  PurgeMac
//
//  Lock keyboard for safe cleaning — captures all keystrokes within the app window.
//  Pink/Purple gradient theme.
//

import SwiftUI

struct KeyboardLockView: View {
    @State private var vm = KeyboardLockViewModel()
    @State private var appeared = false
    @State private var wavePhase: Double = 0
    @State private var ringScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Keyboard Lock", icon: "keyboard.fill", gradient: PMGradients.keyboard) {
                if vm.isLocked {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.pmPink)
                            .frame(width: 6, height: 6)
                            .scaleEffect(vm.lastKeyFlash ? 1.5 : 1.0)
                            .animation(.easeOut(duration: 0.15), value: vm.lastKeyFlash)
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pmPink)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.pmPink.opacity(0.1)))
                }
            }
            PMSeparator()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    lockButton
                    statsRow
                    instructionsCard
                    Spacer(minLength: 20)
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmPink, color2: .pmPurple))
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { vm.unlock() }
    }

    // MARK: - Lock Button

    private var lockButton: some View {
        VStack(spacing: 28) {
            ZStack {
                // Outer wave rings (when locked)
                if vm.isLocked {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                PMGradients.keyboard.opacity(Double(3 - i) * 0.08),
                                lineWidth: 1.5
                            )
                            .frame(width: CGFloat(200 + i * 50), height: CGFloat(200 + i * 50))
                            .scaleEffect(ringScale)
                            .animation(
                                .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.3),
                                value: ringScale
                            )
                    }
                }

                // Glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (vm.isLocked ? Color.pmPink : Color.pmPurple).opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(vm.isLocked ? 1.1 : 0.95)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: vm.isLocked)

                // Main button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        vm.toggleLock()
                        if vm.isLocked { ringScale = 1.1 }
                    }
                } label: {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(
                                vm.isLocked
                                    ? AnyShapeStyle(PMGradients.keyboard)
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .frame(width: 160, height: 160)
                            .shadow(
                                color: vm.isLocked ? Color.pmPink.opacity(0.4) : .clear,
                                radius: 30
                            )

                        // Inner highlight
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(vm.isLocked ? 0.2 : 0.06), Color.clear],
                                    startPoint: .topLeading, endPoint: .center
                                )
                            )
                            .frame(width: 160, height: 160)

                        // Border
                        Circle()
                            .stroke(
                                vm.isLocked
                                    ? AnyShapeStyle(Color.white.opacity(0.2))
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    ),
                                lineWidth: 1.5
                            )
                            .frame(width: 160, height: 160)

                        VStack(spacing: 10) {
                            Image(systemName: vm.isLocked ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white)
                                .contentTransition(.symbolEffect(.replace))

                            Text(vm.isLocked ? "LOCKED" : "UNLOCKED")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(2)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Key flash indicator
                if vm.isLocked && vm.lastKeyFlash {
                    Circle()
                        .fill(Color.pmPink.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.15), value: vm.lastKeyFlash)
                }
            }
            .frame(height: 300)

            // Duration
            if vm.isLocked {
                VStack(spacing: 6) {
                    Text(vm.formattedDuration)
                        .font(.system(size: 42, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: vm.lockDuration)

                    Text("\(vm.keyPressCount) keys intercepted")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.pmTextSecondary)
                        .contentTransition(.numericText())
                        .animation(.default, value: vm.keyPressCount)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            statPill(icon: "hand.tap.fill", value: "\(vm.keyPressCount)", label: "Keys blocked")
            statPill(icon: "clock.fill", value: vm.formattedDuration, label: "Duration")
            statPill(icon: "shield.checkered", value: vm.isLocked ? "Active" : "Inactive", label: "Status")
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(PMGradients.keyboard)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.pmTextMuted)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 16, cornerRadius: 14)
    }

    // MARK: - Instructions

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(PMGradients.keyboard)
                Text("How it works")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                instructionRow("1", "Press the lock button to activate keyboard lock")
                instructionRow("2", "All keystrokes are captured while the lock is active")
                instructionRow("3", "Clean your keyboard safely without triggering shortcuts")
                instructionRow("4", "Hold Esc for 3 seconds or click the button to unlock")
            }

            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.pmAmber)
                Text("Only works while PurgeMac is in focus.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.pmAmber.opacity(0.8))
            }
            .padding(.top, 4)
        }
        .glassCard(padding: 18, cornerRadius: 14)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(PMGradients.keyboard)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.pmPink.opacity(0.1)))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.pmTextSecondary)
                .lineSpacing(2)
        }
    }
}
