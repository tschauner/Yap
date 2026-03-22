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
            if completedOnboarding {
                MissionView()
                    .environmentObject(viewModel)
                    .environmentObject(store)
                    .task {
                        store.prepare()
                    }
            } else {
                OnboardingView()
                    .environmentObject(store)
            }
        }
    }
}
