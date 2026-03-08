// MissionUseCases.swift
// Yap

import Foundation

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
    private let nagService: any NagProviding
    
    init(service: any MissionProviding = MissionService.shared,
         nagService: any NagProviding = NagService.shared) {
        self.service = service
        self.nagService = nagService
    }
    
    struct Input {
        let title: String
        let agent: Agent
        let deadline: Date
    }
    
    func execute(_ input: Input) async -> Mission? {
        do {
            var mission = try await service.createMission(title: input.title, agent: input.agent, deadline: input.deadline)
            
            let scheduled = await nagService.scheduleEscalation(for: mission, startDelay: 0)
            try? await service.updateNotificationsScheduled(mission.id, count: scheduled)
            mission.notificationsScheduled = scheduled
            
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
    private let nagService: any NagProviding
    
    init(service: any MissionProviding = MissionService.shared,
         nagService: any NagProviding = NagService.shared) {
        self.service = service
        self.nagService = nagService
    }
    
    struct Input {
        let id: UUID
        let agent: Agent
        let deadline: Date
    }
    
    func execute(_ input: Input) async -> Mission? {
        do {
            guard var mission = try await service.activate(input.id, agent: input.agent, deadline: input.deadline) else { return nil }
            
            let scheduled = await nagService.scheduleEscalation(for: mission, startDelay: 0)
            try? await service.updateNotificationsScheduled(mission.id, count: scheduled)
            mission.notificationsScheduled = scheduled
            
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
    private let nagService: any NagProviding
    
    init(service: any MissionProviding = MissionService.shared,
         nagService: any NagProviding = NagService.shared) {
        self.service = service
        self.nagService = nagService
    }
    
    func execute(_ input: UUID) async -> Mission? {
        do {
            let mission = try await service.completeMission(input)
            await nagService.missionCompleted(input)
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
    private let nagService: any NagProviding
    private let copyService: any CopyProviding
    
    init(service: any MissionProviding = MissionService.shared,
         nagService: any NagProviding = NagService.shared,
         copyService: any CopyProviding = CopyService.shared) {
        self.service = service
        self.nagService = nagService
        self.copyService = copyService
    }
    
    func execute(_ input: UUID) async -> Mission? {
        do {
            let mission = try await service.giveUpMission(input)
            await nagService.cancelNotifications(for: input)
            copyService.deleteCopy(for: input)
            return mission
        } catch {
            print("⚠️ GiveUpMission failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Extend

struct ExtendMissionUseCase: UseCase {
    private let service: any MissionProviding
    private let nagService: any NagProviding
    
    init(service: any MissionProviding = MissionService.shared,
         nagService: any NagProviding = NagService.shared) {
        self.service = service
        self.nagService = nagService
    }
    
    func execute(_ input: UUID) async -> Mission? {
        do {
            guard let updated = try await service.extendMission(input) else { return nil }
            await nagService.cancelNotifications(for: input)
            await nagService.scheduleEscalation(for: updated, startDelay: 0)
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

