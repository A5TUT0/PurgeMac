//
//  StorageView.swift
//  PurgeMac
//
//  Disk analysis v2 — animated donut chart & large files, purple gradient theme, premium polish.
//

import SwiftUI

struct StorageView: View {
    @State private var vm = StorageViewModel()
    @State private var appeared = false
    @State private var selectedTab = 0
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Storage", icon: "internaldrive.fill", gradient: PMGradients.purple) {
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Large Files").tag(1)
                }.pickerStyle(.segmented).frame(width: 200)
                Button("Refresh") { vm.load(scanURL: appState.scanURL) }
                    .buttonStyle(PurgeSecondaryButton(color: .pmPurple))
                    .disabled(vm.isLoading)
            }
            PMSeparator()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmPurple, color2: .pmIndigo))
        .onAppear {
            withAnimation { appeared = true }
            vm.load(scanURL: appState.scanURL)
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            PMLoadingState(message: "Analyzing storage…", gradient: PMGradients.purple)
        } else if selectedTab == 0 {
            overviewTab
        } else {
            largeFilesTab
        }
    }

    // MARK: - Overview

    private var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                diskUsageCard
                categoryGrid
            }
            .padding(28)
        }
    }

    private var diskUsageCard: some View {
        HStack(spacing: 36) {
            PMDonutChart(categories: vm.categories, total: vm.totalBytes)
                .frame(width: 180, height: 180)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: appeared)

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Disk Usage")
                        .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(vm.usedFraction > 0
                         ? String(format: "%.1f%% used", vm.usedFraction * 100)
                         : "Calculating…")
                        .font(.system(size: 14)).foregroundColor(.pmTextSecondary)
                }

                // Usage bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.05)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(PMGradients.purple)
                                .frame(width: geo.size.width * CGFloat(min(vm.usedFraction, 1.0)), height: 8)
                                .shadow(color: Color.pmPurple.opacity(0.4), radius: 4)
                                .animation(.spring(response: 1, dampingFraction: 0.8).delay(0.3), value: vm.usedFraction)
                        }
                    }
                    .frame(height: 8).frame(maxWidth: 300)
                    HStack {
                        Text(formatBytes(vm.usedBytes) + " used").font(.system(size: 11)).foregroundColor(.pmTextSecondary)
                        Spacer()
                        Text(formatBytes(vm.availableBytes) + " free").font(.system(size: 11)).foregroundColor(.pmGreen)
                    }.frame(maxWidth: 300)
                }

                HStack(spacing: 24) {
                    miniStat("Total", formatBytes(vm.totalBytes), .white)
                    miniStat("Used", formatBytes(vm.usedBytes), .pmPurple)
                    miniStat("Free", formatBytes(vm.availableBytes), .pmGreen)
                }
            }
            Spacer()
        }
        .glassCard(padding: 28, cornerRadius: 20, glow: .pmPurple)
        .gradientBorder(LinearGradient(colors: [Color.pmPurple.opacity(0.12), Color.pmIndigo.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), cornerRadius: 20)
    }

    private func miniStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.pmTextMuted)
        }
    }

    private var categoryGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Array(vm.categories.enumerated()), id: \.element.id) { i, cat in
                PMCategoryCard(cat: cat, total: vm.totalBytes)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.2 + Double(i) * 0.05), value: appeared)
            }
        }
    }

    // MARK: - Large Files

    private var largeFilesTab: some View {
        Group {
            if vm.largeFiles.isEmpty {
                PMEmptyState(icon: "doc.badge.arrow.up.fill", title: "No Large Files", subtitle: "No files over 50 MB found in your scan path.", gradient: PMGradients.purple)
            } else {
                VStack(spacing: 0) {
                    PMStatsBar {
                        PMInlineStat(value: "\(vm.largeFiles.count)", label: "files over 50 MB")
                        PMInlineStat(value: formatBytes(vm.largeFiles.reduce(0) { $0 + $1.size }), label: "total", color: .pmPurple)
                    }
                    PMSeparator()
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(vm.largeFiles) { file in
                                PMLargeFileRow(file: file)
                            }
                        }.padding(20)
                    }
                }
            }
        }
    }
}

// MARK: - Donut Chart

struct PMDonutChart: View {
    let categories: [StorageCategory]
    let total: Int64
    @State private var animated = false

    private var segments: [(fraction: Double, color: Color)] {
        guard total > 0 else { return [] }
        return categories.map { (Double($0.bytes) / Double(total), Color(hex: $0.colorHex)) }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: 26))
            ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                let start = segments.prefix(i).reduce(0) { $0 + $1.fraction }
                Circle()
                    .trim(from: CGFloat(start * (animated ? 1 : 0)), to: CGFloat((start + seg.fraction) * (animated ? 1 : 0)))
                    .stroke(seg.color, style: StrokeStyle(lineWidth: 26, lineCap: i == 0 ? .round : .butt))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: seg.color.opacity(0.2), radius: 3)
                    .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.06), value: animated)
            }
            VStack(spacing: 2) {
                Image(systemName: "internaldrive.fill").font(.system(size: 16)).foregroundStyle(PMGradients.purple)
                Text(formatBytes(categories.filter { $0.name != "Available" }.reduce(0) { $0 + $1.bytes }))
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("used").font(.system(size: 10)).foregroundColor(.pmTextMuted)
            }
        }
        .onAppear { withAnimation { animated = true } }
    }
}

// MARK: - Category Card

struct PMCategoryCard: View {
    let cat: StorageCategory
    let total: Int64
    @State private var hovering = false

    private var fraction: Double { total > 0 ? Double(cat.bytes) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PMIconBadge(icon: cat.icon, color: Color(hex: cat.colorHex), size: 36)
                Spacer()
                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.pmTextSecondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(cat.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(formatBytes(cat.bytes)).font(.system(size: 12)).foregroundColor(.pmTextSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.04)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: max(0, geo.size.width * CGFloat(fraction)), height: 4)
                        .shadow(color: Color(hex: cat.colorHex).opacity(0.3), radius: 3)
                        .animation(.spring(response: 1, dampingFraction: 0.8).delay(0.3), value: fraction)
                }
            }.frame(height: 4)
        }
        .glassCard(padding: 14, cornerRadius: 12, glow: hovering ? Color(hex: cat.colorHex) : nil)
        .scaleEffect(hovering ? 1.015 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        .onHover { h in hovering = h }
    }
}

// MARK: - Large File Row

struct PMLargeFileRow: View {
    let file: LargeFile
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            PMIconBadge(icon: file.typeIcon, size: 36, gradient: PMGradients.purple)
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                Text(file.directory).font(.system(size: 10)).foregroundColor(.pmTextMuted).lineLimit(1)
            }
            Spacer()
            Text(formatBytes(file.size)).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.pmPurple)
            Button { NSWorkspace.shared.activateFileViewerSelecting([file.url]) } label: {
                Image(systemName: "arrow.up.right.square").font(.system(size: 13)).foregroundColor(.pmTextMuted)
            }.buttonStyle(.plain).opacity(hovering ? 1 : 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(hovering ? 0.04 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.white.opacity(hovering ? 0.08 : 0.04), lineWidth: 1)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { hovering = h } }
    }
}
