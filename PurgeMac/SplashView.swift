//
//  SplashView.swift
//  PurgeMac
//
//  Animated launch screen shown before the main UI.
//

import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var logoScale: CGFloat  = 0.65
    @State private var logoOpacity: Double  = 0
    @State private var textOpacity: Double  = 0
    @State private var tagOpacity: Double   = 0
    @State private var ringProgress: CGFloat = 0
    @State private var pulse = false
    @State private var dotsOpacity: Double  = 0

    var body: some View {
        ZStack {
            // Deep background gradient
            LinearGradient(
                colors: [Color(hex: "0b0505"), Color(hex: "18090a"), Color(hex: "220d0e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient bg rings
            GeometryReader { geo in
                let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ForEach(0..<4, id: \.self) { i in
                    let diameter = CGFloat(200 + i * 160)
                    Circle()
                        .stroke(Color.purgePrimary.opacity(0.025 + Double(i) * 0.012), lineWidth: 1)
                        .frame(width: diameter, height: diameter)
                        .position(c)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 3.0 + Double(i) * 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.25),
                            value: pulse
                        )
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 36) {
                // Logo glyph + progress ring
                ZStack {
                    // Track ring
                    Circle()
                        .stroke(Color.purgePrimary.opacity(0.12), lineWidth: 3)
                        .frame(width: 136, height: 136)

                    // Animated fill ring
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "EE3627"), Color(hex: "FF7060")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 136, height: 136)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 2.6), value: ringProgress)

                    // Inner glow
                    Circle()
                        .fill(Color.purgePrimary.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .blur(radius: 14)

                    // App icon
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "EE3627"), Color(hex: "FF8270")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Title + tagline
                VStack(spacing: 10) {
                    Text("PurgeMac")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "f2d4d0")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)

                    Text("Clean. Fast. Yours.")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .opacity(tagOpacity)
                }

                // Loading dots
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.purgeAccent)
                            .frame(width: 5, height: 5)
                            .scaleEffect(pulse ? 1.2 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.18),
                                value: pulse
                            )
                    }
                }
                .opacity(dotsOpacity)
            }
        }
        .onAppear(perform: startSequence)
    }

    private func startSequence() {
        pulse = true

        withAnimation(.spring(response: 0.75, dampingFraction: 0.6).delay(0.1)) {
            logoOpacity = 1
            logoScale   = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.65)) {
            textOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            tagOpacity   = 1
            dotsOpacity  = 1
        }
        withAnimation(.easeInOut(duration: 2.6).delay(0.3)) {
            ringProgress = 1
        }

        // Dismiss after ~3.4 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.35) {
            withAnimation(.easeIn(duration: 0.4)) {
                logoOpacity  = 0
                textOpacity  = 0
                tagOpacity   = 0
                dotsOpacity  = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                onComplete()
            }
        }
    }
}
