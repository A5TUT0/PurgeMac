//
//  SplashView.swift
//  PurgeMac
//
//  Premium animated splash v2 — particle effects, gradient text, cinematic sequence.
//

import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var logoScale: CGFloat  = 0.5
    @State private var logoOpacity: Double  = 0
    @State private var textOpacity: Double  = 0
    @State private var ringProgress: CGFloat = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var orbRotation: Double = 0
    @State private var subtitleOffset: CGFloat = 15

    var body: some View {
        ZStack {
            // Deep background
            Color.pmBg.ignoresSafeArea()

            // Animated gradient mesh
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pmRed.opacity(0.1), .clear],
                        center: .center, startRadius: 10, endRadius: 220
                    ))
                    .frame(width: 450, height: 450)
                    .scaleEffect(glowScale)
                    .blur(radius: 50)

                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pmPurple.opacity(0.06), .clear],
                        center: .center, startRadius: 10, endRadius: 180
                    ))
                    .frame(width: 350, height: 350)
                    .offset(x: 90, y: -70)
                    .blur(radius: 35)

                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pmBlue.opacity(0.04), .clear],
                        center: .center, startRadius: 10, endRadius: 150
                    ))
                    .frame(width: 300, height: 300)
                    .offset(x: -70, y: 80)
                    .blur(radius: 30)
            }

            // Floating orbs
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(
                        i % 2 == 0
                            ? Color.pmRed.opacity(0.03)
                            : Color.pmPurple.opacity(0.03)
                    )
                    .frame(width: CGFloat(30 + i * 25))
                    .offset(
                        x: CGFloat(cos(orbRotation / 50 + Double(i) * 1.5)) * CGFloat(70 + i * 25),
                        y: CGFloat(sin(orbRotation / 50 + Double(i) * 1.5)) * CGFloat(40 + i * 18)
                    )
                    .blur(radius: 15)
            }

            VStack(spacing: 30) {
                // Logo + ring
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(Color.pmRed.opacity(0.06), lineWidth: 1)
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.pmRed.opacity(0.06), lineWidth: 2.5)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            PMGradients.brand,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.pmRed.opacity(0.5), radius: 8)

                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(PMGradients.brand)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 10) {
                    Text("PurgeMac")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "FFB5AF")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )

                    Text("Clean · Fast · Yours")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(3)
                        .offset(y: subtitleOffset)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear(perform: startSequence)
    }

    private func startSequence() {
        // Glow pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowScale = 1.2
        }
        // Orb drift
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }
        // Logo
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
            logoOpacity = 1
            logoScale   = 1
        }
        // Text
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1
            subtitleOffset = 0
        }
        // Ring
        withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
            ringProgress = 1
        }
        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                logoOpacity = 0; textOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onComplete()
            }
        }
    }
}
