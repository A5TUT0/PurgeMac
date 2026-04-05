//
//  DuplicatesView.swift
//  PurgeMac
//
//  UI for finding and removing duplicate files.
//

import SwiftUI

struct DuplicatesView: View {
    @State private var vm = DuplicatesViewModel()
    @State private var appeared = false
    @State private var expandedGroups: Set<UUID> = []
    @State private var showDeleteConfirm = false
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
            if vm.scannedDirectory == nil { vm.scanHomeDirectory() }
        }
        .confirmationDialog(
            "Move \(vm.selectedCount) file(s) to Trash?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) { vm.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will free \(formatBytes(vm.groups.filter { _ in true }.flatMap(\.files).filter(\.isSelected).reduce(0) { $0 + $1.size })) of space.")
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            PurgeSectionHeader(title: "Duplicates", icon: "doc.on.doc.fill")
            Spacer()

            if vm.isScanning {
                ProgressView(value: vm.scanProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
                    .tint(.purgePrimary)
            }

            if vm.selectedCount > 0 {
                Button("Delete \(vm.selectedCount) File(s)") { showDeleteConfirm = true }
                    .buttonStyle(PurgePrimaryButton(isDestructive: true))
                    .transition(.scale.combined(with: .opacity))
            }

            if vm.scannedDirectory != nil && !vm.isScanning {
                Button("Rescan") { vm.rescan() }
                    .buttonStyle(PurgeSecondaryButton())
            }

            Button("Scan Folder…") { vm.pickDirectory() }
                .buttonStyle(PurgePrimaryButton())
                .disabled(vm.isScanning)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isScanning {
            scanningState
        } else if vm.groups.isEmpty && vm.scannedDirectory == nil {
            PurgeEmptyState(
                icon: "doc.on.doc",
                title: "No folder scanned yet",
                subtitle: "Choose a folder and PurgeMac will detect every duplicate file inside it.",
                actionLabel: "Choose Folder…",
                action: { vm.pickDirectory() }
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: appeared)
        } else if vm.groups.isEmpty {
            PurgeEmptyState(
                icon: "checkmark.seal.fill",
                title: "No duplicates found",
                subtitle: vm.statusMessage,
                actionLabel: "Scan Another Folder",
                action: { vm.pickDirectory() }
            )
        } else {
            resultsList
        }
    }

    // MARK: - Scanning state

    private var scanningState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.purgePrimary.opacity(0.12), lineWidth: 3)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: vm.scanProgress)
                    .stroke(Color.purgePrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: vm.scanProgress)
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.purgePrimary)
            }
            VStack(spacing: 6) {
                Text("Scanning…")
                    .font(.system(size: 16, weight: .semibold))
                Text(vm.statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results list

    private var resultsList: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack(spacing: 20) {
                statBadge(value: "\(vm.groups.count)", label: "Groups")
                statBadge(value: "\(vm.filesScanned)", label: "Files Scanned")
                statBadge(value: formatBytes(vm.totalSavings), label: "Recoverable", color: .purgePrimary)
                Spacer()
                if vm.selectedCount > 0 {
                    Text("\(vm.selectedCount) file(s) selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.purgeSurface(scheme))

            Divider()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.groups.enumerated()), id: \.element.id) { gi, group in
                        DuplicateGroupCard(
                            group: group,
                            groupIndex: gi,
                            isExpanded: expandedGroups.contains(group.id),
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if expandedGroups.contains(group.id) {
                                        expandedGroups.remove(group.id)
                                    } else {
                                        expandedGroups.insert(group.id)
                                    }
                                }
                            },
                            onToggleFile: { fi in vm.toggleFile(groupIndex: gi, fileIndex: fi) }
                        )
                    }
                }
                .padding(20)
            }
        }
    }

    private func statBadge(value: String, label: String, color: Color = .secondary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - DuplicateGroupCard

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let groupIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleFile: (Int) -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.purgeAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text("\(group.files.count) copies · \(formatBytes(group.fileSize)) each")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    // Savings badge
                    Text("Save \(formatBytes(group.potentialSavings))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.purgePrimary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.purgePrimary.opacity(0.1))
                        )

                    if group.selectedCount > 0 {
                        Text("\(group.selectedCount) selected")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { fi, file in
                        DuplicateFileRow(
                            file: file,
                            isFirst: fi == 0,
                            onToggle: { onToggleFile(fi) }
                        )
                        if fi < group.files.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.purgeCard(scheme))
                .shadow(
                    color: scheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06),
                    radius: 8, x: 0, y: 3
                )
        )
    }
}

// MARK: - DuplicateFileRow

struct DuplicateFileRow: View {
    let file: DuplicateFile
    let isFirst: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(file.isSelected ? Color.purgePrimary : Color.secondary.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if file.isSelected {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.purgePrimary)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: file.isSelected)

                Image(systemName: "doc.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.purgeSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(file.name)
                            .font(.system(size: 13))
                            .lineLimit(1)
                        if isFirst {
                            Text("ORIGINAL")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.purgeSecondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.purgeSecondary.opacity(0.15)))
                        }
                    }
                    Text(file.directory)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(formatRelativeDate(file.dateModified))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                file.isSelected
                    ? Color.purgePrimary.opacity(0.04)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
