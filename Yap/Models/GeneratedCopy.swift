// GeneratedCopy.swift
// Yap

import Foundation

/// Alle vorgenerierten Notification-Texte für eine Mission.
/// Wird einmalig per GPT generiert und lokal gespeichert.
struct GeneratedCopy: Codable, Equatable {
    let missionId: UUID
    let messages: [Message]
    let reaction: String  // Agent's spontaneous first reaction to the goal
    let generatedAt: Date
    
    struct Message: Codable, Equatable {
        let title: String
        let body: String
        let level: Int  // EscalationLevel.rawValue
    }
}
