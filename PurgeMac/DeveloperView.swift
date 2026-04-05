//
//  DeveloperView.swift
//  PurgeMac
//
//  Developer tools for cleaning project folders.
//

import SwiftUI

struct DeveloperView: View {
    @State private var vm = DeveloperViewModel()
    @State private var appeared = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if vm.projectFolder == nil {
                folderPickerState
            } else {
                taskGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.purgeBackground(scheme))
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            PurgeSectionHeader(title: "Developer", icon: "hammer.fill")
            Spacer()

            if vm.projectFolder != nil {
                // Folder pill
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.purgePrimary)
                    Text(vm.projectFolder!.lastPathComponent)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
                .onTapGesture { vm.pickFolder() }

                Button("Change Folder") { vm.pickFolder() }
                    .buttonStyle(PurgeSecondaryButton())

                Button("Run All") { vm.runAll() }
                    .buttonStyle(PurgePrimaryButton())
                    .disabled(vm.tasks.allSatisfy { $0.state != .idle })
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Folder picker state (no folder selected)

    private var folderPickerState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.purgePrimary.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.purgePrimary.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.purgePrimary)
                }

                VStack(spacing: 8) {
                    Text("Choose a Project Folder")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("Select the root of your project to unlock\ndeveloper cleanup tools.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                vm.pickFolder()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                    Text("Select Project Folder")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
            }
            .buttonStyle(PurgePrimaryButton())
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.1), value: appeared)

            // Feature preview pills
            let previews = ["node_modules", ".DS_Store", "dist/", ".cache", "lock files", "coverage/"]
            HStack(spacing: 8) {
                ForEach(previews, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Task grid

    private var taskGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Size summary
                folderSummaryBar

                // Task cards
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(Array(vm.tasks.enumerated()), id: \.element.id) { idx, task in
                        DevTaskCard(task: task) {
                            vm.run(taskID: task.id)
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(idx) * 0.05),
                            value: appeared
                        )
                    }
                }

                // Reset all
                HStack {
                    Spacer()
                    Button("Reset Results") { vm.resetAll() }
                        .buttonStyle(PurgeSecondaryButton())
                }
            }
            .padding(20)
        }
    }

    // MARK: - Folder summary bar

    private var folderSummaryBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.projectFolder!.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if vm.isAnalyzingSize {
                ProgressView()
                    .frame(width: 16, height: 16)
                    .scaleEffect(0.8)
            } else if !vm.folderSizeText.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Folder Size")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(vm.folderSizeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purgePrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.purgePrimary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.purgePrimary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - DevTaskCard

private struct DevTaskCard: View {
    let task: DevTask
    let onRun: () -> Void

    @Environment(\.colorScheme) var scheme
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 42, height: 42)
                    Image(systemName: task.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Spacer()

                // State indicator / run button
                taskActionArea
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                Text(task.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Result
            if let result = task.result {
                Text(result)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(task.state == .done ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            (task.state == .done ? Color.green : Color.red).opacity(0.1)
                        )
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.purgeCard(scheme))
                .shadow(
                    color: scheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.05),
                    radius: hovering ? 10 : 5, x: 0, y: hovering ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    task.state == .done ? Color.green.opacity(0.35)
                    : task.state == .running ? Color.purgePrimary.opacity(0.5)
                    : Color.purgeStroke(scheme),
                    lineWidth: 1
                )
        )
        .scaleEffect(hovering ? 1.015 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
        .onHover { h in hovering = h }
    }

    private var iconColor: Color {
        switch task.state {
        case .idle: return .purgePrimary
        case .running: return .orange
        case .done: return .green
        case .failed: return .red
        }
    }

    private var iconBackground: Color {
        switch task.state {
        case .idle: return Color.purgePrimary.opacity(0.1)
        case .running: return Color.orange.opacity(0.1)
        case .done: return Color.green.opacity(0.1)
        case .failed: return Color.red.opacity(0.1)
        }
    }

    @ViewBuilder
    private var taskActionArea: some View {
        switch task.state {
        case .idle:
            Button("Run") { onRun() }
                .buttonStyle(PurgePrimaryButton())
                .font(.system(size: 12, weight: .semibold))

        case .running:
            HStack(spacing: 6) {
                ProgressView()
                    .frame(width: 16, height: 16)
                    .scaleEffect(0.85)
                Text("Running…")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .transition(.scale.combined(with: .opacity))

        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
        }
    }
}
