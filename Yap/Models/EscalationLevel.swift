// EscalationLevel.swift
// Yap

import Foundation

/// Defines how notifications escalate over time.
enum EscalationLevel: Int, CaseIterable {
    case gentle = 0     // Every hour
    case nudge = 1      // Every 45 min
    case push = 2       // Every 30 min
    case urgent = 3     // Every 15 min
    case meltdown = 4   // Every 10 min
    
    /// Minutes between notifications at this level
    var intervalMinutes: Int {
        switch self {
        case .gentle: 60
        case .nudge: 45
        case .push: 30
        case .urgent: 15
        case .meltdown: 10
        }
    }
    
    /// How many notifications to send at this level before escalating
    var count: Int {
        switch self {
        case .gentle: 3
        case .nudge: 3
        case .push: 4
        case .urgent: 4
        case .meltdown: 10  // Just keeps going
        }
    }
    
    /// Build the full schedule: returns array of minute-offsets from start
    static func buildSchedule(startOffsetMinutes: Int = 0) -> [(minuteOffset: Int, level: EscalationLevel)] {
        var schedule: [(minuteOffset: Int, level: EscalationLevel)] = []
        var currentMinute = startOffsetMinutes
        
        for level in EscalationLevel.allCases {
            for _ in 0..<level.count {
                schedule.append((currentMinute, level))
                currentMinute += level.intervalMinutes
            }
        }
        
        return schedule
    }
}
