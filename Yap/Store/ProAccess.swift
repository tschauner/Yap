// ProAccess.swift
// Yap

import Foundation

/// Zentrale Stelle die prüft ob ein Feature Pro braucht.
enum ProAccess {
    
    // MARK: - Free Tier Limits
    
    /// Welcher Agent ist gratis verfügbar.
    static let freeAgent: NagTone = .bestFriend
    
    /// Max aktive Goals im Free Tier.
    static let freeGoalLimit = 1
    
    // MARK: - Checks
    
    /// Ist dieser Agent im Free Tier verfügbar?
    static func isAgentFree(_ tone: NagTone) -> Bool {
        tone == freeAgent
    }
    
    /// Braucht dieser Agent Pro?
    static func requiresPro(_ tone: NagTone) -> Bool {
        !isAgentFree(tone)
    }
    
    /// Kann der User ein neues Goal erstellen? (Goal-Limit)
    @MainActor
    static func canCreateGoal(currentActiveCount: Int) -> Bool {
        StoreManager.shared.isPro || currentActiveCount < freeGoalLimit
    }
    
    /// Kann der User AI-generierte Copy nutzen?
    @MainActor
    static var canUseAICopy: Bool {
        StoreManager.shared.isPro
    }
}
