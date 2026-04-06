//
//  ContentView.swift
//  PurgeMac
//
//  Main container with animated transitions.
//

import SwiftUI

struct ContentView: View {
    @State private var selected: AppSection = .dashboard
    @State private var isSidebarOpen: Bool = true
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                mainLayout
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }

    private var mainLayout: some View {
        HStack(spacing: 0) {
            SidebarView(selected: $selected, isSidebarOpen: $isSidebarOpen)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            // Detail pane
            ZStack {
                Color.pmBg.ignoresSafeArea()

                Group {
                    switch selected {
                    case .dashboard:     DashboardView(selected: $selected)
                    case .duplicates:    DuplicatesView()
                    case .loginItems:    LoginItemsView()
                    case .downloads:     DownloadsView()
                    case .storage:       StorageView()
                    case .developer:     DeveloperView()
                    case .keyboardLock:  KeyboardLockView()
                    case .trash:         TrashView()
                    case .settings:      SettingsView()
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 4)))
                .animation(.easeInOut(duration: 0.2), value: selected)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Push dashboard content slightly down if the sidebar is closed
            // to avoid overlapping with traffic lights
            .padding(.top, isSidebarOpen ? 0 : 28)
        }
        .ignoresSafeArea(.all, edges: .top) // Allows sidebar background to sit under traffic lights
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
