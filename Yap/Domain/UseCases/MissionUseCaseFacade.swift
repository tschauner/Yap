// MissionUseCaseFacade.swift
// Yap

import Foundation

/// Bündelt alle Mission-bezogenen UseCases in einer einzigen Dependency.
/// Hält das ViewModel-Init sauber.
struct MissionUseCaseFacade {
    let fetchActiveMission: FetchActiveMissionUseCase
    let fetchQueue: FetchQueueUseCase
    let createMission: CreateMissionUseCase
    let completeMission: CompleteMissionUseCase
    let giveUpMission: GiveUpMissionUseCase
    let removeFromQueue: RemoveFromQueueUseCase
    let extendMission: ExtendMissionUseCase
    let activateMission: ActivateMissionUseCase
    let fetchStats: FetchStatsUseCase
    let fetchMissionHistory: FetchMissionHistoryUseCase
    let addToQueue: AddToQueueUseCase
    let loadReaction: LoadReactionUseCase
    let generateReaction: GenerateReactionUseCase
    let generateCopy: GenerateCopyUseCase
    let fetchGlobalLeaderboard: FetchGlobalLeaderboardUseCase
    
    init(
        fetchActiveMission: FetchActiveMissionUseCase = .init(),
        fetchQueue: FetchQueueUseCase = .init(),
        createMission: CreateMissionUseCase = .init(),
        completeMission: CompleteMissionUseCase = .init(),
        giveUpMission: GiveUpMissionUseCase = .init(),
        removeFromQueue: RemoveFromQueueUseCase = .init(),
        extendMission: ExtendMissionUseCase = .init(),
        activateMission: ActivateMissionUseCase = .init(),
        fetchStats: FetchStatsUseCase = .init(),
        fetchMissionHistory: FetchMissionHistoryUseCase = .init(),
        addToQueue: AddToQueueUseCase = .init(),
        loadReaction: LoadReactionUseCase = .init(),
        generateReaction: GenerateReactionUseCase = .init(),
        generateCopy: GenerateCopyUseCase = .init(),
        fetchGlobalLeaderboard: FetchGlobalLeaderboardUseCase = .init()
    ) {
        self.fetchActiveMission = fetchActiveMission
        self.fetchQueue = fetchQueue
        self.createMission = createMission
        self.completeMission = completeMission
        self.giveUpMission = giveUpMission
        self.removeFromQueue = removeFromQueue
        self.extendMission = extendMission
        self.activateMission = activateMission
        self.fetchStats = fetchStats
        self.fetchMissionHistory = fetchMissionHistory
        self.addToQueue = addToQueue
        self.loadReaction = loadReaction
        self.generateReaction = generateReaction
        self.generateCopy = generateCopy
        self.fetchGlobalLeaderboard = fetchGlobalLeaderboard
    }
}
