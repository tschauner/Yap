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
    case gordonRamsay    // RAW. UNACCEPTABLE. FINISH IT.
    case disappointedDad // Says nothing. You feel everything.
    case gymBro          // BRO. LETS GET IT. NO DAYS OFF.
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bestFriend: "Best Friend"
        case .mom: "Mom"
        case .boss: "Boss"
        case .drill: "Drill Sergeant"
        case .therapist: "Therapist"
        case .grandma: "Grandma"
        case .ex: "The Ex"
        case .conspiracyTheorist: "The Theorist"
        case .passiveAggressiveColleague: "The Colleague"
        case .gordonRamsay: "Gordon Ramsay"
        case .disappointedDad: "Disappointed Dad"
        case .gymBro: "Gym Bro"
        }
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
        case .gordonRamsay: "🔥"
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
        case .gordonRamsay: return "dobermann"
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
        case .passiveAggressiveColleague: "😊"
        case .gordonRamsay: "👨‍🍳"
        case .disappointedDad: "🤦"
        case .gymBro: "💪"
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
        case .ex: "Passive-aggressive. Hurtful. Somehow effective."
        case .conspiracyTheorist: "They don't want you to finish. That's why you must."
        case .passiveAggressiveColleague: "\"No no, it's fine. I'll cover for you. Again.\""
        case .gordonRamsay: "This task is RAW. Finish it or get out."
        case .disappointedDad: "He says nothing. That's somehow worse."
        case .gymBro: "NO DAYS OFF. NO EXCUSES. BRO."
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
        case .ex: "Typical. I don't know why I expected anything different."
        case .conspiracyTheorist: "That's exactly what they wanted. You played right into it."
        case .passiveAggressiveColleague: "No worries. I've already finished it for you. Like always."
        case .gordonRamsay: "Pathetic. Get out of my kitchen."
        case .disappointedDad: "..."
        case .gymBro: "BRO. I can't even look at you right now."
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
        case .ex: "I just think it's interesting you couldn't do this when we were together."
        case .conspiracyTheorist: "The system doesn't want you to succeed. I do."
        case .passiveAggressiveColleague: "I'll just... wait. No, go ahead. I'll handle it."
        case .gordonRamsay: "I've seen better effort from a frozen pizza."
        case .disappointedDad: "I'm not mad. I'm just... I'm going to the garage."
        case .gymBro: "Every rep. Every task. Every day. LET'S GET IT."
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
        case .ex: "Of course you're giving up. Some things never change."
        case .conspiracyTheorist: "Quitting? That's what they want you to do. Wake up."
        case .passiveAggressiveColleague: "Oh, giving up? No no, it's fine. I'll just... do it myself."
        case .gordonRamsay: "You call this a quit?! GET BACK IN THERE!"
        case .disappointedDad: "...Do what you want."
        case .gymBro: "BRO. You're seriously gonna tap out?! SERIOUSLY?!"
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
        case .ex: "I mean... good. I guess you can do things without me after all."
        case .conspiracyTheorist: "They didn't think you could do it. You proved them wrong. All of them."
        case .passiveAggressiveColleague: "Oh wow, you finished. I'd already started covering for you, but... great."
        case .gordonRamsay: "FINALLY. That's what I'm talking about. Beautiful."
        case .disappointedDad: "Good job, son." // Two words. Maximum emotional impact.
        case .gymBro: "YOOO LETS GOOOO BRO! THAT'S WHAT I'M TALKING ABOUT!"
        }
    }
    
    /// Sales pitch for the paywall — agents justify the price.
    var salesPitch: String {
        switch self {
        case .bestFriend: return "Bro, that's less than ONE coffee. And I'll be there for you EVERY day. Unlike your ex."
        case .mom: return "I gave birth to guilt-trips for FREE. This is a bargain."
        case .boss: return "Consider this an investment in your career. Tax deductible, probably."
        case .drill: return "THE COST OF WEAKNESS IS FAR GREATER, MAGGOT! PAY UP!"
        case .therapist: return "Think of it as self-care. You're worth it. Aren't you?"
        case .grandma: return "In my day, motivation cost NOTHING. But fine, I'll take it."
        // Pack agents don't appear in the standard paywall
        case .ex, .conspiracyTheorist, .passiveAggressiveColleague,
             .gordonRamsay, .disappointedDad, .gymBro:
            return ""
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
        case .grandma: Color(red: 0.85, green: 0.55, blue: 0.45)
        case .ex: Color(red: 0.8, green: 0.2, blue: 0.4)
        case .conspiracyTheorist: Color(red: 0.2, green: 0.7, blue: 0.4)
        case .passiveAggressiveColleague: Color(.systemGray2)
        case .gordonRamsay: Color(red: 0.85, green: 0.15, blue: 0.15)
        case .disappointedDad: Color(red: 0.5, green: 0.38, blue: 0.25)
        case .gymBro: .orange
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
        case .gordonRamsay: .heart
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
        case .gordonRamsay:
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

// MARK: - Pack Membership

extension Agent {
    /// Which pack this agent belongs to. nil = base agent (Free or Pro).
    var pack: AgentPack? {
        switch self {
        case .ex, .conspiracyTheorist, .passiveAggressiveColleague: return .chaos
        case .gordonRamsay, .disappointedDad, .gymBro: return .legends
        default: return nil
        }
    }
    
    /// Base agents are part of Free or Pro tier, not a pack.
    var isBaseAgent: Bool { pack == nil }
}
