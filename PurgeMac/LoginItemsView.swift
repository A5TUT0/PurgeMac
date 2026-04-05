//
//  LoginItemsView.swift
//  PurgeMac
//
//  Manage apps that launch at login.
//

import SwiftUI

struct LoginItemsView: View {
    @State private var vm = LoginItemsViewModel()
    @State private var appeared = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var scheme

    private var filtered: [LoginItem] {
        guard !searchText.isEmpty else { return vm.items }
        return vm.items.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
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
            if vm.items.isEmpty { vm.load() }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            PurgeSectionHeader(title: "Login Items", icon: "power.circle.fill")
            Spacer()

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("Search…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(width: 140)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )

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
            loadingState
        } else if vm.accessDenied {
            accessDeniedState
        } else if vm.items.isEmpty {
            PurgeEmptyState(
                icon: "power.circle",
                title: "No login items found",
                subtitle: "No LaunchAgent plists were found in your system.",
                actionLabel: "Refresh",
                action: { vm.load() }
            )
        } else {
            listContent
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .frame(width: 30, height: 30)
                .scaleEffect(1.4)
                .tint(.purgePrimary)
            Text("Reading login items…")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accessDeniedState: some View {
        PurgeEmptyState(
            icon: "lock.circle",
            title: "Access Restricted",
            subtitle: "PurgeMac needs access to ~/Library/LaunchAgents to list login items. Run the app outside the sandbox or grant Full Disk Access in System Settings → Privacy & Security.",
            actionLabel: "Open Privacy Settings",
            action: {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
                )
            }
        )
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack {
                Text("\(vm.items.count) item(s) · \(vm.items.filter(\.isEnabled).count) enabled")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.purgeSurface(scheme))

            Divider()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { item in
                        LoginItemRow(item: item) {
                            vm.toggle(item: item)
                        } onRemove: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                vm.remove(item: item)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: appeared)
                    }
                }
                .padding(20)
            }
        }
    }
}

// MARK: - LoginItemRow

struct LoginItemRow: View {
    let item: LoginItem
    let onToggle: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) var scheme
    @State private var hovering = false

    private var appIcon: NSImage? {
        guard !item.executablePath.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFile: item.executablePath)
    }

    var body: some View {
        HStack(spacing: 14) {
            // App icon or fallback
            Group {
                if let img = appIcon {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Text(item.executablePath.isEmpty ? item.label : item.executablePath)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status badge
            Text(item.isEnabled ? "Enabled" : "Disabled")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(item.isEnabled ? .green : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(item.isEnabled
                        ? Color.green.opacity(0.1)
                        : Color.secondary.opacity(0.1))
                )

            // Toggle
            Toggle("", isOn: Binding(get: { item.isEnabled }, set: { _ in onToggle() }))
                .toggleStyle(.switch)
                .tint(.purgePrimary)
                .scaleEffect(0.85)

            // Remove
            Button {
                onRemove()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: hovering)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.purgeCard(scheme))
                .shadow(
                    color: scheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.05),
                    radius: 6, x: 0, y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.purgeStroke(scheme), lineWidth: 1)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
