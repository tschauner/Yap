// Agent.swift
// Yap

import Foundation
import SwiftUI

/// The persona that sends escalating notifications.
enum Agent: String, Codable, CaseIterable, Identifiable {
    // MARK: - Base Agents (Free + Pro)
    case bestFriend  // Casual, loving roasts
    case mom        // Guilt trips from caring to devastation
    case boss        // Corporate passive-aggression
    case drill       // Military drill sergeant
    case therapist   // Starts validating, gets uncomfortably honest
    case grandma     // Emotional warfare from grandma
    
    static var standard: [Self] = [.mom, .bestFriend, .boss, .drill, .therapist, .grandma]
    
    // MARK: - Chaos Pack
    case ex                          // Passive-aggressive heartbreak
    case conspiracyTheorist          // Unhinged but weirdly motivating
    case passiveAggressiveColleague  // "No no, it's fine. I'll do it."
    
    // MARK: - Legends Pack
    case chef            // RAW. UNACCEPTABLE. FINISH IT.
    case disappointedDad // Says nothing. You feel everything.
    case gymBro          // BRO. LETS GET IT. NO DAYS OFF.
    
    var id: String { rawValue }
    
    var displayName: String {
        "agent_\(rawValue)_display_name".localized
    }
    
    var celebrationEmoji: String {
        switch self {
        case .bestFriend: "🤙"
        case .mom: "❤️"
        case .boss: "💼"
        case .drill: "🫡"
        case .therapist: "🧘"
        case .grandma: "🍪"
        case .ex: "💔"
        case .conspiracyTheorist: "👁️"
        case .passiveAggressiveColleague: "🙂"
        case .chef: "🔥"
        case .disappointedDad: "😶"
        case .gymBro: "💪"
        }
    }
    
    var image: String {
        switch self {
        case .bestFriend: return "golden"
        case .mom: return "dachs"
        case .boss: return "shepard"
        case .drill: return "dobermann"
        case .therapist: return "pudel"
        case .grandma: return "terrier"
        // Pack agents — assets TBD
        case .ex: return "dachs"
        case .conspiracyTheorist: return "terrier"
        case .passiveAggressiveColleague: return "shepard"
        case .chef: return "dobermann"
        case .disappointedDad: return "golden"
        case .gymBro: return "dobermann"
        }
    }
    
    /// Emoji is only used inside push notification content, not in app UI.
    var emoji: String {
        switch self {
        case .bestFriend: "🫶"
        case .mom: "🫵"
        case .boss: "👔"
        case .drill: "🪖"
        case .therapist: "🛋️"
        case .grandma: "👵"
        case .ex: "💔"
        case .conspiracyTheorist: "🛸"
        case .passiveAggressiveColleague: "🙂"
        case .chef: "👨‍🍳"
        case .disappointedDad: "🤦"
        case .gymBro: "💪"
        }
    }
    
    var description: String {
        "agent_\(rawValue)_description".localized
    }
    
    /// One-liner roast when the user gives up. Used in the Loser screen.
    var giveUpRoast: String {
        "agent_\(rawValue)_give_up_roast".localized
    }
    
    /// The agent's pitch — what they'd say to get hired.
    var pitch: String {
        "agent_\(rawValue)_pitch".localized
    }
    
    /// One-liner the agent uses to sell Pro — shown in onboarding paywall.
    var proPitch: String {
        "agent_\(rawValue)_pro_pitch".localized
    }
    
    /// Alert message when the user taps "Give up" — asking for confirmation.
    var giveUpConfirmation: String {
        "agent_\(rawValue)_give_up_confirmation".localized
    }
    
    var alert: String {
        "\(displayName): \(giveUpConfirmation)"
    }
    
    /// Congratulations message when the user completes a mission.
    var completionMessage: String {
        "agent_\(rawValue)_completion".localized
    }
    
    /// Agent's roast when the user extends the deadline by 24h.
    var extendRoast: String {
        "agent_\(rawValue)_extend_roast".localized
    }
    
    // MARK: - Visual Identity
    
    /// Accent color for this persona.
    var accentColor: Color {
        switch self {
        case .bestFriend: .blue
        case .mom: Color(.systemPink)
        case .boss: Color(.systemGray)
        case .drill: .green
        case .therapist: .purple
        case .grandma: Color(red: 0.85, green: 0.55, blue: 0.45)
        case .ex: Color(red: 0.8, green: 0.2, blue: 0.4)
        case .conspiracyTheorist: Color(red: 0.2, green: 0.7, blue: 0.4)
        case .passiveAggressiveColleague: Color(.systemGray2)
        case .chef: Color(red: 0.85, green: 0.15, blue: 0.15)
        case .disappointedDad: Color(red: 0.5, green: 0.38, blue: 0.25)
        case .gymBro: .orange
        }
    }
    
    /// Three-color palette for aurora/gradient effects. First color is always the accentColor.
    var auroraColors: [Color] {
        switch self {
        case .bestFriend:
            [accentColor, Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 0.9)]
        case .mom:
            [accentColor, Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.7, green: 0.2, blue: 0.5)]
        case .boss:
            [accentColor, Color(red: 0.3, green: 0.35, blue: 0.45), Color(red: 0.15, green: 0.2, blue: 0.35)]
        case .drill:
            [accentColor, Color(red: 0.2, green: 0.5, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.1)]
        case .therapist:
            [accentColor, Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.2, blue: 0.6)]
        case .grandma:
            [accentColor, Color(red: 0.75, green: 0.45, blue: 0.55), Color(red: 0.6, green: 0.35, blue: 0.4)]
        case .ex:
            [accentColor, Color(red: 0.6, green: 0.1, blue: 0.3), Color(red: 0.9, green: 0.1, blue: 0.2)]
        case .conspiracyTheorist:
            [accentColor, Color(red: 0.1, green: 0.9, blue: 0.3), Color(red: 0.0, green: 0.5, blue: 0.2)]
        case .passiveAggressiveColleague:
            [accentColor, Color(red: 0.45, green: 0.5, blue: 0.55), Color(red: 0.3, green: 0.35, blue: 0.5)]
        case .chef:
            [accentColor, Color(red: 0.95, green: 0.3, blue: 0.1), Color(red: 0.7, green: 0.1, blue: 0.0)]
        case .disappointedDad:
            [accentColor, Color(red: 0.4, green: 0.3, blue: 0.2), Color(red: 0.35, green: 0.25, blue: 0.15)]
        case .gymBro:
            [accentColor, Color(red: 1.0, green: 0.5, blue: 0.1), Color(red: 0.9, green: 0.3, blue: 0.0)]
        }
    }
    
    /// SF Symbol for subtle icon usage.
    var icon: SystemImage {
        switch self {
        case .bestFriend: .personTwo
        case .mom: .heart
        case .boss: .briefcase
        case .drill: .shield
        case .therapist: .brain
        case .grandma: .eyeglasses
        case .ex: .heart
        case .conspiracyTheorist: .shield
        case .passiveAggressiveColleague: .briefcase
        case .chef: .heart
        case .disappointedDad: .personTwo
        case .gymBro: .shield
        }
    }
    
    /// Font design that gives each persona typographic character.
    var fontDesign: Font.Design {
        .default
    }
    
    /// Font weight for the persona name display.
    var fontWeight: Font.Weight {
        .bold
    }
    
    // MARK: - Agent Profile Stats
    
    /// Total messages per mission (sum of all escalation counts).
    var totalMessages: Int {
        escalationProfile.counts.reduce(0, +)
    }
    
    /// Intensity label based on shortest interval.
    var intensityLabel: String {
        let minInterval = escalationProfile.intervals.min() ?? 60
        switch minInterval {
        case 0...5:   return "agent_intensity_extreme".localized
        case 6...10:  return "agent_intensity_intense".localized
        case 11...15: return "agent_intensity_high".localized
        case 16...30: return "agent_intensity_medium".localized
        default:      return "agent_intensity_chill".localized
        }
    }
    
    /// Short style tag describing the agent's approach.
    var styleTag: String {
        "agent_\(rawValue)_style_tag".localized
    }
    
    // MARK: - Escalation Profile
    
    /// Agent-specific notification intervals and counts per escalation level.
    /// Determines how aggressively each agent nags.
    var escalationProfile: EscalationProfile {
        switch self {
        case .bestFriend:
            // Chill — lässige Erinnerungen
            EscalationProfile(
                intervals: [180, 120, 90, 45, 20],
                counts:    [2,   2,   3,  3,  10]
            )
        case .mom:
            // Moderat — startet sanft, wird drängender
            EscalationProfile(
                intervals: [120, 90, 60, 30, 15],
                counts:    [2,   3,  3,  4,  10]
            )
        case .boss:
            // Mittel — corporate Rhythmus
            EscalationProfile(
                intervals: [150, 120, 60, 30, 15],
                counts:    [2,   2,   3,  4,  10]
            )
        case .drill:
            // Aggressiv — sofort Druck, erbarmungslos
            EscalationProfile(
                intervals: [60, 45, 30, 15, 10],
                counts:    [2,  2,  3,  4,  10]
            )
        case .therapist:
            // Selten — gibt dir Raum, fragt behutsam
            EscalationProfile(
                intervals: [240, 180, 120, 60, 30],
                counts:    [2,   2,   3,   3,  10]
            )
        case .grandma:
            EscalationProfile(
                intervals: [150, 120, 60, 30, 10],
                counts:    [2,   3,   3,  4,  10]
            )
        case .ex:
            // Passive-aggressive: starts slow, gets cutting
            EscalationProfile(
                intervals: [180, 120, 60, 30, 10],
                counts:    [2,   2,   3,  4,  10]
            )
        case .conspiracyTheorist:
            // Erratic — unpredictable intervals
            EscalationProfile(
                intervals: [90, 45, 120, 20, 10],
                counts:    [2,  3,  2,   4,  10]
            )
        case .passiveAggressiveColleague:
            // Steady, relentless passive pressure
            EscalationProfile(
                intervals: [120, 90, 60, 30, 15],
                counts:    [2,   3,  3,  4,  10]
            )
        case .chef:
            // Intense, immediate, no patience
            EscalationProfile(
                intervals: [45, 30, 20, 10, 5],
                counts:    [2,  3,  3,  4,  10]
            )
        case .disappointedDad:
            // Sparse — silence is the weapon
            EscalationProfile(
                intervals: [300, 240, 120, 60, 30],
                counts:    [1,   1,   2,   3,  5]
            )
        case .gymBro:
            // Maximum energy, maximum frequency
            EscalationProfile(
                intervals: [60, 45, 30, 15, 5],
                counts:    [2,  3,  3,  4,  10]
            )
        }
    }
}

// MARK: - Agent Tier

extension Agent {
    /// Whether this agent is a base (free) agent.
    var isBaseAgent: Bool { !isSpecialAgent }
    
    /// Special Agents have memory — they remember past missions.
    /// Unlocked with Pro.
    var isSpecialAgent: Bool {
        AgentPack.allAgents.contains(self)
    }
}
