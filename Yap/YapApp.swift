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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
