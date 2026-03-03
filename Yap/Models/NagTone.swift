// NagTone.swift
// Yap

import Foundation

/// The persona that sends escalating notifications.
enum NagTone: String, Codable, CaseIterable, Identifiable {
    case bestFriend  // Casual, loving roasts
    case mama        // Guilt trips from caring to devastation
    case boss        // Corporate passive-aggression
    case drill       // Military drill sergeant
    case therapist   // Starts validating, gets uncomfortably honest
    case oma         // Emotional warfare from grandma
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bestFriend: "Best Friend"
        case .mama: "Mama"
        case .boss: "Boss"
        case .drill: "Drill Sergeant"
        case .therapist: "Therapist"
        case .oma: "Oma"
        }
    }
    
    var emoji: String {
        switch self {
        case .bestFriend: "🫶"
        case .mama: "👩‍🍳"
        case .boss: "👔"
        case .drill: "🫡"
        case .therapist: "🧘"
        case .oma: "👵"
        }
    }
    
    var description: String {
        switch self {
        case .bestFriend: "Roasts you because they love you"
        case .mama: "Guilt trips that escalate to emotional devastation"
        case .boss: "Corporate passive-aggression in notification form"
        case .drill: "Full R. Lee Ermey mode. No mercy."
        case .therapist: "Validates you, then asks the hard questions"
        case .oma: "\"I'm not mad, just disappointed\" on steroids"
        }
    }
    
    /// One-liner roast when the user gives up. Used in the Loser screen.
    var giveUpRoast: String {
        switch self {
        case .bestFriend: "Bro... I believed in you. I literally told the group chat."
        case .mama: "I'm not angry. I'm just... no, I am angry."
        case .boss: "This will be reflected in your performance review."
        case .drill: "DISHONORABLE. DISCHARGE. GET OUT OF MY SIGHT."
        case .therapist: "Let's unpack why you keep abandoning things."
        case .oma: "It's fine. I'll just sit here. Alone. Like always."
        }
    }
}
