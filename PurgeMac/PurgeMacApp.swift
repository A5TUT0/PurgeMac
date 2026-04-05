//
//  PurgeMacApp.swift
//  PurgeMac
//
//  Created by Noah Lezama on 05.04.2026.
//

import SwiftUI

@main
struct PurgeMacApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                } else {
                    ContentView()
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1100, height: 720)
    }
}
