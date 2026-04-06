//
//  TrashView.swift
//  PurgeMac
//
//  Visualize and manage your Trash — red/orange gradient theme.
//

import SwiftUI

struct TrashView: View {
    @State private var vm = TrashViewModel()
    @State private var appeared = false
    @State private var showEmptyConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            PMToolbar(title: "Trash", icon: "trash.fill", gradient: PMGradients.trashGrad) {
                if vm.totalSize > 0 {
                    PMFeatureTag(
                        text: formatBytes(vm.totalSize),
                        gradient: PMGradients.trashGrad
                    )
                }
                Button("Refresh") { vm.load() }
                    .buttonStyle(PurgeSecondaryButton(color: .pmOrange))
                    .disabled(vm.isLoading)
                if !vm.items.isEmpty {
                    Button("Empty Trash") { showEmptyConfirm = true }
                        .buttonStyle(PurgePrimaryButton(isDestructive: true, isSmall: true))
                }
            }
            PMSeparator()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PMSectionBackground(color1: Color(hex: "EF4444"), color2: .pmOrange))
        .onAppear {
            withAnimation { appeared = true }
            vm.load()
        }
        .confirmationDialog("Empty Trash?", isPresented: $showEmptyConfirm, titleVisibility: .visible) {
            Button("Empty Trash", role: .destructive) { vm.emptyTrash() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(vm.itemCount) item(s) (\(formatBytes(vm.totalSize))). This cannot be undone.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            PMLoadingState(message: "Reading trash…", gradient: PMGradients.trashGrad)
        } else if vm.items.isEmpty {
            PMEmptyState(
                icon: "trash",
                title: "Trash is Empty",
                subtitle: "Your trash is clean — nothing to see here.",
                gradient: PMGradients.forest
            )
        } else {
            VStack(spacing: 0) {
                // Summary card
                trashSummary
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                PMSeparator()

                // Items list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(vm.items.enumerated()), id: \.element.id) { i, item in
                            TrashItemRow(item: item)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.2).delay(Double(min(i, 20)) * 0.025), value: appeared)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    // MARK: - Trash Summary

    private var trashSummary: some View {
        HStack(spacing: 20) {
            // Trash size visualization
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "EF4444").opacity(0.15), .clear],
                            center: .center, startRadius: 10, endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(PMGradients.trashGrad.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "trash.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(PMGradients.trashGrad)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(formatBytes(vm.totalSize))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(vm.itemCount) item\(vm.itemCount == 1 ? "" : "s") in trash")
                    .font(.system(size: 13))
                    .foregroundColor(.pmTextSecondary)

                HStack(spacing: 8) {
                    Button("Empty Trash") { showEmptyConfirm = true }
                        .buttonStyle(PurgePrimaryButton(isDestructive: true, isSmall: true))
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .glassCard(padding: 20, cornerRadius: 16, glow: Color(hex: "EF4444"))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }
}

// MARK: - Trash Item Row

struct TrashItemRow: View {
    let item: TrashItem
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            PMIconBadge(icon: item.typeIcon, size: 34, gradient: PMGradients.trashGrad)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(formatRelativeDate(item.dateModified))
                    .font(.system(size: 11))
                    .foregroundColor(.pmTextMuted)
            }

            Spacer()

            Text(formatBytes(item.size))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "EF4444"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(hovering ? 0.04 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.white.opacity(hovering ? 0.08 : 0.04), lineWidth: 1)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
