// MissionUseCases.swift
// Yap

import Foundation
import UserNotifications

// MARK: - Queue

/// Queue laden → [MissionItem]
struct FetchQueueUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: Void) async -> [MissionItem] {
        (try? await service.queue()) ?? []
    }
}

/// MissionItem zur Queue hinzufügen (nur Titel).
struct AddToQueueUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: String) async -> MissionItem? {
        try? await service.addToQueue(title: input)
    }
}

/// MissionItem aus Queue löschen.
struct RemoveFromQueueUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: UUID) async {
        try? await service.removeFromQueue(input)
    }
}

/// Queue umsortieren.
struct ReorderQueueUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: [UUID]) async {
        try? await service.reorderQueue(input)
    }
}

// MARK: - Active Mission

/// Aktive Mission laden.
struct FetchActiveMissionUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: Void) async -> Mission? {
        try? await service.activeMission()
    }
}

/// Neue Mission erstellen (direkt aktiv, nicht aus Queue).
struct CreateMissionUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    struct Input {
        let title: String
        let agent: Agent
        let deadline: Date
    }
    
    func execute(_ input: Input) async -> Mission? {
        do {
            let mission = try await service.createMission(title: input.title, agent: input.agent, deadline: input.deadline)
            // Remote push notifications are scheduled server-side via generate-copy
            return mission
        } catch {
            print("⚠️ CreateMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

/// Queue-Item aktivieren → Agent wählen → wird zur Mission.
struct ActivateMissionUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    struct Input {
        let id: UUID
        let agent: Agent
        let deadline: Date
    }
    
    func execute(_ input: Input) async -> Mission? {
        do {
            guard let mission = try await service.activate(input.id, agent: input.agent, deadline: input.deadline) else { return nil }
            // Remote push notifications are scheduled server-side via generate-copy
            return mission
        } catch {
            print("⚠️ ActivateMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Complete / Give Up

/// Mission erledigt → Mission für Stats.
struct CompleteMissionUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: UUID) async -> Mission? {
        do {
            let mission = try await service.completeMission(input)
            // Cancel server-side remote push notifications
            await DeviceService.shared.cancelPendingNotifications(goalId: input)
            // Reset app badge
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
            return mission
        } catch {
            print("⚠️ CompleteMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

/// Mission aufgeben → Mission für Stats.
struct GiveUpMissionUseCase: UseCase {
    private let service: any MissionProviding
    private let copyService: any CopyProviding
    
    init(service: any MissionProviding = MissionService.shared,
         copyService: any CopyProviding = CopyService.shared) {
        self.service = service
        self.copyService = copyService
    }
    
    func execute(_ input: UUID) async -> Mission? {
        do {
            let mission = try await service.giveUpMission(input)
            copyService.deleteCopy(for: input)
            // Cancel server-side remote push notifications
            await DeviceService.shared.cancelPendingNotifications(goalId: input)
            // Reset app badge
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
            return mission
        } catch {
            print("⚠️ GiveUpMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Extend

struct ExtendMissionUseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ id: UUID, hours: Int) async -> Mission? {
        do {
            guard let updated = try await service.extendMission(id, hours: hours) else { return nil }
            // Cancel old server-side notifications — new ones will be scheduled via generate-copy
            await DeviceService.shared.cancelPendingNotifications(goalId: id)
            return updated
        } catch {
            print("⚠️ ExtendMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Stats

struct FetchStatsUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: Void) async -> DeviceStats? {
        try? await service.fetchStats()
    }
}

struct FetchMissionHistoryUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: Void) async -> [Mission] {
        let missions = (try? await service.finishedMissions()) ?? []
        return missions
    }
}

// MARK: - Reaction & Copy Generation

/// Agent-Reaction für eine Mission laden (aus dem generierten Copy-Cache).
struct LoadReactionUseCase {
    private let copyService: any CopyProviding
    
    init(copyService: any CopyProviding = CopyService.shared) {
        self.copyService = copyService
    }
    
    func execute(_ missionId: UUID) -> String? {
        copyService.loadReaction(for: missionId)
    }
}

/// Fast reaction call (~2s) — only generates the agent's spontaneous reaction.
struct GenerateReactionUseCase {
    private let copyService: any CopyProviding
    
    init(copyService: any CopyProviding = CopyService.shared) {
        self.copyService = copyService
    }
    
    func execute(_ mission: Mission) async -> String? {
        await copyService.generateReaction(for: mission)
    }
}

/// Full copy generation (messages + reaction) — runs in background after mission creation.
struct GenerateCopyUseCase {
    private let copyService: any CopyProviding
    
    init(copyService: any CopyProviding = CopyService.shared) {
        self.copyService = copyService
    }
    
    func execute(_ mission: Mission) async {
        _ = await copyService.generateCopy(for: mission)
    }
}

// MARK: - Global Leaderboard

/// Fetch aggregated stats across all users per agent.
struct FetchGlobalLeaderboardUseCase: UseCase {
    private let service: any MissionProviding
    
    init(service: any MissionProviding = MissionService.shared) {
        self.service = service
    }
    
    func execute(_ input: Void) async -> [GlobalAgentStats] {
        (try? await service.fetchGlobalLeaderboard()) ?? []
    }
}

