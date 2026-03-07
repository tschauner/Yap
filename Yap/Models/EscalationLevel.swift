// EscalationLevel.swift
// Yap

import Foundation

/// Agent-specific timing for each escalation level.
struct EscalationProfile {
    /// Minutes between notifications at each level (gentle → meltdown).
    let intervals: [Int]   // count must == EscalationLevel.allCases.count
    /// How many notifications per level before escalating.
    let counts: [Int]      // count must == EscalationLevel.allCases.count
    
    func interval(for level: EscalationLevel) -> Int {
        intervals[level.rawValue]
    }
    
    func count(for level: EscalationLevel) -> Int {
        counts[level.rawValue]
    }
}

/// Defines how notifications escalate over time.
enum EscalationLevel: Int, CaseIterable {
    case gentle = 0
    case nudge = 1
    case push = 2
    case urgent = 3
    case meltdown = 4
    
    /// Build the full schedule using an agent's escalation profile.
    static func buildSchedule(profile: EscalationProfile, startOffsetMinutes: Int = 0) -> [(minuteOffset: Int, level: EscalationLevel)] {
        var schedule: [(minuteOffset: Int, level: EscalationLevel)] = []
        var currentMinute = startOffsetMinutes
        
        for level in EscalationLevel.allCases {
            let count = profile.count(for: level)
            let interval = profile.interval(for: level)
            for _ in 0..<count {
                schedule.append((currentMinute, level))
                currentMinute += interval
            }
        }
        
        return schedule
    }
}
