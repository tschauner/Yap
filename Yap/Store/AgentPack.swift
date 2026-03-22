// AgentPack.swift
// Yap
//
// Defines the special agents group.
// Special agents are unlocked with Pro.

import Foundation

// MARK: - AgentPack

/// All special agents — unlocked with Pro.
enum AgentPack {
    /// All special agents across all packs.
    static let allAgents: [Agent] = [
        .ex, .conspiracyTheorist, .passiveAggressiveColleague,
        .chef, .disappointedDad, .gymBro
    ]
    
    static let payWall: [Agent] = [
        .conspiracyTheorist, .passiveAggressiveColleague, .ex,
        .disappointedDad, .chef, .gymBro
    ]
}
