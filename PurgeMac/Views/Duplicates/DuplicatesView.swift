//
//  DuplicatesView.swift
//  PurgeMac
//
//  Premium duplicates scanner v2 — enhanced visual polish.
//

import SwiftUI

struct DuplicatesView: View {
    @State private var vm = DuplicatesViewModel()
    @State private var appeared = false
    @State private var expandedGroups: Set<UUID> = []
    @State private var showDeleteConfirm = false
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Duplicates", icon: "doc.on.doc.fill", gradient: PMGradients.sunset) {
                if vm.isScanning {
                    ProgressView(value: vm.scanProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 120)
                        .tint(.pmRose)
                }
                if vm.selectedCount > 0 {
                    Button("Delete \(vm.selectedCount)") { showDeleteConfirm = true }
                        .buttonStyle(PurgePrimaryButton(isDestructive: true, isSmall: true))
                }
                if vm.scannedDirectory != nil && !vm.isScanning {
                    Button("Rescan") { vm.rescan() }
                        .buttonStyle(PurgeSecondaryButton(color: .pmRose))
                }
                Button("Scan") {
                    if let url = appState.scanURL { vm.scan(directory: url) }
                }
                .buttonStyle(PurgePrimaryButton(isSmall: true, gradient: PMGradients.sunset))
                .disabled(vm.isScanning || appState.scanURL == nil)
            }
            PMSeparator()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmRose, color2: .pmOrange))
        .onAppear {
            withAnimation { appeared = true }
            if vm.scannedDirectory == nil, let url = appState.scanURL {
                vm.scan(directory: url)
            }
        }
        .confirmationDialog("Move \(vm.selectedCount) file(s) to Trash?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Move to Trash", role: .destructive) { vm.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isScanning {
            VStack(spacing: 28) {
                PMProgressRing(progress: vm.scanProgress, size: 90, lineWidth: 6, icon: "doc.on.doc.fill", gradient: PMGradients.sunset, glowColor: .pmRose)
                VStack(spacing: 8) {
                    Text("Scanning for duplicates…")
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    Text(vm.statusMessage)
                        .font(.system(size: 12)).foregroundColor(.pmTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.groups.isEmpty && vm.scannedDirectory == nil {
            PMEmptyState(icon: "doc.on.doc", title: "Ready to Scan", subtitle: "Scan your folder for duplicate files to free up space.", gradient: PMGradients.sunset, actionLabel: "Scan Now") {
                if let url = appState.scanURL { vm.scan(directory: url) }
            }
        } else if vm.groups.isEmpty {
            PMEmptyState(icon: "checkmark.seal.fill", title: "No Duplicates", subtitle: vm.statusMessage, gradient: PMGradients.forest)
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            PMStatsBar {
                PMInlineStat(value: "\(vm.groups.count)", label: "Groups")
                PMInlineStat(value: "\(vm.filesScanned)", label: "Scanned")
                PMInlineStat(value: formatBytes(vm.totalSavings), label: "Recoverable", color: .pmCoral)
            }

            PMSeparator()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(vm.groups.enumerated()), id: \.element.id) { gi, group in
                        PMDuplicateGroupCard(
                            group: group, isExpanded: expandedGroups.contains(group.id),
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if expandedGroups.contains(group.id) { expandedGroups.remove(group.id) }
                                    else { expandedGroups.insert(group.id) }
                                }
                            },
                            onToggleFile: { fi in vm.toggleFile(groupIndex: gi, fileIndex: fi) }
                        )
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.25).delay(Double(min(gi, 10)) * 0.03), value: appeared)
                    }
                }
                .padding(20)
            }
        }
    }
}

// MARK: - Group Card

struct PMDuplicateGroupCard: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleFile: (Int) -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.pmTextMuted).frame(width: 14)
                    PMIconBadge(icon: "doc.on.doc.fill", size: 36, gradient: PMGradients.sunset)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.displayName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                        Text("\(group.files.count) copies · \(formatBytes(group.fileSize)) each")
                            .font(.system(size: 11)).foregroundColor(.pmTextSecondary)
                    }
                    Spacer()
                    PMFeatureTag(text: "Save \(formatBytes(group.potentialSavings))", gradient: PMGradients.sunset)
                }
                .padding(.horizontal, 16).padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                PMSeparator().padding(.horizontal, 16)
                VStack(spacing: 0) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { fi, file in
                        Button { onToggleFile(fi) } label: {
                            HStack(spacing: 12) {
                                PMCheckbox(isSelected: file.isSelected)
                                Image(systemName: "doc.fill").font(.system(size: 13)).foregroundColor(.pmTextMuted)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(file.name).font(.system(size: 13)).foregroundColor(.white).lineLimit(1)
                                        if fi == 0 {
                                            Text("ORIGINAL").font(.system(size: 8, weight: .bold)).foregroundColor(.pmGreen)
                                                .padding(.horizontal, 5).padding(.vertical, 2)
                                                .background(Capsule().fill(Color.pmGreen.opacity(0.1)))
                                        }
                                    }
                                    Text(file.directory).font(.system(size: 10)).foregroundColor(.pmTextMuted).lineLimit(1)
                                }
                                Spacer()
                                Text(formatRelativeDate(file.dateModified)).font(.system(size: 11)).foregroundColor(.pmTextMuted)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(file.isSelected ? Color.pmRed.opacity(0.04) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if fi < group.files.count - 1 {
                            PMSeparator().padding(.leading, 54)
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .glassCard(padding: 0, cornerRadius: 14, glow: hovering ? .pmRose : nil)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}
