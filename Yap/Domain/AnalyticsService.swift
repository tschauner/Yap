// AnalyticsService.swift
// Yap

import Foundation

/// Trackt Goal-Lifecycle-Events in der yap_goals-Tabelle auf Supabase
/// und leichtgewichtige Funnel-Events in yap_events.
/// Rein asynchron, fire-and-forget — Fehler werden geloggt, blockieren aber nichts.
final class AnalyticsService {
    
    static let shared = AnalyticsService()
    private let api = APIClient()
    private init() {}
    
    /// Uses the canonical Keychain-backed device ID (same as all other services).
    private var deviceId: String { APIClient.deviceId }
    
    /// Whether this process runs inside the iOS Simulator.
    static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Event Names
    
    enum Event: String {
        // App lifecycle
        case appOpened              = "app_opened"
        
        // Onboarding funnel
        case onboardingWelcome      = "onboarding_welcome"
        case onboardingAgents       = "onboarding_agents"
        case onboardingDeadline     = "onboarding_deadline"
        case onboardingName         = "onboarding_name"
        case onboardingNotifications = "onboarding_notifications"
        case onboardingPaywallShown = "onboarding_paywall_shown"
        case onboardingPaywallSkipped = "onboarding_paywall_skipped"
        case onboardingPaywallPurchased = "onboarding_paywall_purchased"
        case onboardingCompleted    = "onboarding_completed"
        
        // Mission lifecycle
        case missionCreated         = "mission_created"
        case missionCompleted       = "mission_completed"
        case missionGivenUp         = "mission_given_up"
    }
    
    // MARK: - Event Tracking (yap_events)
    
    /// Track a named event with optional metadata. Fire-and-forget.
    func track(_ event: Event, metadata: [String: Any]? = nil) {
        var body: [String: Any] = [
            "device_id": deviceId,
            "event": event.rawValue
        ]
        if let metadata, !metadata.isEmpty {
            body["metadata"] = metadata
        }
        fire("yap_events", method: "POST", body: body)
    }
    
    // MARK: - Track Goal Created
    
    func trackGoalCreated(_ mission: Mission, notificationsScheduled: Int, usedAICopy: Bool, isPro: Bool) {
        let body: [String: Any] = [
            "id": mission.id.uuidString,
            "device_id": deviceId,
            "title": mission.title,
            "agent": mission.agent.rawValue,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "notifications_scheduled": notificationsScheduled,
            "is_pro": isPro,
            "used_ai_copy": usedAICopy
        ]
        fire("yap_goals", method: "POST", body: body)
        
        // Also track as event for funnel
        track(.missionCreated, metadata: ["agent": mission.agent.rawValue])
    }
    
    // MARK: - Track Goal Completed
    
    func trackGoalCompleted(_ mission: Mission, escalationLevel: Int) {
        let minutesToComplete: Int? = mission.completedAt.map { completed in
            Int(completed.timeIntervalSince(mission.createdAt) / 60)
        }
        
        let body: [String: Any?] = [
            "completed_at": ISO8601DateFormatter().string(from: Date()),
            "escalation_level_at_completion": escalationLevel,
            "time_to_complete_minutes": minutesToComplete
        ]
        
        // PATCH via filter
        fire("yap_goals?id=eq.\(mission.id.uuidString)", method: "PATCH", body: body as [String: Any])
        
        track(.missionCompleted, metadata: ["agent": mission.agent.rawValue])
    }
    
    // MARK: - Track Goal Given Up
    
    func trackGoalGivenUp(_ goalId: UUID) {
        let body: [String: Any] = [
            "given_up_at": ISO8601DateFormatter().string(from: Date())
        ]
        fire("yap_goals?id=eq.\(goalId.uuidString)", method: "PATCH", body: body)
        
        track(.missionGivenUp)
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
