// AnalyticsService.swift
// Yap

import Foundation
import UIKit

/// Trackt Goal-Lifecycle-Events in der yap_goals-Tabelle auf Supabase.
/// Rein asynchron, fire-and-forget — Fehler werden geloggt, blockieren aber nichts.
actor AnalyticsService {
    
    static let shared = AnalyticsService()
    private init() {}
    
    private var deviceId: String {
        // Persistent Device ID (bleibt auch nach App-Reinstall gleich, solange Keychain existiert)
        if let existing = UserDefaults.standard.string(forKey: "yap_device_id") {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "yap_device_id")
        return new
    }
    
    // MARK: - Track Goal Created
    
    func trackGoalCreated(_ goal: Goal, notificationsScheduled: Int, usedAICopy: Bool, isPro: Bool) {
        let body: [String: Any] = [
            "id": goal.id.uuidString,
            "device_id": deviceId,
            "title": goal.title,
            "tone": goal.tone.rawValue,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "notifications_scheduled": notificationsScheduled,
            "is_pro": isPro,
            "used_ai_copy": usedAICopy
        ]
        fire("yap_goals", method: "POST", body: body)
    }
    
    // MARK: - Track Goal Completed
    
    func trackGoalCompleted(_ goal: Goal, escalationLevel: Int) {
        let minutesToComplete: Int? = goal.completedAt.map { completed in
            Int(completed.timeIntervalSince(goal.createdAt) / 60)
        }
        
        let body: [String: Any?] = [
            "completed_at": ISO8601DateFormatter().string(from: Date()),
            "escalation_level_at_completion": escalationLevel,
            "time_to_complete_minutes": minutesToComplete
        ]
        
        // PATCH via filter
        fire("yap_goals?id=eq.\(goal.id.uuidString)", method: "PATCH", body: body as [String: Any])
    }
    
    // MARK: - Track Goal Given Up
    
    func trackGoalGivenUp(_ goalId: UUID) {
        let body: [String: Any] = [
            "given_up_at": ISO8601DateFormatter().string(from: Date())
        ]
        fire("yap_goals?id=eq.\(goalId.uuidString)", method: "PATCH", body: body)
    }
    
    // MARK: - Fire & Forget
    
    private func fire(_ path: String, method: String, body: [String: Any]) {
        Task {
            do {
                let url = URL(string: "\(Config.supabaseURL)/rest/v1/\(path)")!
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                request.timeoutInterval = 10
                
                let (_, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                if !(200...299).contains(status) {
                    print("⚠️ Analytics \(method) \(path) failed: HTTP \(status)")
                }
            } catch {
                print("⚠️ Analytics error: \(error.localizedDescription)")
            }
        }
    }
}
