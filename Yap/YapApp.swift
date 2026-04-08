//
//  YapApp.swift
//  Yap
//
//  Created by Philipp Tschauner on 03.03.26.
//

import SwiftUI

@main
struct YapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @StateObject private var viewModel = MissionViewModel()
    @StateObject private var store = StoreManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if completedOnboarding {
                    MissionView()
                        .environmentObject(viewModel)
                        .environmentObject(store)
                } else {
                    OnboardingView()
                        .environmentObject(store)
                }
            }
            .task {
                store.prepare()
                setupQuickActions()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task { await store.updatePurchaseStatus() }
            }
        }
    }
    
    private func setupQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.phitsch.Yap.quit-taunt",
                localizedTitle: L10n.QuickAction.randomQuote,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "hand.wave"),
                userInfo: nil
            )
        ]
    }
}
