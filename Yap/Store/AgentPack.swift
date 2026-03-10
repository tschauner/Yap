// AgentPack.swift
// Yap
//
// Defines purchasable agent packs.
// All marketing copy (name, description, price) comes from
// StoreKit via App Store Connect localization — not from this file.

import Foundation

// MARK: - AgentPack

enum AgentPack: String, CaseIterable, Identifiable, Codable {
    case chaos   = "com.philipptschauner.yap.pack.chaos"
    case legends = "com.philipptschauner.yap.pack.legends"

    var id: String { rawValue }

    /// StoreKit product identifier.
    var productID: String { rawValue }

    /// Agents included in this pack.
    var agents: [Agent] {
        switch self {
        case .chaos:   return [.ex, .conspiracyTheorist, .passiveAggressiveColleague]
        case .legends: return [.gordonRamsay, .disappointedDad, .gymBro]
        }
    }

    // MARK: Display (fallbacks — real strings come from StoreKit localization)

    /// Emoji badge for the pack tile.
    var emoji: String {
        switch self {
        case .chaos:   return "🔥"
        case .legends: return "⚡️"
        }
    }

    /// Fallback name shown before StoreKit product loads.
    var fallbackName: String {
        switch self {
        case .chaos:   return "Chaos Pack"
        case .legends: return "Legends Pack"
        }
    }

    /// Fallback description shown before StoreKit product loads.
    var fallbackDescription: String {
        switch self {
        case .chaos:
            return "The Ex, The Theorist & The Colleague"
        case .legends:
            return "Gordon Ramsay, Disappointed Dad & Gym Bro"
        }
    }
}
