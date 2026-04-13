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
        
//        #if DEBUG
//        completedOnboarding = false
//        #endif
        
        // Notification Delegate setzen (für Foreground-Anzeige)
        UNUserNotificationCenter.current().delegate = self
        
        // Notification Actions registrieren
        registerNotificationActions()

        // Ensure custom push sounds are available in Library/Sounds
        installNotificationSoundFilesIfNeeded()
        
        // Register for remote push notifications
        application.registerForRemoteNotifications()
        
        // Sync device metadata (timezone, language) on every launch
        Task { await DeviceService.shared.syncDeviceMetadata() }
        
        // Track app open event (for funnel analytics)
        AnalyticsService.shared.track(.appOpened)
        
        return true
    }

    private func installNotificationSoundFilesIfNeeded() {
        let soundNames = [
            "yap_select_f_1", "yap_select_f_2", "yap_select_f_3", "yap_select_f_4",
            "yap_select_m_1", "yap_select_m_2", "yap_select_m_3",
            "yap_fail_f_1", "yap_fail_f_2", "yap_fail_m_1", "yap_fail_m_2",
            "yap_success_f_1", "yap_success_f_2", "yap_success_m_1", "yap_success_m_2", "yap_success_m_3",
        ]

        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return
        }

        let soundsDir = libraryURL.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

        for name in soundNames {
            let destination = soundsDir.appendingPathComponent("\(name).caf")

            if FileManager.default.fileExists(atPath: destination.path) {
                continue
            }

            let source = Bundle.main.url(forResource: name, withExtension: "caf")
                ?? Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds")

            guard let source else {
                continue
            }

            do {
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Keep app launch resilient if copy fails
            }
        }
    }
    
    // MARK: - Foreground Re-Registration
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Re-register APNs token every time the app comes to foreground.
        // This ensures the server always has a fresh token and push_enabled = true,
        // even if the server disabled push due to a BadDeviceToken error.
        application.registerForRemoteNotifications()
        
        // Update last_seen_at for engagement tracking
        Task { await DeviceService.shared.touchLastSeen() }
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
            guard ProAccess.isPro else { return }
            // Shift pending remote notifications by +30 minutes
            try? await MissionService.shared.snoozeMission(goalId, minutes: 30)
            
        case UNNotificationDefaultActionIdentifier:
            // User hat auf die Notification getippt → App öffnen
            // TODO: Deep-link zum Goal
            break
            
        default:
            break
        }
    }
    
    // MARK: - Notification Actions
    
    func registerNotificationActions() {
        let doneAction = UNNotificationAction(
            identifier: "DONE_ACTION",
            title: L10n.Mission.notificationDone,
            options: []
        )
        
        if ProAccess.isPro {
            let snoozeAction = UNNotificationAction(
                identifier: "SNOOZE_ACTION",
                title: L10n.Mission.notificationSnooze,
                options: []
            )
            
            let category = UNNotificationCategory(
                identifier: "YAP_REMINDER",
                actions: [doneAction, snoozeAction],
                intentIdentifiers: [],
                options: []
            )
            UNUserNotificationCenter.current().setNotificationCategories([category])
        } else {
            let category = UNNotificationCategory(
                identifier: "YAP_REMINDER",
                actions: [doneAction],
                intentIdentifiers: [],
                options: []
            )
            UNUserNotificationCenter.current().setNotificationCategories([category])
        }
    }
}
