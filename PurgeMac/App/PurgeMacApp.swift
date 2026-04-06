//
//  PurgeMacApp.swift
//  PurgeMac
//
//  Created by Noah Lezama on 05.04.2026.
//

import SwiftUI

@main
struct PurgeMacApp: App {
    @State private var appState = AppState()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                } else {
                    ContentView()
                        .environment(appState)
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .frame(minWidth: 950, minHeight: 640)
            .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1140, height: 740)
    }
}
