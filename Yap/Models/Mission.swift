// Mission.swift
// Yap

import Foundation

// MARK: - Mission Item (Queue — leichtgewichtig)

/// Ein simpler Queue-Eintrag: nur Titel + Datum. Wird zur Mission wenn Agent gewählt wird.
struct MissionItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.createdAt = .now
    }
}

// MARK: - Mission Status

enum MissionStatus: String, Codable, Equatable {
    case queued
    case active
    case completed
    case givenUp = "given_up"
}

// MARK: - Mission (aktiv / abgeschlossen — volles Objekt)

/// Eine aktive oder beendete Mission mit allen Details.
struct Mission: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceId: String
    var title: String
    var agent: Agent
    var language: String
    var status: MissionStatus
    var createdAt: Date
    var deadline: Date
    var completedAt: Date?
    var givenUpAt: Date?
    var extended: Bool
    var notificationsScheduled: Int
    var notificationsSent: Int
    var escalationLevelAtCompletion: Int?
    var timeToCompleteMinutes: Int?
    var isPro: Bool
    var usedAiCopy: Bool
    
    var isCompleted: Bool { status == .completed }
    var isActive: Bool { status == .active }
    var isGivenUp: Bool { status == .givenUp }
    var isExpired: Bool { status == .active && deadline < .now }
    var isFailed: Bool { isGivenUp || isExpired }
    var isFinished: Bool { isCompleted || isFailed }
    
    /// Wie lange die Mission aktiv war
    var duration: TimeInterval {
        let end = completedAt ?? givenUpAt ?? Date()
        return end.timeIntervalSince(createdAt)
    }
    
    var estimatedIgnoredMessages: Int {
        notificationsSent
    }
    
    var peakEscalation: EscalationLevel {
        let schedule = EscalationLevel.buildSchedule(profile: agent.escalationProfile)
        let elapsedMinutes = Int(duration / 60)
        let reached = schedule.filter { $0.minuteOffset <= elapsedMinutes }
        return reached.last?.level ?? .gentle
    }
    
    var tagline: String {
        isCompleted ? agent.completionMessage : agent.pitch
    }
    
    var durationFormatted: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(mins)min" : "\(mins)min"
    }
    
    var durationMinutes: Int { timeToCompleteMinutes ?? Int(duration / 60) }
}


// MARK: - Device Stats

struct DeviceStats: Codable, Equatable {
    let totalCompleted: Int
    let totalGivenUp: Int
    let totalPending: Int
    let avgMinutes: Int?
    let currentStreak: Int
    let completionRate: Double
    let totalMissions: Int
    let fastestMinutes: Int?
    let slowestMinutes: Int?
    let favoriteAgent: String?
}

