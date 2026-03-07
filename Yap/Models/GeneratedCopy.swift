// GeneratedCopy.swift
// Yap

import Foundation

/// Alle vorgenerierten Notification-Texte für eine Mission.
/// Wird einmalig per GPT generiert und lokal gespeichert.
struct GeneratedCopy: Codable, Equatable {
    let missionId: UUID
    let messages: [Message]
    let generatedAt: Date
    
    struct Message: Codable, Equatable {
        let title: String
        let body: String
        let level: Int  // EscalationLevel.rawValue
    }
}
