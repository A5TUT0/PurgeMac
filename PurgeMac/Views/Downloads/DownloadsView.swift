//
//  DownloadsView.swift
//  PurgeMac
//
//  Clean downloads folder v2 — ocean gradient theme, premium styling.
//

import SwiftUI

struct DownloadsView: View {
    @State private var vm = DownloadsViewModel()
    @State private var appeared = false
    @State private var showDeleteConfirm = false
    @State private var searchText = ""

    private var displayFiles: [DownloadFile] {
        let sorted = vm.sorted
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Downloads", icon: "arrow.down.circle.fill", gradient: PMGradients.ocean) {
                PMSearchField(text: $searchText, placeholder: "Search files…")
                Picker("", selection: $vm.sortOrder) {
                    ForEach(DownloadsViewModel.SortOrder.allCases) { o in Text(o.rawValue).tag(o) }
                }.pickerStyle(.menu).frame(width: 130)
                if vm.selected.count > 0 {
                    Button("Delete \(vm.selected.count)") { showDeleteConfirm = true }
                        .buttonStyle(PurgePrimaryButton(isDestructive: true, isSmall: true))
                }
                Button("Open Folder…") { vm.pickFolder() }
                    .buttonStyle(PurgeSecondaryButton(color: .pmCyan))
            }
            PMSeparator()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmBlue, color2: .pmCyan))
        .onAppear {
            withAnimation { appeared = true }
            if vm.files.isEmpty { vm.loadDefaults() }
        }
        .confirmationDialog("Move \(vm.selected.count) file(s) to Trash?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Move to Trash", role: .destructive) { vm.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will free \(formatBytes(vm.selectedSize)).") }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            PMLoadingState(message: "Reading downloads…", gradient: PMGradients.ocean)
        } else if vm.files.isEmpty {
            PMEmptyState(icon: "arrow.down.to.line.circle", title: "No Files Found", subtitle: "Downloads folder is empty or access was denied.", gradient: PMGradients.ocean, actionLabel: "Choose Folder…") { vm.pickFolder() }
        } else {
            VStack(spacing: 0) {
                // Summary
                PMStatsBar {
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { vm.toggleAll() }
                    } label: {
                        HStack(spacing: 6) {
                            PMCheckbox(isSelected: vm.allSelected)
                            Text("Select All").font(.system(size: 12)).foregroundColor(.pmTextSecondary)
                        }
                    }.buttonStyle(.plain)

                    Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 16)

                    PMInlineStat(value: "\(vm.files.count)", label: "Files")
                    PMInlineStat(value: formatBytes(vm.totalSize), label: "Total")
                    if vm.selected.count > 0 {
                        PMInlineStat(value: formatBytes(vm.selectedSize), label: "Selected", color: .pmBlue)
                    }
                }

                PMSeparator()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(displayFiles.enumerated()), id: \.element.id) { i, file in
                            PMDownloadRow(file: file, onToggle: { vm.toggleFile(file) }, onReveal: { vm.revealInFinder(file) })
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.2).delay(Double(min(i, 20)) * 0.02), value: appeared)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

struct PMDownloadRow: View {
    let file: DownloadFile
    let onToggle: () -> Void
    let onReveal: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                PMCheckbox(isSelected: file.isSelected)
                PMIconBadge(icon: file.typeIcon, color: Color(hex: file.typeColor), size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(formatBytes(file.size)).font(.system(size: 11)).foregroundColor(.pmTextSecondary)
                        Text("·").foregroundColor(.pmTextMuted)
                        Text(formatRelativeDate(file.dateAdded)).font(.system(size: 11)).foregroundColor(.pmTextSecondary)
                        if !file.fileExtension.isEmpty {
                            Text(file.fileExtension.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: file.typeColor))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: file.typeColor).opacity(0.08)))
                        }
                    }
                }
                Spacer()
                Button { onReveal() } label: {
                    Image(systemName: "arrow.up.right.square").font(.system(size: 13)).foregroundColor(.pmTextMuted)
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(file.isSelected ? Color.pmBlue.opacity(0.06) : Color.white.opacity(hovering ? 0.03 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        file.isSelected ? Color.pmBlue.opacity(0.15) :
                            hovering ? Color.white.opacity(0.06) : Color.white.opacity(0.04),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
