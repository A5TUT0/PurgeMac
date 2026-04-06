//
//  DashboardView.swift
//  PurgeMac
//
//  Premium dashboard v2 — hero with animated mesh gradient, health score, quick actions,
//  memory pressure, feature cards with premium hover effects.
//

import SwiftUI
internal import Combine

struct DashboardView: View {
    @Binding var selected: AppSection
    @Environment(AppState.self) var appState
    @State private var appeared = false
    @State private var memoryPressure: Double = 0
    @State private var healthScore: Int = 0
    @State private var healthAnimated: Int = 0
    @State private var cpuLoad: Double = 0
    @State private var memoryUsed: Int64 = 0
    
    // Auto-refresh timer
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    private let features: [(section: AppSection, gradient: LinearGradient, description: String, accent: Color)] = [
        (.duplicates, PMGradients.sunset, "Find and remove duplicate files to free up space", .pmRose),
        (.loginItems, PMGradients.amber, "Control which apps launch at startup", .pmAmber),
        (.downloads, PMGradients.ocean, "Clean your downloads folder fast", .pmBlue),
        (.storage, PMGradients.purple, "Analyze disk usage & find large files", .pmPurple),
        (.developer, PMGradients.forest, "Clean dev project build artifacts", .pmTeal),
        (.keyboardLock, PMGradients.keyboard, "Lock keyboard for safe cleaning", .pmPink),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                systemStatsRow
                quickActionsRow
                PMSectionLabel(text: "TOOLS")
                    .padding(.horizontal, 4)
                featureGrid
                tipCard
                Spacer(minLength: 20)
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmRed, color2: .pmPurple))
        .onAppear {
            withAnimation { appeared = true }
            calculateHealth()
            refreshSystemStats()
        }
        .onReceive(timer) { _ in
            if appeared { refreshSystemStats() }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("Good \(greeting)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("👋")
                        .font(.system(size: 26))
                }

                Text("Your Mac is looking healthy. Use the tools\nbelow to keep it that way.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    statusPill(icon: "checkmark.shield.fill", text: "System OK", color: .pmGreen)
                    statusPill(icon: "folder.fill", text: appState.scanPathDisplay, color: .pmCoral)
                }
                .padding(.top, 2)
            }

            Spacer()

            // Health ring
            healthRing
        }
        .glassCard(padding: 26, cornerRadius: 20, glow: .pmRed)
        .gradientBorder(
            LinearGradient(
                colors: [Color.pmRed.opacity(0.15), Color.pmCoral.opacity(0.08), Color.pmOrange.opacity(0.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            cornerRadius: 20
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -12)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
    }

    // MARK: - Health Ring

    private var healthRing: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pmRed.opacity(0.08), .clear],
                        center: .center, startRadius: 10, endRadius: 60
                    )
                )
                .frame(width: 110, height: 110)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 6)
                .frame(width: 85, height: 85)

            // Progress
            Circle()
                .trim(from: 0, to: CGFloat(healthAnimated) / 100)
                .stroke(
                    PMGradients.brand,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 85, height: 85)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.pmRed.opacity(0.3), radius: 6)
                .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: healthAnimated)

            VStack(spacing: 1) {
                Text("\(healthAnimated)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: healthAnimated)
                Text("Health")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.pmTextMuted)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }

    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.pmTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
                .overlay(Capsule().stroke(color.opacity(0.1), lineWidth: 0.5))
        )
    }

    // MARK: - System Stats

    private var systemStatsRow: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            PMStatCard(value: ProcessInfo.processInfo.operatingSystemVersionString, label: "macOS", icon: "desktopcomputer", gradient: PMGradients.brand)
            PMStatCard(value: formatBytes(memoryUsed), label: "RAM Used", icon: "memorychip", gradient: PMGradients.purple)
            PMStatCard(value: String(format: "%.1f%%", cpuLoad), label: "CPU Load", icon: "cpu", gradient: PMGradients.ocean)
            PMStatCard(value: formatUptime(), label: "Uptime", icon: "clock", gradient: PMGradients.forest)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        HStack(spacing: 10) {
            quickAction(icon: "trash.fill", label: "View Trash", color: .pmOrange) {
                withAnimation { selected = .trash }
            }
            quickAction(icon: "keyboard.fill", label: "Lock Keyboard", color: .pmPink) {
                withAnimation { selected = .keyboardLock }
            }
            quickAction(icon: "memorychip", label: "Memory: \(String(format: "%.0f%%", memoryPressure))", color: memoryColor) {}

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func quickAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.pmTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(0.08))
                    .overlay(Capsule().stroke(color.opacity(0.1), lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }

    private var memoryColor: Color {
        if memoryPressure > 80 { return .pmRed }
        if memoryPressure > 60 { return .pmAmber }
        return .pmGreen
    }

    private func formatUptime() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let hours = Int(uptime) / 3600
        let mins  = (Int(uptime) % 3600) / 60
        if hours > 24 { return "\(hours / 24)d \(hours % 24)h" }
        return "\(hours)h \(mins)m"
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(Array(features.enumerated()), id: \.offset) { i, feature in
                DashboardFeatureCard(
                    section: feature.section,
                    gradient: feature.gradient,
                    description: feature.description,
                    accentColor: feature.accent
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selected = feature.section
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(i) * 0.05),
                    value: appeared
                )
            }
        }
    }

    // MARK: - Tip

    private var tipCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PMGradients.amber.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(PMGradients.amber)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Pro Tip")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.pmAmber)
                Text("Start with Duplicates — it often reclaims the most space with the least effort.")
                    .font(.system(size: 12))
                    .foregroundColor(.pmTextSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .glassCard(padding: 14, cornerRadius: 12)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
    }

    // MARK: - Calculations

    private func calculateHealth() {
        // Simple health score based on available disk space
        let volumeURL = URL(fileURLWithPath: "/")
        if let rv = try? volumeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
           let total = rv.volumeTotalCapacity,
           let available = rv.volumeAvailableCapacityForImportantUsage {
            let freePercent = Double(available) / Double(total)
            healthScore = min(100, Int(freePercent * 200 + 30)) // generous scaling
        } else {
            healthScore = 85
        }
        // Animate in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                healthAnimated = healthScore
            }
        }
    }

    private func refreshSystemStats() {
        let (used, _, pressure) = SystemMonitor.shared.getMemoryUsage()
        let load = SystemMonitor.shared.getCPUUsage()
        
        withAnimation(.easeOut(duration: 0.5)) {
            memoryUsed = Int64(used)
            memoryPressure = pressure
            if load > 0 {
                cpuLoad = load
            }
        }
    }
}

// MARK: - Mach System Monitor
class SystemMonitor {
    static let shared = SystemMonitor()
    private var previousInfo = host_cpu_load_info()
    
    private init() { _ = getCPULoad() }
    
    func getCPUUsage() -> Double {
        let cpuLoad = getCPULoad()
        let userDiff = Double(cpuLoad.cpu_ticks.0 - previousInfo.cpu_ticks.0)
        let sysDiff  = Double(cpuLoad.cpu_ticks.1 - previousInfo.cpu_ticks.1)
        let idleDiff = Double(cpuLoad.cpu_ticks.2 - previousInfo.cpu_ticks.2)
        let niceDiff = Double(cpuLoad.cpu_ticks.3 - previousInfo.cpu_ticks.3)
        let totalTicks = userDiff + sysDiff + idleDiff + niceDiff
        let totalUsed = userDiff + sysDiff + niceDiff
        previousInfo = cpuLoad
        return totalTicks > 0 ? (totalUsed / totalTicks) * 100.0 : 0.0
    }
    
    private func getCPULoad() -> host_cpu_load_info {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var cpuLoad = host_cpu_load_info()
        _ = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        return cpuLoad
    }
    
    func getMemoryUsage() -> (used: Double, total: Double, percentage: Double) {
        let total = ProcessInfo.processInfo.physicalMemory
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        if result == KERN_SUCCESS {
            let pageSize = Double(vm_page_size)
            let usedMemory = Double(vmStats.active_count + vmStats.wire_count + vmStats.compressor_page_count) * pageSize
            return (usedMemory, Double(total), (usedMemory / Double(total)) * 100.0)
        }
        return (0, Double(total), 0)
    }
}

// MARK: - Feature Card (v2)

struct DashboardFeatureCard: View {
    let section: AppSection
    let gradient: LinearGradient
    let description: String
    var accentColor: Color = .pmRed
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    PMIconBadge(icon: section.icon, size: 44, gradient: gradient)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(gradient)
                        .opacity(hovering ? 1 : 0.25)
                        .scaleEffect(hovering ? 1.15 : 1)
                        .rotationEffect(.degrees(hovering ? 0 : -10))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.pmTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
            .glassCard(padding: 16, cornerRadius: 14, glow: hovering ? accentColor : nil)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        hovering
                            ? accentColor.opacity(0.2)
                            : Color.white.opacity(0.04),
                        lineWidth: 1
                    )
            )
            .scaleEffect(hovering ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { h in hovering = h }
    }
}
