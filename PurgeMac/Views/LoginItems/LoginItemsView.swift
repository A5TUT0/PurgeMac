//
//  LoginItemsView.swift
//  PurgeMac
//
//  Manage startup apps v2 — amber gradient theme, premium styling.
//

import SwiftUI

struct LoginItemsView: View {
    @State private var vm = LoginItemsViewModel()
    @State private var appeared = false
    @State private var searchText = ""

    private var filtered: [LoginItem] {
        guard !searchText.isEmpty else { return vm.items }
        return vm.items.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Login Items", icon: "bolt.circle.fill", gradient: PMGradients.amber) {
                PMSearchField(text: $searchText)
                Button("Refresh") { vm.load() }
                    .buttonStyle(PurgeSecondaryButton(color: .pmAmber))
                    .disabled(vm.isLoading)
            }
            PMSeparator()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: .pmAmber, color2: .pmOrange))
        .onAppear {
            withAnimation { appeared = true }
            if vm.items.isEmpty { vm.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            PMLoadingState(message: "Reading login items…", gradient: PMGradients.amber)
        } else if vm.accessDenied {
            PMEmptyState(
                icon: "lock.circle", title: "Access Restricted",
                subtitle: "Grant Full Disk Access in System Settings → Privacy & Security to view login items.",
                gradient: PMGradients.amber,
                actionLabel: "Open Privacy Settings"
            ) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
            }
        } else if vm.items.isEmpty {
            PMEmptyState(icon: "bolt.circle", title: "No Login Items", subtitle: "No LaunchAgent plists were found.", gradient: PMGradients.amber, actionLabel: "Refresh") { vm.load() }
        } else {
            VStack(spacing: 0) {
                // Summary
                PMStatsBar {
                    PMInlineStat(value: "\(vm.items.count)", label: "Total Items")
                    PMInlineStat(value: "\(vm.items.filter(\.isEnabled).count)", label: "Enabled", color: .pmGreen)
                    PMInlineStat(value: "\(vm.items.filter { !$0.isEnabled }.count)", label: "Disabled", color: .pmTextMuted)
                }
                PMSeparator()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { i, item in
                            PMLoginItemRow(item: item, onToggle: { vm.toggle(item: item) }, onRemove: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { vm.remove(item: item) }
                            })
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.22).delay(Double(min(i, 15)) * 0.03), value: appeared)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

struct PMLoginItemRow: View {
    let item: LoginItem
    let onToggle: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    private var appIcon: NSImage? {
        guard !item.executablePath.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFile: item.executablePath)
    }

    var body: some View {
        HStack(spacing: 14) {
            // App icon
            Group {
                if let img = appIcon {
                    Image(nsImage: img).resizable().scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.white.opacity(0.06))
                        Image(systemName: "app.fill").font(.system(size: 18)).foregroundColor(.pmTextMuted)
                    }
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(item.executablePath.isEmpty ? item.label : item.executablePath)
                    .font(.system(size: 10)).foregroundColor(.pmTextMuted).lineLimit(1)
            }

            Spacer()

            // Status
            HStack(spacing: 5) {
                Circle().fill(item.isEnabled ? Color.pmGreen : Color.pmTextMuted).frame(width: 6, height: 6)
                Text(item.isEnabled ? "Active" : "Inactive")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(item.isEnabled ? .pmGreen : .pmTextMuted)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill((item.isEnabled ? Color.pmGreen : Color.pmTextMuted).opacity(0.08)))

            Toggle("", isOn: Binding(get: { item.isEnabled }, set: { _ in onToggle() }))
                .toggleStyle(.switch).tint(.pmAmber).scaleEffect(0.8)

            Button { onRemove() } label: {
                Image(systemName: "minus.circle.fill").font(.system(size: 16)).foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(hovering ? 0.04 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(hovering ? 0.08 : 0.04), lineWidth: 1)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
