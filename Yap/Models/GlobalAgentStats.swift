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
    
    var successRateFormatted: String {
        "\(Int(successRate))%"
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
    
    enum CodingKeys: String, CodingKey {
        case agent, completed, total
        case givenUp = "given_up"
        case totalUsers = "total_users"
        case successRate = "success_rate"
        case avgMinutes = "avg_minutes"
    }
}
