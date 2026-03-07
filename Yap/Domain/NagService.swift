// NagService.swift
// Yap

import Foundation
import UserNotifications

// MARK: - Protocol

protocol NagProviding: Actor {
    func requestPermission() async -> Bool
    @discardableResult func scheduleEscalation(for mission: Mission, startDelay: Int) -> Int
    func missionCompleted(_ missionId: UUID)
    func cancelNotifications(for goalId: UUID)
}

/// Schedules escalating local notifications for a goal.
/// Uses NagCopy templates to generate dynamic, agent-aware messages.
///
/// iOS erlaubt max. 64 pending notifications — unser volles Schedule
/// hat ~24 Einträge, also genug Platz für mehrere Goals falls nötig.
actor NagService: NagProviding {
    
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
    ///   - mission: Das Ziel des Users (enthält deadline)
    ///   - startDelay: Verzögerung in Minuten bis zur ersten Notification (default: 0 = sofort starten)
    /// - Returns: Anzahl der geplanten Notifications
    @discardableResult
    func scheduleEscalation(for mission: Mission, startDelay: Int = 0) -> Int {
        let center = UNUserNotificationCenter.current()
        
        // Alte Notifications für dieses Goal entfernen
        cancelNotifications(for: mission.id)
        
        let schedule = EscalationLevel.buildSchedule(profile: mission.agent.escalationProfile, startOffsetMinutes: startDelay)
        
        // Nur Notifications planen die VOR der Deadline liegen
        let minutesUntilDeadline = Int(mission.deadline.timeIntervalSinceNow / 60)
        let withinDeadline = schedule.filter { $0.minuteOffset < minutesUntilDeadline }
        
        // Max 64 pending insgesamt, wir nehmen max 24 pro Goal
        let capped = Array(withinDeadline.prefix(24))
        
        for (index, entry) in capped.enumerated() {
            let template = NagCopy.template(
                agent: mission.agent,
                level: entry.level,
                index: index
            )
            let resolved = template.resolved(with: mission.title)
            
            let content = UNMutableNotificationContent()
            content.title = resolved.title
            content.body = resolved.body
            content.sound = notificationSound(for: entry.level)
            content.categoryIdentifier = "YAP_REMINDER"
            content.userInfo = [
                "goalId": mission.id.uuidString,
                "level": entry.level.rawValue
            ]
            // Badge zeigt Eskalations-Level
            content.badge = NSNumber(value: entry.level.rawValue + 1)
            
            let seconds = max(TimeInterval(entry.minuteOffset * 60), 1)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: seconds,
                repeats: false
            )
            
            let identifier = notificationId(goalId: mission.id, index: index)
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
        
        print("📬 Scheduled \(capped.count) notifications for '\(mission.title)' (\(mission.agent.displayName))")
        return capped.count
    }
    
    // MARK: - Complete / Cancel
    
    /// Goal erledigt → alle pending Notifications canceln + Badge reset.
    func missionCompleted(_ missionId: UUID) {
        cancelNotifications(for: missionId)
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
