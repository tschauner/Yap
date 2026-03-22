// ProAccess.swift
// Yap

import Foundation
import SwiftUI

/// Central access-control layer.
/// Combines Free tier and Pro lifetime purchase.
enum ProAccess {

    @AppStorage("isPro") static var isPro = false

    // MARK: - Free Tier Limits

    /// Max missions per day on the Free tier.
    static let freeDailyLimit = 1

    // MARK: - Agent Access

    /// Base agents are free. Special agents require Pro.
    static func isAgentUnlocked(_ agent: Agent) -> Bool {
        if agent.isBaseAgent { return true }
        return isPro
    }

    /// Whether this agent requires Pro to use.
    static func requiresPro(_ agent: Agent) -> Bool {
        !isAgentUnlocked(agent)
    }

    // MARK: - Mission Limits

    /// Can the user start another mission today?
    static func canCreateMissionToday(missionsCreatedToday: Int) -> Bool {
        isPro || missionsCreatedToday < freeDailyLimit
    }

    // MARK: - Feature Gates

    /// Deadline extension is Pro-only.
    static var canExtend: Bool { isPro }

    /// Deadline change is Pro-only.
    static var canChangeDeadline: Bool { isPro }

    /// AI copy is always available — it's the core USP.
    static var canUseAICopy: Bool { true }
}

