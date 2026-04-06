//
//  DeveloperView.swift
//  PurgeMac
//
//  Developer cleanup tools v2 — forest gradient theme, premium styling.
//

import SwiftUI

struct DeveloperView: View {
    @State private var vm = DeveloperViewModel()
    @State private var appeared = false
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Developer", icon: "terminal.fill", gradient: PMGradients.forest) {
                if vm.projectFolder != nil {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.fill").font(.system(size: 10)).foregroundStyle(PMGradients.forest)
                        Text(vm.projectFolder!.lastPathComponent)
                            .font(.system(size: 12, weight: .medium)).foregroundColor(.pmTextSecondary).lineLimit(1)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    )
                    .onTapGesture { vm.pickFolder() }

                    Button("Change") { vm.pickFolder() }.buttonStyle(PurgeSecondaryButton(color: .pmTeal))
                    Button("Run All") { vm.runAll() }
                        .buttonStyle(PurgePrimaryButton(isSmall: true, gradient: PMGradients.forest))
                        .disabled(vm.tasks.allSatisfy { $0.state != .idle })
                }
            }
            PMSeparator()

            if vm.projectFolder == nil {
                folderPicker
            } else {
                taskGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmTeal, color2: .pmGreen))
        .onAppear {
            withAnimation { appeared = true }
            if vm.projectFolder == nil, let url = appState.scanURL { vm.setFolder(url) }
        }
    }

    // MARK: - Folder Picker

    private var folderPicker: some View {
        VStack(spacing: 32) {
            Spacer()
            PMEmptyState(
                icon: "folder.badge.plus",
                title: "Choose a Project Folder",
                subtitle: "Select the root of your project to clean node_modules,\nbuild artifacts, caches, and more.",
                gradient: PMGradients.forest,
                actionLabel: "Select Project Folder"
            ) { vm.pickFolder() }

            HStack(spacing: 8) {
                ForEach(["node_modules", "dist/", ".cache", ".DS_Store", "lock files"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.pmTextMuted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                                )
                        )
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
            Spacer()
        }
    }

    // MARK: - Task Grid

    private var taskGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                folderSummary

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(Array(vm.tasks.enumerated()), id: \.element.id) { idx, task in
                        PMDevTaskCard(task: task) { vm.run(taskID: task.id) }
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.25).delay(Double(idx) * 0.04), value: appeared)
                    }
                }

                HStack { Spacer(); Button("Reset") { vm.resetAll() }.buttonStyle(PurgeGhostButton()) }
            }
            .padding(20)
        }
    }

    private var folderSummary: some View {
        HStack(spacing: 12) {
            PMIconBadge(icon: "folder.fill", size: 38, gradient: PMGradients.forest)
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.projectFolder!.lastPathComponent).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(vm.projectFolder!.path).font(.system(size: 10, design: .monospaced)).foregroundColor(.pmTextMuted).lineLimit(1)
            }
            Spacer()
            if vm.isAnalyzingSize {
                ProgressView().frame(width: 14, height: 14).scaleEffect(0.8)
            } else if !vm.folderSizeText.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(vm.folderSizeText).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.pmTeal)
                    Text("folder size").font(.system(size: 9)).foregroundColor(.pmTextMuted)
                }
            }
        }
        .glassCard(padding: 16, cornerRadius: 14, glow: .pmTeal)
        .gradientBorder(LinearGradient(colors: [Color.pmTeal.opacity(0.15), Color.pmGreen.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), cornerRadius: 14)
    }
}

// MARK: - Dev Task Card

private struct PMDevTaskCard: View {
    let task: DevTask
    let onRun: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                PMIconBadge(icon: task.icon, color: iconColor, size: 40)
                Spacer()
                actionArea
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(.white)
                Text(task.description).font(.system(size: 11)).foregroundColor(.pmTextSecondary).lineLimit(2).fixedSize(horizontal: false, vertical: true).lineSpacing(2)
            }
            if let result = task.result {
                Text(result)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(task.state == .done ? .pmGreen : .red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(
                        Capsule().fill((task.state == .done ? Color.pmGreen : Color.red).opacity(0.08))
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .glassCard(padding: 14, cornerRadius: 14, glow: hovering ? iconColor : nil)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    task.state == .done ? Color.pmGreen.opacity(0.15) :
                    task.state == .running ? Color.pmTeal.opacity(0.2) :
                    hovering ? Color.white.opacity(0.06) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(hovering ? 1.015 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        .onHover { h in hovering = h }
    }

    private var iconColor: Color {
        switch task.state {
        case .idle: return .pmTeal
        case .running: return .pmAmber
        case .done: return .pmGreen
        case .failed: return .red
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch task.state {
        case .idle:
            Button("Run") { onRun() }.buttonStyle(PurgePrimaryButton(isSmall: true, gradient: PMGradients.forest))
        case .running:
            HStack(spacing: 5) {
                ProgressView().frame(width: 14, height: 14).scaleEffect(0.8)
                Text("Running…").font(.system(size: 10)).foregroundColor(.pmTextSecondary)
            }
        case .done:
            Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(.pmGreen)
                .transition(.scale.combined(with: .opacity))
        case .failed:
            Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(.red)
        }
    }
}
