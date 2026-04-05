//
//  StorageView.swift
//  PurgeMac
//
//  Storage visualization with an animated donut chart.
//

import SwiftUI

struct StorageView: View {
    @State private var vm = StorageViewModel()
    @State private var appeared = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.purgeBackground(scheme))
        .onAppear {
            withAnimation { appeared = true }
            vm.load()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            PurgeSectionHeader(title: "Storage", icon: "internaldrive.fill")
            Spacer()
            Button("Refresh") { vm.load() }
                .buttonStyle(PurgeSecondaryButton())
                .disabled(vm.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            VStack(spacing: 20) {
                ProgressView()
                    .frame(width: 30, height: 30)
                    .scaleEffect(1.4)
                    .tint(.purgePrimary)
                Text("Analysing storage…").font(.system(size: 14)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    mainCard
                    categoryGrid
                }
                .padding(28)
            }
        }
    }

    // MARK: - Main card

    private var mainCard: some View {
        HStack(spacing: 40) {
            // Donut chart
            DonutChart(
                categories: vm.categories.filter { $0.name != "Available" },
                available: vm.availableBytes,
                total: vm.totalBytes
            )
            .frame(width: 200, height: 200)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: appeared)

            // Summary stats
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Disk Usage")
                        .font(.system(size: 22, weight: .bold))
                    Text(vm.usedFraction > 0
                         ? String(format: "%.0f%% used", vm.usedFraction * 100)
                         : "Calculating…")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Usage bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.purgeBackground(scheme))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purgePrimary, Color.purgeAccent],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * CGFloat(min(vm.usedFraction, 1.0)),
                                    height: 12
                                )
                                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: vm.usedFraction)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.purgeStroke(scheme), lineWidth: 1)
                        )
                    }
                    .frame(height: 12)
                    .frame(maxWidth: 320)

                    HStack {
                        Text(formatBytes(vm.usedBytes) + " used")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                        Spacer()
                        Text(formatBytes(vm.availableBytes) + " available")
                            .font(.system(size: 11)).foregroundColor(.green)
                    }
                    .frame(maxWidth: 320)
                }

                // Quick stats row
                HStack(spacing: 28) {
                    quickStat(label: "Total", value: formatBytes(vm.totalBytes))
                    quickStat(label: "Used",  value: formatBytes(vm.usedBytes), color: .purgePrimary)
                    quickStat(label: "Free",  value: formatBytes(vm.availableBytes), color: .green)
                }
            }
            Spacer()
        }
        .purgeCard(padding: 28)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
    }

    private func quickStat(label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Category grid

    private var categoryGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(Array(vm.categories.enumerated()), id: \.element.id) { i, cat in
                CategoryCard(cat: cat, total: vm.totalBytes)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2 + Double(i) * 0.07), value: appeared)
            }
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let cat: StorageCategory
    let total: Int64
    @Environment(\.colorScheme) var scheme

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(cat.bytes) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: cat.colorHex).opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: cat.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: cat.colorHex))
                }
                Spacer()
                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cat.name)
                    .font(.system(size: 13, weight: .semibold))
                Text(formatBytes(cat.bytes))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Mini bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.purgeBackground(scheme))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: max(geo.size.width * CGFloat(fraction), 0), height: 5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3), value: fraction)
                }
            }
            .frame(height: 5)
        }
        .purgeCard(padding: 16)
    }
}

// MARK: - Donut Chart

struct DonutChart: View {
    let categories: [StorageCategory]
    let available: Int64
    let total: Int64

    @State private var animated = false

    private var segments: [(fraction: Double, color: Color)] {
        guard total > 0 else { return [] }
        var s = categories.map { (Double($0.bytes) / Double(total), Color(hex: $0.colorHex)) }
        // Append available
        s.append((Double(available) / Double(total), Color(hex: "3B9450")))
        return s
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 30))

            // Segments
            ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                let start = segments.prefix(i).reduce(0, { $0 + $1.fraction })
                Circle()
                    .trim(
                        from: CGFloat(start * (animated ? 1 : 0)),
                        to:   CGFloat((start + seg.fraction) * (animated ? 1 : 0))
                    )
                    .stroke(
                        seg.color,
                        style: StrokeStyle(lineWidth: 30, lineCap: i == 0 ? .round : .butt)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.06), value: animated)
            }

            // Center label
            VStack(spacing: 2) {
                Text(formatBytes(total - available))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("used")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation { animated = true }
        }
    }
}
