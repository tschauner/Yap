// NagService.swift
// Yap

import Foundation
import UserNotifications

/// Schedules escalating local notifications for a goal.
/// Uses NagCopy templates to generate dynamic, tone-aware messages.
///
/// iOS erlaubt max. 64 pending notifications — unser volles Schedule
/// hat ~24 Einträge, also genug Platz für mehrere Goals falls nötig.
actor NagService {
    
    static let shared = NagService()
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }
    
    func permissionStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    // MARK: - Schedule
    
    /// Plant die komplette Eskalations-Kette für ein Goal.
    /// - Parameters:
    ///   - goal: Das Ziel des Users
    ///   - startDelay: Verzögerung in Minuten bis zur ersten Notification (default: 0 = sofort starten)
    /// - Returns: Anzahl der geplanten Notifications
    @discardableResult
    func scheduleEscalation(for goal: Goal, startDelay: Int = 0) -> Int {
        let center = UNUserNotificationCenter.current()
        
        // Alte Notifications für dieses Goal entfernen
        cancelNotifications(for: goal.id)
        
        let schedule = EscalationLevel.buildSchedule(startOffsetMinutes: startDelay)
        
        // Max 64 pending insgesamt, wir nehmen max 24 pro Goal
        let capped = Array(schedule.prefix(24))
        
        for (index, entry) in capped.enumerated() {
            let template = NagCopy.template(
                tone: goal.tone,
                level: entry.level,
                index: index
            )
            let resolved = template.resolved(with: goal.title)
            
            let content = UNMutableNotificationContent()
            content.title = resolved.title
            content.body = resolved.body
            content.sound = notificationSound(for: entry.level)
            content.categoryIdentifier = "YAP_REMINDER"
            content.userInfo = [
                "goalId": goal.id.uuidString,
                "level": entry.level.rawValue
            ]
            // Badge zeigt Eskalations-Level
            content.badge = NSNumber(value: entry.level.rawValue + 1)
            
            let seconds = max(TimeInterval(entry.minuteOffset * 60), 1)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: seconds,
                repeats: false
            )
            
            let identifier = notificationId(goalId: goal.id, index: index)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error {
                    print("⚠️ Failed to schedule notification \(index): \(error.localizedDescription)")
                }
            }
        }
        
        print("📬 Scheduled \(capped.count) notifications for '\(goal.title)' (\(goal.tone.displayName))")
        return capped.count
    }
    
    // MARK: - Complete / Cancel
    
    /// Goal erledigt → alle pending Notifications canceln + Badge reset.
    func goalCompleted(_ goalId: UUID) {
        cancelNotifications(for: goalId)
        clearBadge()
    }
    
    /// Alle Notifications für ein bestimmtes Goal entfernen.
    func cancelNotifications(for goalId: UUID) {
        let center = UNUserNotificationCenter.current()
        let prefix = "yap-\(goalId.uuidString)"
        
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: matching)
            print("🗑️ Cancelled \(matching.count) notifications for goal \(goalId)")
        }
    }
    
    /// Alles canceln (App-Reset, etc.).
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearBadge()
    }
    
    // MARK: - Debug
    
    /// Gibt alle pending Notifications in der Konsole aus.
    func debugPrintPending() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending notifications: \(requests.count)")
        for req in requests {
            let trigger = req.trigger as? UNTimeIntervalNotificationTrigger
            let seconds = trigger?.timeInterval ?? 0
            print("  [\(req.identifier)] in \(Int(seconds/60))min — \(req.content.title): \(req.content.body)")
        }
    }
    
    // MARK: - Private
    
    private func notificationId(goalId: UUID, index: Int) -> String {
        "yap-\(goalId.uuidString)-\(index)"
    }
    
    private func notificationSound(for level: EscalationLevel) -> UNNotificationSound {
        switch level {
        case .gentle, .nudge:
            return .default
        case .push, .urgent:
            return UNNotificationSound.defaultCritical
        case .meltdown:
            return UNNotificationSound.defaultCritical
        }
    }
    
    private func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}
