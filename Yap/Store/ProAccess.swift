// ProAccess.swift
// Yap

import Foundation
import SwiftUI

/// Zentrale Stelle die prüft ob ein Feature Pro braucht.
enum ProAccess {
    
    @AppStorage("isPro") static var isPro = false
    
    // MARK: - Free Tier Limits
    
    /// Welcher Agent ist gratis verfügbar.
    static let freeAgent: Agent = .mom
    
    /// Max Missions pro Tag im Free Tier.
    static let freeDailyLimit = 1
    
    // MARK: - Quick Pro Check
    
    /// Ist dieser Agent im Free Tier verfügbar?
    static func isAgentFree(_ agent: Agent) -> Bool {
        agent == freeAgent
    }
    
    /// Braucht dieser Agent Pro?
    static func requiresPro(_ agent: Agent) -> Bool {
        !isAgentFree(agent)
    }
    
    /// Kann der User heute noch eine Mission starten?
    /// Free: 1 pro Tag, Pro: Unlimited
    static func canCreateMissionToday(missionsCreatedToday: Int) -> Bool {
        isPro || missionsCreatedToday < freeDailyLimit
    }
    
    /// Deadline verlängern ist Pro-only.
    static var canExtend: Bool {
        isPro
    }
    
    /// AI Copy ist für alle verfügbar — das ist der USP!
    static var canUseAICopy: Bool {
        true
    }
}
