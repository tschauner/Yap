// MockData.swift
// Yap
//
// Debug-only mock data for Leaderboard testing.
// Activate via Xcode Scheme → Arguments → Launch Arguments: -MOCK_LEADERBOARD

#if DEBUG

import Foundation

enum MockData {
    
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-MOCK_LEADERBOARD")
    }
    
    // MARK: - Global Leaderboard (all agents, varied stats)
    
    static let globalLeaderboard: [GlobalAgentStats] = [
        GlobalAgentStats(agent: "drill",          completed: 412, givenUp: 88,  total: 500, totalUsers: 187, successRate: 82,   avgMinutes: 45),
        GlobalAgentStats(agent: "chef",            completed: 289, givenUp: 71,  total: 360, totalUsers: 142, successRate: 80,   avgMinutes: 38),
        GlobalAgentStats(agent: "mom",             completed: 534, givenUp: 146, total: 680, totalUsers: 310, successRate: 79,   avgMinutes: 67),
        GlobalAgentStats(agent: "gymBro",          completed: 198, givenUp: 62,  total: 260, totalUsers: 95,  successRate: 76,   avgMinutes: 32),
        GlobalAgentStats(agent: "bestFriend",      completed: 623, givenUp: 217, total: 840, totalUsers: 402, successRate: 74,   avgMinutes: 82),
        GlobalAgentStats(agent: "boss",            completed: 301, givenUp: 119, total: 420, totalUsers: 198, successRate: 72,   avgMinutes: 55),
        GlobalAgentStats(agent: "disappointedDad", completed: 156, givenUp: 64,  total: 220, totalUsers: 88,  successRate: 71,   avgMinutes: 91),
        GlobalAgentStats(agent: "grandma",         completed: 278, givenUp: 122, total: 400, totalUsers: 175, successRate: 70,   avgMinutes: 73),
        GlobalAgentStats(agent: "ex",              completed: 134, givenUp: 66,  total: 200, totalUsers: 78,  successRate: 67,   avgMinutes: 48),
        GlobalAgentStats(agent: "therapist",       completed: 189, givenUp: 111, total: 300, totalUsers: 134, successRate: 63,   avgMinutes: 105),
        GlobalAgentStats(agent: "passiveAggressiveColleague", completed: 87, givenUp: 53, total: 140, totalUsers: 56, successRate: 62, avgMinutes: 58),
        GlobalAgentStats(agent: "conspiracyTheorist", completed: 72, givenUp: 48, total: 120, totalUsers: 45, successRate: 60,  avgMinutes: 71),
    ]
    
    // MARK: - Your Missions (mixed history for "You" tab)
    
    static let missionHistory: [Mission] = {
        let device = "mock-debug-device"
        let now = Date()
        
        func date(daysAgo: Int, hour: Int = 10) -> Date {
            Calendar.current.date(byAdding: .day, value: -daysAgo, to:
                Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
            )!
        }
        
        func mission(
            agent: Agent,
            title: String,
            status: MissionStatus,
            daysAgo: Int,
            minutes: Int? = nil,
            extended: Bool = false,
            notifications: Int = 8
        ) -> Mission {
            let created = date(daysAgo: daysAgo)
            let deadline = date(daysAgo: daysAgo, hour: 23)
            let completed: Date? = status == .completed ? created.addingTimeInterval(Double(minutes ?? 60) * 60) : nil
            let givenUp: Date? = status == .givenUp ? created.addingTimeInterval(Double(minutes ?? 120) * 60) : nil
            
            return Mission(
                id: UUID(),
                deviceId: device,
                title: title,
                agent: agent,
                language: "de",
                status: status,
                createdAt: created,
                deadline: deadline,
                completedAt: completed,
                givenUpAt: givenUp,
                extended: extended,
                notificationsScheduled: notifications,
                notificationsSent: status == .completed ? notifications / 2 : notifications,
                escalationLevelAtCompletion: status == .completed ? 2 : nil,
                timeToCompleteMinutes: status == .completed ? minutes : nil,
                isPro: true,
                usedAiCopy: true
            )
        }
        
        return [
            // Mom — 3 completed, 1 given up → 75%
            mission(agent: .mom, title: "Wohnung aufräumen", status: .completed, daysAgo: 1, minutes: 45),
            mission(agent: .mom, title: "Einkaufen gehen", status: .completed, daysAgo: 3, minutes: 30),
            mission(agent: .mom, title: "Arzttermin vereinbaren", status: .completed, daysAgo: 7, minutes: 90),
            mission(agent: .mom, title: "Steuererklärung anfangen", status: .givenUp, daysAgo: 10, minutes: 180),
            
            // Drill — 4 completed, 0 given up → 100%
            mission(agent: .drill, title: "10km laufen", status: .completed, daysAgo: 2, minutes: 55),
            mission(agent: .drill, title: "Garage aufräumen", status: .completed, daysAgo: 5, minutes: 40),
            mission(agent: .drill, title: "Bewerbung schreiben", status: .completed, daysAgo: 8, minutes: 120),
            mission(agent: .drill, title: "Keller entrümpeln", status: .completed, daysAgo: 14, minutes: 95),
            
            // Best Friend — 2 completed, 2 given up → 50%
            mission(agent: .bestFriend, title: "Präsentation fertig machen", status: .completed, daysAgo: 4, minutes: 70),
            mission(agent: .bestFriend, title: "Bücher zurückbringen", status: .givenUp, daysAgo: 6),
            mission(agent: .bestFriend, title: "Portfolio updaten", status: .completed, daysAgo: 9, minutes: 85),
            mission(agent: .bestFriend, title: "Emails beantworten", status: .givenUp, daysAgo: 12),
            
            // Chef — 2 completed, 1 given up → 67%
            mission(agent: .chef, title: "Abendessen kochen", status: .completed, daysAgo: 2, minutes: 35),
            mission(agent: .chef, title: "Meal Prep Sonntag", status: .completed, daysAgo: 6, minutes: 50),
            mission(agent: .chef, title: "Küche deep clean", status: .givenUp, daysAgo: 11),
            
            // Disappointed Dad — 1 completed, 2 given up → 33%
            mission(agent: .disappointedDad, title: "Fahrrad reparieren", status: .givenUp, daysAgo: 3),
            mission(agent: .disappointedDad, title: "Rasen mähen", status: .completed, daysAgo: 8, minutes: 40),
            mission(agent: .disappointedDad, title: "Regal zusammenbauen", status: .givenUp, daysAgo: 15, extended: true),
            
            // Therapist — 1 completed, 0 given up → 100% (but only 1 mission)
            mission(agent: .therapist, title: "Journaling anfangen", status: .completed, daysAgo: 5, minutes: 25),
            
            // Ex — 0 completed, 1 given up → 0%
            mission(agent: .ex, title: "Sachen aus der Wohnung holen", status: .givenUp, daysAgo: 13),
        ]
    }()
}

#endif
