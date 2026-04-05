//
//  DownloadsView.swift
//  PurgeMac
//
//  Browse and clean the downloads folder.
//

import SwiftUI

struct DownloadsView: View {
    @State private var vm = DownloadsViewModel()
    @State private var appeared = false
    @State private var showDeleteConfirm = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var scheme

    private var displayFiles: [DownloadFile] {
        let sorted = vm.sorted
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

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
            if vm.files.isEmpty { vm.loadDefaults() }
        }
        .confirmationDialog(
            "Move \(vm.selected.count) file(s) to Trash?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) { vm.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will free \(formatBytes(vm.selectedSize)).")
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            PurgeSectionHeader(title: "Downloads", icon: "arrow.down.to.line.circle.fill")
            Spacer()

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("Search files…", text: $searchText).textFieldStyle(.plain).font(.system(size: 13)).frame(width: 130)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))

            // Sort picker
            Picker("", selection: $vm.sortOrder) {
                ForEach(DownloadsViewModel.SortOrder.allCases) { o in
                    Text(o.rawValue).tag(o)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)

            if vm.selected.count > 0 {
                Button("Delete \(vm.selected.count) File(s)") { showDeleteConfirm = true }
                    .buttonStyle(PurgePrimaryButton(isDestructive: true))
            }

            Button("Open Folder…") { vm.pickFolder() }
                .buttonStyle(PurgeSecondaryButton())
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
                Text("Reading downloads folder…").font(.system(size: 14)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.files.isEmpty {
            PurgeEmptyState(
                icon: "arrow.down.to.line.circle",
                title: "Downloads folder is empty",
                subtitle: "There are no files in the detected Downloads folder, or access was denied.",
                actionLabel: "Choose Folder…",
                action: { vm.pickFolder() }
            )
        } else {
            VStack(spacing: 0) {
                // Summary bar
                HStack(spacing: 20) {
                    // Select-all checkbox
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { vm.toggleAll() }
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(vm.allSelected ? Color.purgePrimary : Color.secondary.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 16, height: 16)
                                if vm.allSelected {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.purgePrimary).frame(width: 16, height: 16)
                                    Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                                }
                            }
                            Text("Select All").font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().frame(height: 16)

                    statBadge(value: "\(vm.files.count)", label: "Files")
                    statBadge(value: formatBytes(vm.totalSize), label: "Total")
                    if vm.selected.count > 0 {
                        statBadge(value: formatBytes(vm.selectedSize), label: "Selected", color: .purgePrimary)
                    }
                    Spacer()

                    if let url = vm.downloadsURL {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill").font(.system(size: 10)).foregroundColor(.secondary)
                            Text(url.path).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1).frame(maxWidth: 220)
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Color.purgeSurface(scheme))

                Divider()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(displayFiles.enumerated()), id: \.element.id) { i, file in
                            DownloadFileRow(file: file,
                                           onToggle: { vm.toggleFile(file) },
                                           onReveal: { vm.revealInFinder(file) })
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.22).delay(Double(min(i, 20)) * 0.025), value: appeared)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private func statBadge(value: String, label: String, color: Color = .secondary) -> some View {
        HStack(spacing: 4) {
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }
}

// MARK: - DownloadFileRow

struct DownloadFileRow: View {
    let file: DownloadFile
    let onToggle: () -> Void
    let onReveal: () -> Void

    @Environment(\.colorScheme) var scheme
    @State private var hovering = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(file.isSelected ? Color.purgePrimary : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if file.isSelected {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.purgePrimary).frame(width: 18, height: 18)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: file.isSelected)

                // File icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: file.typeColor).opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: file.typeIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: file.typeColor))
                }

                // Name + meta
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                    HStack(spacing: 8) {
                        Text(formatBytes(file.size)).font(.system(size: 11)).foregroundColor(.secondary)
                        Text("·").foregroundColor(.secondary.opacity(0.4))
                        Text(formatRelativeDate(file.dateAdded)).font(.system(size: 11)).foregroundColor(.secondary)
                        if !file.fileExtension.isEmpty {
                            Text(file.fileExtension.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: file.typeColor))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: file.typeColor).opacity(0.1)))
                        }
                    }
                }

                Spacer()

                // Reveal in Finder button (on hover)
                Button {
                    onReveal()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: hovering)
            }
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        file.isSelected
                            ? Color.purgePrimary.opacity(0.06)
                            : Color.purgeCard(scheme)
                    )
                    .shadow(
                        color: scheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05),
                        radius: 5, x: 0, y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        file.isSelected
                            ? Color.purgePrimary.opacity(0.25)
                            : Color.purgeStroke(scheme),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { hovering = h } }
    }
}
