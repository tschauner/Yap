// Goal.swift
// Yap

import Foundation

/// A daily goal the user wants to accomplish.
struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var tone: NagTone
    var createdAt: Date
    var completedAt: Date?
    var extended: Bool       // Hat der User 24h verlängert?
    var notificationsScheduled: Int  // Wie viele Notifications geplant wurden
    
    var isCompleted: Bool { completedAt != nil }
    
    /// Day this goal belongs to (yyyy-MM-dd)
    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: createdAt)
    }
    
    /// Wie lange das Goal aktiv war (bis jetzt oder bis completedAt)
    var duration: TimeInterval {
        let end = completedAt ?? Date()
        return end.timeIntervalSince(createdAt)
    }
    
    /// Wie viele Nachrichten der User ignoriert hat (basierend auf verstrichener Zeit)
    var estimatedIgnoredMessages: Int {
        let schedule = EscalationLevel.buildSchedule()
        let elapsedMinutes = Int(duration / 60)
        return schedule.prefix(notificationsScheduled).filter { $0.minuteOffset <= elapsedMinutes }.count
    }
    
    /// Höchstes erreichtes Escalation Level
    var peakEscalation: EscalationLevel {
        let schedule = EscalationLevel.buildSchedule()
        let elapsedMinutes = Int(duration / 60)
        let reached = schedule.filter { $0.minuteOffset <= elapsedMinutes }
        return reached.last?.level ?? .gentle
    }
    
    init(id: UUID = UUID(), title: String, tone: NagTone = .bestFriend, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.tone = tone
        self.createdAt = createdAt
        self.extended = false
        self.notificationsScheduled = 0
    }
}
