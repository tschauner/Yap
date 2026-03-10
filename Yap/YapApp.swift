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
    @AppStorage("appearance") var appearance: Appearance = .dark
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var store = StoreManager()
    @StateObject private var packStore = AgentPackStore()
    
    var body: some Scene {
        WindowGroup {
            if completedOnboarding {
                MissionView()
                    .environmentObject(viewModel)
                    .environmentObject(store)
                    .environmentObject(packStore)
                    .preferredColorScheme(appearance.scheme)
                    .task {
                        store.prepare()
                        packStore.prepare()
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
