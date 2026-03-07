// Agent.swift
// Yap

import Foundation
import SwiftUI

/// The persona that sends escalating notifications.
enum Agent: String, Codable, CaseIterable, Identifiable {
    case bestFriend  // Casual, loving roasts
    case mom        // Guilt trips from caring to devastation
    case boss        // Corporate passive-aggression
    case drill       // Military drill sergeant
    case therapist   // Starts validating, gets uncomfortably honest
    case grandma         // Emotional warfare from grandma
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bestFriend: "Best Friend"
        case .mom: "Mom"
        case .boss: "Boss"
        case .drill: "Drill Sergeant"
        case .therapist: "Therapist"
        case .grandma: "Grandma"
        }
    }
    
    var image: String {
        switch self {
        case .bestFriend:
            return "golden"
        case .mom:
            return "dachs"
        case .boss:
            return "shepard"
        case .drill:
            return "dobermann"
        case .therapist:
            return "pudel"
        case .grandma:
            return "terrier"
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
        }
    }
    
    var description: String {
        switch self {
        case .bestFriend: "Roasts you because they love you"
        case .mom: "Guilt trips that escalate to emotional devastation"
        case .boss: "Corporate passive-aggression in notification form"
        case .drill: "Full R. Lee Ermey mode. No mercy."
        case .therapist: "Validates you, then asks the hard questions"
        case .grandma: "\"I'm not mad, just disappointed\" on steroids"
        }
    }
    
    /// One-liner roast when the user gives up. Used in the Loser screen.
    var giveUpRoast: String {
        switch self {
        case .bestFriend: "Bro... I believed in you. I literally told the group chat."
        case .mom: "I'm not angry. I'm just... no, I am angry."
        case .boss: "This will be reflected in your performance review."
        case .drill: "DISHONORABLE. DISCHARGE. GET OUT OF MY SIGHT."
        case .therapist: "Let's unpack why you keep abandoning things."
        case .grandma: "It's fine. I'll just sit here. Alone. Like always."
        }
    }
    
    /// The agent's pitch — what they'd say to get hired.
    var pitch: String {
        switch self {
        case .bestFriend: "I'll hype you up and roast you until it's done."
        case .mom: "You'll finish it. Because I raised you better than this."
        case .boss: "Deadlines exist. I enforce them. Simple."
        case .drill: "I will break you. And then you will be unstoppable."
        case .therapist: "We'll find the root cause. And then we'll fix it."
        case .grandma: "I've got all day. And I know where you live."
        }
    }
    
    /// Alert message when the user taps "Give up" — asking for confirmation.
    var giveUpConfirmation: String {
        switch self {
        case .bestFriend: "Wait, you're actually quitting? After all that hype I gave you?"
        case .mom: "You want to give up? After everything I've done for you?"
        case .boss: "Walking away from your responsibilities? That's a bold career move."
        case .drill: "SURRENDER?! Is that what they taught you? IS IT?!"
        case .therapist: "Are you sure this is what you want, or are you just avoiding discomfort?"
        case .grandma: "Giving up already? I survived a war, you know."
        }
    }
    
    var alert: String {
        "\(displayName): \(giveUpConfirmation)"
    }
    
    /// Congratulations message when the user completes a mission.
    var completionMessage: String {
        switch self {
        case .bestFriend: "LET'S GOOO! I knew you had it in you!"
        case .mom: "See? I always believed in you. Now call me more often."
        case .boss: "Excellent work. Consider this noted for your next review."
        case .drill: "OUTSTANDING, SOLDIER! You've earned my respect today."
        case .therapist: "You did it. How does it feel to honor your commitment?"
        case .grandma: "I'm so proud of you! Now come over, I made cookies."
        }
    }
    
    /// Sales pitch for the paywall — agents justify the price.
    var salesPitch: String {
        switch self {
        case .bestFriend: "Bro, that's less than ONE coffee. And I'll be there for you EVERY day. Unlike your ex."
        case .mom: "I gave birth to guilt-trips for FREE. This is a bargain."
        case .boss: "Consider this an investment in your career. Tax deductible, probably."
        case .drill: "THE COST OF WEAKNESS IS FAR GREATER, MAGGOT! PAY UP!"
        case .therapist: "Think of it as self-care. You're worth it. Aren't you?"
        case .grandma: "In my day, motivation cost NOTHING. But fine, I'll take it."
        }
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
        case .grandma: Color(red: 0.85, green: 0.55, blue: 0.45) // warm rose
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
            // Mittel — startet subtle, wird giftiger
            EscalationProfile(
                intervals: [150, 120, 60, 30, 10],
                counts:    [2,   3,   3,  4,  10]
            )
        }
    }
}
