// ProAccess.swift
// Yap

import Foundation
import SwiftUI

/// Central access-control layer.
/// Combines Free tier, Pro subscription, and Agent Pack purchases.
enum ProAccess {

    @AppStorage("isPro") static var isPro = false

    // MARK: - Free Tier Limits

    /// The only agent available for free.
    static let freeAgent: Agent = .mom

    /// Max missions per day on the Free tier.
    static let freeDailyLimit = 1

    // MARK: - Agent Access

    /// Returns whether the agent is in the Free tier.
    static func isAgentFree(_ agent: Agent) -> Bool {
        agent == freeAgent
    }

    /// Returns whether the agent is unlocked for this user.
    /// Priority: Free → Pro (base agents) → Pack purchase.
    static func isAgentUnlocked(_ agent: Agent, packStore: AgentPackStore) -> Bool {
        if isAgentFree(agent) { return true }
        if !agent.isBaseAgent {
            // Pack agent: needs the corresponding pack
            guard let pack = agent.pack else { return false }
            return packStore.isPurchased(pack)
        }
        // Base agent: needs Pro
        return isPro
    }

    /// Whether showing the paywall is appropriate for this agent.
    static func requiresPro(_ agent: Agent) -> Bool {
        agent.isBaseAgent && !isAgentFree(agent)
    }

    // MARK: - Mission Limits

    /// Can the user start another mission today?
    static func canCreateMissionToday(missionsCreatedToday: Int) -> Bool {
        isPro || missionsCreatedToday < freeDailyLimit
    }

    // MARK: - Feature Gates

    /// Deadline extension is Pro-only.
    static var canExtend: Bool { isPro }

    /// AI copy is always available — it's the core USP.
    static var canUseAICopy: Bool { true }
}

