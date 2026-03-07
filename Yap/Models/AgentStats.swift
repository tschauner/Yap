// AgentStats.swift
// Yap

import Foundation

/// Performance stats for a single agent.
struct AgentStats: Identifiable {
    let agent: Agent
    let completed: Int
    let givenUp: Int
    
    var id: String { agent.rawValue }
    
    var total: Int { completed + givenUp }
    
    var successRate: Double? {
        guard total > 0 else { return nil }
        return Double(completed) / Double(total)
    }
    
    var successRateFormatted: String {
        guard let rate = successRate else { return "–" }
        return "\(Int(rate * 100))%"
    }
    
    var record: String {
        "\(completed)/\(total)"
    }
}

extension Array where Element == Mission {
    /// Calculate stats per agent from mission history.
    func agentStats() -> [AgentStats] {
        Agent.allCases.map { agent in
            let missions = self.filter { $0.agent == agent }
            let completed = missions.filter { $0.status == .completed }.count
            let givenUp = missions.filter { $0.status == .givenUp }.count
            return AgentStats(agent: agent, completed: completed, givenUp: givenUp)
        }
    }
    
    /// Stats sorted by success rate (highest first), then by total missions.
    func agentLeaderboard() -> [AgentStats] {
        agentStats()
            .filter { $0.total > 0 }
            .sorted { lhs, rhs in
                let lhsRate = lhs.successRate ?? -1
                let rhsRate = rhs.successRate ?? -1
                if lhsRate != rhsRate {
                    return lhsRate > rhsRate
                }
                return lhs.total > rhs.total
            }
    }
}
