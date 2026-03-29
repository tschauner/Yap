// GlobalAgentStats.swift
// Yap

import Foundation

/// Aggregated performance stats for a single agent across ALL users.
struct GlobalAgentStats: Identifiable, Decodable {
    let agent: String
    let completed: Int
    let givenUp: Int
    let total: Int
    let totalUsers: Int
    let successRate: Double
    let avgMinutes: Int?
    
    var id: String { agent }
    
    /// Resolved Agent enum (nil if unknown agent string).
    var resolvedAgent: Agent? {
        Agent(rawValue: agent)
    }
    
    /// Normalized to 0–1 for use with rateColor (Supabase returns 0–100).
    /// Returns nil when total < 3 so rateColor shows .secondary (grey).
    var successRateNormalized: Double? {
        guard total >= 3 else { return nil }
        return successRate / 100
    }

    var successRateFormatted: String {
        guard total >= 3 else { return "–" }
        return "\(Int(successRate))%"
    }
    
    var record: String {
        "\(completed)/\(total)"
    }
    
    var avgTimeFormatted: String {
        guard let avg = avgMinutes else { return "–" }
        if avg < 60 { return "\(avg)m" }
        let h = avg / 60
        let m = avg % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}
