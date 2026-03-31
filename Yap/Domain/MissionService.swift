// MissionService.swift
// Yap

import Foundation

// MARK: - Protocol

protocol MissionProviding: Actor {
    // Queue (leichtgewichtig)
    func queue() async throws -> [MissionItem]
    func addToQueue(title: String) async throws -> MissionItem
    func removeFromQueue(_ id: UUID) async throws
    func reorderQueue(_ ids: [UUID]) async throws
    
    // Aktive Mission (volles Objekt)
    func activeMission() async throws -> Mission?
    func createMission(title: String, agent: Agent, deadline: Date) async throws -> Mission
    func activate(_ id: UUID, agent: Agent, deadline: Date) async throws -> Mission?
    func completeMission(_ id: UUID) async throws -> Mission?
    func giveUpMission(_ id: UUID) async throws -> Mission?
    func failMission(_ id: UUID) async throws -> Mission?
    func snoozeMission(_ id: UUID, minutes: Int) async throws
    func extendMission(_ id: UUID, hours: Int) async throws -> Mission?
    func updateNotificationsScheduled(_ id: UUID, count: Int) async throws
    
    // History + Stats
    func finishedMissions() async throws -> [Mission]
    func fetchStats() async throws -> DeviceStats
    func fetchGlobalLeaderboard() async throws -> [GlobalAgentStats]
}

/// Manages mission persistence via Supabase PostgREST.
actor MissionService: MissionProviding {
    
    static let shared = MissionService()
    
    private let api: APIClient
    private let deviceId: String
    private let table = "yap_goals"
    
    init(api: APIClient = APIClient(), deviceId: String = APIClient.deviceId) {
        self.api = api
        self.deviceId = deviceId
    }
    
    // MARK: - Queue (MissionItem)
    
    func queue() async throws -> [MissionItem] {
        try await api.rest(
            table: table,
            query: "device_id=eq.\(deviceId)&status=eq.queued&order=created_at.asc&select=id,title,created_at"
        )
    }
    
    func addToQueue(title: String) async throws -> MissionItem {
        let body: [String: Any] = [
            "device_id": deviceId,
            "title": title,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "status": MissionStatus.queued.rawValue
        ]
        
        let items: [MissionItem] = try await api.restInsert(table: table, body: .json(body))
        guard let item = items.first else { throw APIError.noData }
        return item
    }
    
    func removeFromQueue(_ id: UUID) async throws {
        try await api.restDelete(table: table, query: "id=eq.\(id.uuidString)")
    }
    
    func reorderQueue(_ ids: [UUID]) async throws {
        let _: String? = try await api.rpc(
            function: "reorder_queue",
            params: .json([
                "p_device_id": deviceId,
                "p_goal_ids": ids.map(\.uuidString)
            ])
        )
    }
    
    // MARK: - Active Mission
    
    func activeMission() async throws -> Mission? {
        let missions: [Mission] = try await api.rest(
            table: table,
            query: "device_id=eq.\(deviceId)&status=eq.active&limit=1"
        )
        return missions.first
    }
    
    /// Neue Mission direkt erstellen + aktivieren (ohne Queue).
    func createMission(title: String, agent: Agent, deadline: Date) async throws -> Mission {
        let body: [String: Any] = [
            "device_id": deviceId,
            "title": title,
            "agent": agent.rawValue,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "status": MissionStatus.active.rawValue,
            "deadline": ISO8601DateFormatter().string(from: deadline),
            "is_pro": ProAccess.isPro,
            "used_ai_copy": ProAccess.canUseAICopy
        ]
        
        let missions: [Mission] = try await api.restInsert(table: table, body: .json(body))
        guard let mission = missions.first else { throw APIError.noData }
        return mission
    }
    
    /// Queue-Item aktivieren → wird zur Mission mit Agent.
    func activate(_ id: UUID, agent: Agent, deadline: Date) async throws -> Mission? {
        let nextId: UUID? = try await api.rpc(
            function: "activate_next_goal",
            params: .json([
                "p_device_id": deviceId,
                "p_agent": agent.rawValue,
                "p_deadline": ISO8601DateFormatter().string(from: deadline)
            ])
        )
        guard let nextId else { return nil }
        
        let missions: [Mission] = try await api.rest(
            table: table,
            query: "id=eq.\(nextId.uuidString)"
        )
        return missions.first
    }
    
    // MARK: - Complete / Give Up
    
    func completeMission(_ id: UUID) async throws -> Mission? {
        let existing: [Mission] = try await api.rest(
            table: table,
            query: "id=eq.\(id.uuidString)"
        )
        guard let mission = existing.first else { return nil }
        
        let now = Date()
        let minutes = Int(now.timeIntervalSince(mission.createdAt) / 60)
        let escalation = mission.peakEscalation.rawValue
        
        let updated: [Mission] = try await api.restUpdate(
            table: table,
            query: "id=eq.\(id.uuidString)",
            body: .json([
                "status": "completed",
                "completed_at": ISO8601DateFormatter().string(from: now),
                "time_to_complete_minutes": minutes,
                "escalation_level_at_completion": escalation
            ])
        )
        return updated.first
    }
    
    func giveUpMission(_ id: UUID) async throws -> Mission? {
        let existing: [Mission] = try await api.rest(
            table: table,
            query: "id=eq.\(id.uuidString)"
        )
        guard let mission = existing.first else { return nil }
        
        let now = Date()
        let minutes = Int(now.timeIntervalSince(mission.createdAt) / 60)
        let escalation = mission.peakEscalation.rawValue
        
        let updated: [Mission] = try await api.restUpdate(
            table: table,
            query: "id=eq.\(id.uuidString)",
            body: .json([
                "status": "given_up",
                "given_up_at": ISO8601DateFormatter().string(from: now),
                "time_to_complete_minutes": minutes,
                "escalation_level_at_completion": escalation
            ])
        )
        return updated.first
    }

    func failMission(_ id: UUID) async throws -> Mission? {
        let existing: [Mission] = try await api.rest(
            table: table,
            query: "id=eq.\(id.uuidString)"
        )
        guard let mission = existing.first else { return nil }
        
        let minutes = Int(mission.deadline.timeIntervalSince(mission.createdAt) / 60)
        let escalation = mission.peakEscalation.rawValue
        
        let updated: [Mission] = try await api.restUpdate(
            table: table,
            query: "id=eq.\(id.uuidString)",
            body: .json([
                "status": "failed",
                "given_up_at": ISO8601DateFormatter().string(from: mission.deadline),
                "time_to_complete_minutes": minutes,
                "escalation_level_at_completion": escalation
            ])
        )
        return updated.first
    }

    func snoozeMission(_ id: UUID, minutes: Int) async throws {
        struct PendingNotification: Decodable {
            let id: UUID
            let scheduledAt: Date
        }

        let pending: [PendingNotification] = try await api.rest(
            table: "yap_notifications",
            query: "goal_id=eq.\(id.uuidString)&status=eq.pending&select=id,scheduled_at"
        )

        let now = Date()
        let snoozeEnd = now.addingTimeInterval(TimeInterval(minutes * 60))

        // Cancel only notifications scheduled within the next 30 min window
        for entry in pending where entry.scheduledAt > now && entry.scheduledAt <= snoozeEnd {
            try await api.restUpdate(
                table: "yap_notifications",
                query: "id=eq.\(entry.id.uuidString)",
                body: .json(["status": "cancelled", "error": "snoozed"])
            )
        }
    }
    
    // MARK: - Extend
    
    func extendMission(_ id: UUID, hours: Int) async throws -> Mission? {
        let newDeadline: Date
        if hours <= 12 {
            // Short extension: just add hours to now
            newDeadline = Date.now.addingTimeInterval(Double(hours) * 3600)
        } else {
            // Full-day extension: tomorrow 18:00 (avoids overnight pushes)
            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            newDeadline = cal.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }
        let updated: [Mission] = try await api.restUpdate(
            table: table,
            query: "id=eq.\(id.uuidString)",
            body: .json([
                "extended": true,
                "deadline": ISO8601DateFormatter().string(from: newDeadline)
            ])
        )
        return updated.first
    }
    
    // MARK: - Notifications
    
    func updateNotificationsScheduled(_ id: UUID, count: Int) async throws {
        try await api.restUpdate(
            table: table,
            query: "id=eq.\(id.uuidString)",
            body: .json(["notifications_scheduled": count])
        )
    }
    
    // MARK: - History
    
    func finishedMissions() async throws -> [Mission] {
        try await api.rest(
            table: table,
            query: "device_id=eq.\(deviceId)&status=in.(completed,given_up,failed)&order=created_at.desc"
        )
    }
    
    // MARK: - Stats
    
    func fetchStats() async throws -> DeviceStats {
        try await api.rpc(
            function: "get_device_stats",
            params: .json(["p_device_id": deviceId])
        )
    }
    
    func fetchGlobalLeaderboard() async throws -> [GlobalAgentStats] {
        try await api.rpc(
            function: "get_global_agent_leaderboard"
        )
    }
}

