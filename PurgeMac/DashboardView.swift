//
//  DashboardView.swift
//  PurgeMac
//
//  Home overview with animated feature cards.
//

import SwiftUI

struct DashboardView: View {
    @Binding var selected: AppSection
    @Environment(\.colorScheme) var scheme
    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    private let features: [AppSection] = [.duplicates, .loginItems, .downloads, .storage, .developer]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {

                // ── Header ──────────────────────────────────────────────────
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)

                // ── Feature grid ────────────────────────────────────────────
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { i, section in
                        DashboardCard(section: section) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selected = section
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 22)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.12 + Double(i) * 0.08),
                            value: appeared
                        )
                    }
                }

                // ── Tip ─────────────────────────────────────────────────────
                tipRow
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55), value: appeared)

                Spacer(minLength: 20)
            }
            .padding(28)
        }
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: Sub-views

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Welcome to PurgeMac")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Your Mac, immaculate.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge
            }

            // Accent rule
            LinearGradient(
                colors: [Color.purgePrimary.opacity(0.85), Color.purgeAccent.opacity(0)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 2)
            .cornerRadius(1)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: .green.opacity(0.6), radius: 4)
            Text("System OK")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.09))
                .overlay(Capsule().stroke(Color.green.opacity(0.18), lineWidth: 1))
        )
    }

    private var tipRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundColor(.purgeAccent)

            VStack(alignment: .leading, spacing: 3) {
                Text("Quick Tip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.purgeAccent)
                Text("Start with Duplicates — it often reclaims the most space with the least effort.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.purgeAccent.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.purgeAccent.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

// MARK: - Dashboard Card

struct DashboardCard: View {
    let section: AppSection
    let action: () -> Void

    @Environment(\.colorScheme) var scheme
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.purgePrimary.opacity(hovering ? 0.15 : 0.09))
                            .frame(width: 46, height: 46)
                        Image(systemName: section.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.purgePrimary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                        .opacity(hovering ? 1 : 0)
                        .offset(x: hovering ? 0 : -5)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(section.tagline)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .purgeCard(padding: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        hovering
                            ? Color.purgePrimary.opacity(0.2)
                            : Color.purgeStroke(scheme),
                        lineWidth: 1
                    )
            )
            .scaleEffect(hovering ? 1.015 : 1)
            .shadow(
                color: hovering ? Color.purgePrimary.opacity(0.1) : .clear,
                radius: 14, x: 0, y: 6
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { h in hovering = h }
    }
}
