// AppDelegate.swift
// Yap

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // TODO: Firebase.configure() wenn Firebase SDK hinzugefügt
        
        // Notification Delegate setzen (für Foreground-Anzeige)
        UNUserNotificationCenter.current().delegate = self
        
        // Notification Actions registrieren
        registerNotificationActions()
        
        return true
    }
    
    // MARK: - Foreground Notifications anzeigen
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
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
            title: "Done ✅",
            options: [.destructive]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Shut up for 30min 🤫",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "YAP_REMINDER",
            actions: [doneAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
