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
    /// - Parameters:
    ///   - profile: Agent-specific escalation timing
    ///   - startOffsetMinutes: Delay before first notification
    ///   - availableMinutes: Total time until deadline. If provided, intervals compress to fit.
    static func buildSchedule(
        profile: EscalationProfile,
        startOffsetMinutes: Int = 0,
        availableMinutes: Int? = nil
    ) -> [(minuteOffset: Int, level: EscalationLevel)] {
        var schedule: [(minuteOffset: Int, level: EscalationLevel)] = []
        
        // Calculate total uncompressed duration
        let uncompressedTotal = EscalationLevel.allCases.reduce(0) { sum, level in
            sum + profile.interval(for: level) * profile.count(for: level)
        }
        
        // Compression: shrink intervals proportionally when deadline is tight
        // Floor at 0.15 → never less than 15% of original intervals
        let effectiveAvailable = (availableMinutes ?? uncompressedTotal) - startOffsetMinutes
        let compression: Double = effectiveAvailable > 0
            ? min(1.0, max(0.15, Double(effectiveAvailable) / Double(uncompressedTotal)))
            : 1.0
        
        let minInterval = 5 // minimum 5 minutes between pushes
        let deadlineBuffer = 5 // last push must be at least 5 min before deadline
        var currentMinute = startOffsetMinutes
        
        // Erste Notification sofort: Agent meldet sich direkt nach Mission-Start
        schedule.append((startOffsetMinutes, .gentle))
        
        for level in EscalationLevel.allCases {
            let count = profile.count(for: level)
            let interval = max(minInterval, Int(Double(profile.interval(for: level)) * compression))
            for _ in 0..<count {
                currentMinute += interval
                // Stop if we'd exceed the deadline buffer
                if let available = availableMinutes, currentMinute >= available - deadlineBuffer {
                    break
                }
                schedule.append((currentMinute, level))
            }
            if let available = availableMinutes, currentMinute >= available - deadlineBuffer {
                break
            }
        }
        
        // Guarantee minimum 6 messages for a decent experience
        let minimumMessages = 6
        if let available = availableMinutes, schedule.count < minimumMessages, schedule.count > 0 {
            let lastMinute = schedule.last?.minuteOffset ?? startOffsetMinutes
            let remainingTime = (available - deadlineBuffer) - lastMinute
            let needed = minimumMessages - schedule.count
            
            if remainingTime > needed * minInterval {
                let fillInterval = max(minInterval, remainingTime / (needed + 1))
                var cursor = lastMinute
                
                for i in 0..<needed {
                    cursor += fillInterval
                    if cursor >= available - deadlineBuffer { break }
                    let level: EscalationLevel = i < needed / 2 ? .urgent : .meltdown
                    schedule.append((cursor, level))
                }
            }
        }
        
        return schedule
    }
}
