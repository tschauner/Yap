// AppDelegate.swift
// Yap

import UserNotifications
import Foundation
internal import UIKit
import SwiftUI

extension Notification.Name {
    static let yapPushReceived = Notification.Name("yapPushReceived")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("completedOnboarding") var completedOnboarding = false
    @AppStorage("isPro") var isPro = false
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        #if DEBUG
        completedOnboarding = false
        #endif
        
        // Notification Delegate setzen (für Foreground-Anzeige)
        UNUserNotificationCenter.current().delegate = self
        
        // Notification Actions registrieren
        registerNotificationActions()
        
        // Register for remote push notifications
        application.registerForRemoteNotifications()
        
        // Sync device metadata (timezone, language) on every launch
        Task { await DeviceService.shared.syncDeviceMetadata() }
        
        return true
    }
    
    // MARK: - Remote Push Token
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        DeviceService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Foreground Notifications anzeigen
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Save latest push body so ActiveMissionView can display it
        let content = notification.request.content
        let userInfo = content.userInfo
        if let goalId = userInfo["goalId"] as? String, !content.body.isEmpty {
            UserDefaults.standard.set(content.body, forKey: "lastPushBody_\(goalId)")
            NotificationCenter.default.post(name: .yapPushReceived, object: nil, userInfo: ["goalId": goalId, "body": content.body])
        }
        return [.banner, .sound, .badge]
    }
    
    // MARK: - Notification Action Response
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let goalIdString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdString) else { return }
        
        switch response.actionIdentifier {
        case "DONE_ACTION":
            // Goal als erledigt markieren → stoppt weitere Notifications
            _ = try? await MissionService.shared.completeMission(goalId)
            
        case "SNOOZE_ACTION":
            // 30 Minuten Ruhe, dann geht's weiter
            // TODO: Implement snooze (re-schedule mit Offset)
            break
            
        case UNNotificationDefaultActionIdentifier:
            // User hat auf die Notification getippt → App öffnen
            // TODO: Deep-link zum Goal
            break
            
        default:
            break
        }
    }
    
    // MARK: - Notification Actions
    
    private func registerNotificationActions() {
        let doneAction = UNNotificationAction(
            identifier: "DONE_ACTION",
            title: "Done",
            options: [.destructive]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Shut up for 30min",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "YAP_REMINDER",
            actions: [doneAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
