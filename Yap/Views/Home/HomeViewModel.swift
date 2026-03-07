// HomeViewModel.swift
// Yap

import Foundation
import Combine
import SwiftUI

enum Appearance: String {
    case light
    case dark
    
    var scheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

final class HomeViewModel: ObservableObject {
    
    enum Phase: Equatable {
        case loading
        case selection
        case activeMission(Mission)
        case completed(Mission)  // Stats nach Erfolg
        case gaveUp(Mission)     // Stats nach Aufgeben
    }
    
    @Published var missionText: String = ""
    @Published var selectedAgent: Agent? = nil
    @Published var phase: Phase = .loading
    @Published var error: String? = nil
    @Published var showPaywall: Bool = false
    @Published var selectedMission: MissionItem?
    @Published var showGiveApAlert = false
    @Published var isFocused = false
    @Published var selectedDeadline: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
    @AppStorage("appearance") var appearance: Appearance = .light
    @AppStorage(QuietHours.startKey) var quietHoursStart: Int = QuietHours.defaultStart
    @AppStorage(QuietHours.endKey) var quietHoursEnd: Int = QuietHours.defaultEnd
    
    // Queue
    @Published var queuedMissions: [MissionItem] = []
    
    // Stats (Gesamtübersicht)
    @Published var stats: DeviceStats?
    @Published var missionHistory: [Mission] = []
    
    /// Agent performance stats calculated from history.
    var agentStats: [AgentStats] {
        missionHistory.agentStats()
    }
    
    /// Leaderboard sorted by success rate.
    var agentLeaderboard: [AgentStats] {
        missionHistory.agentLeaderboard()
    }
    
    /// Get stats for a specific agent.
    func stats(for agent: Agent) -> AgentStats {
        agentStats.first { $0.agent == agent } ?? AgentStats(agent: agent, completed: 0, givenUp: 0)
    }
    
    /// Get all finished missions for a specific agent.
    func missions(for agent: Agent) -> [Mission] {
        missionHistory.filter { $0.agent == agent }
    }
    
    /// How many missions were created today (for daily limit check).
    var missionsCreatedToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return missionHistory.filter { calendar.startOfDay(for: $0.createdAt) == today }.count
    }
    
    func orderAgentList() -> [Agent] {
        let indexByAgent = Dictionary(uniqueKeysWithValues: Agent.allCases.enumerated().map { ($1, $0) })

        return Agent.allCases.sorted { lhs, rhs in
            let lhsStats = stats(for: lhs)
            let rhsStats = stats(for: rhs)

            let lhsRate = lhsStats.successRate ?? -1
            let rhsRate = rhsStats.successRate ?? -1
            if lhsRate != rhsRate {
                return lhsRate > rhsRate
            }

            if lhsStats.total != rhsStats.total {
                return lhsStats.total > rhsStats.total
            }

            return (indexByAgent[lhs] ?? 0) < (indexByAgent[rhs] ?? 0)
        }
    }
    
    private let onboardingKey = "yap_onboarding_complete"
    
    // MARK: - UseCases
    
    private let fetchActiveMission: FetchActiveMissionUseCase
    private let fetchQueue: FetchQueueUseCase
    private let createMission: CreateMissionUseCase
    private let completeMission: CompleteMissionUseCase
    private let giveUpMission: GiveUpMissionUseCase
    private let removeFromQueue: RemoveFromQueueUseCase
    private let extendMission: ExtendMissionUseCase
    private let activateMission: ActivateMissionUseCase
    private let fetchStats: FetchStatsUseCase
    private let fetchMissionHistory: FetchMissionHistoryUseCase
    private let addToQueue: AddToQueueUseCase
    
    init(fetchActiveMission: FetchActiveMissionUseCase = .init(),
         fetchQueue: FetchQueueUseCase = .init(),
         createMission: CreateMissionUseCase = .init(),
         completeMission: CompleteMissionUseCase = .init(),
         giveUpMission: GiveUpMissionUseCase = .init(),
         removeFromQueue: RemoveFromQueueUseCase = .init(),
         extendMission: ExtendMissionUseCase = .init(),
         activateMission: ActivateMissionUseCase = .init(),
         fetchStats: FetchStatsUseCase = .init(),
         fetchMissionHistory: FetchMissionHistoryUseCase = .init(),
         addToQueue: AddToQueueUseCase = .init()) {
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
    }
    
    var canSubmitMission: Bool {
        !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Lifecycle
    
    @MainActor
    func onAppear() async {
        if let active = await fetchActiveMission.execute(()) {
            phase = .activeMission(active)
        } else {
            phase = .selection
        }
        
        // Queue im Hintergrund laden
        queuedMissions = await fetchQueue.execute(())
        
        // History für Agent Stats laden
        await refreshMissionHistory()
    }

    @MainActor
    private func refreshMissionHistory() async {
        missionHistory = await fetchMissionHistory.execute(())
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        phase = .selection
    }
    
    @MainActor
    func toggleAppearance() {
        if appearance == .light {
            appearance = .dark
        } else {
            appearance = .light
        }
    }
    
    // MARK: - Mission Flow
    @MainActor
    func selectAgent(_ agent: Agent, title: String) async {
        // Agent check: Only Mom is free
        if ProAccess.requiresPro(agent) && !ProAccess.isPro {
            showPaywall = true
            return
        }
        
        // Daily limit check: Free users get 1 mission/day
        if !ProAccess.canCreateMissionToday(missionsCreatedToday: missionsCreatedToday) {
            showPaywall = true
            return
        }
        
        try? await Task.sleep(for: .seconds(2))
        guard let mission = await createMission.execute(.init(
            title: title,
            agent: agent,
            deadline: selectedDeadline
        )) else {
            error = "Mission konnte nicht erstellt werden."
            phase = .selection
            await refreshMissionHistory()
            return
        }
        
        phase = .activeMission(mission)
        await refreshMissionHistory()
    }
    
    /// MissionItem zur Queue hinzufügen — nur Titel, kein Agent.
    @MainActor
    func addMissionToQueue(_ title: String) async {
        guard let item = await addToQueue.execute(title) else { return }
        queuedMissions.append(item)
    }
    
    /// MissionItem aus der Queue löschen.
    @MainActor
    func removeMissionFromQueue(_ item: MissionItem) async {
        await removeFromQueue.execute(item.id)
        queuedMissions.removeAll { $0.id == item.id }
    }
    
    // MARK: - Active Mission Actions
    
    /// Mission erledigt → Stats-Screen.
    @MainActor
    func markMissionDone(_ mission: Mission) async {
        guard let result = await completeMission.execute(mission.id) else { return }
        phase = .completed(result)
        await refreshMissionHistory()
    }
    
    /// Mission aufgeben → Loser-Stats-Screen.
    @MainActor
    func giveUp(_ mission: Mission) async {
        guard let result = await giveUpMission.execute(mission.id) else { return }
        phase = .gaveUp(result)
        await refreshMissionHistory()
    }
    
    /// 24h Verlängerung (nur 1× pro Mission, Pro-only).
    @MainActor
    func extend(_ mission: Mission) async {
        guard ProAccess.canExtend else {
            showPaywall = true
            return
        }
        guard !mission.extended else { return }
        guard let updated = await extendMission.execute(mission.id) else { return }
        phase = .activeMission(updated)
    }
    
    // MARK: - Post-Result Actions
    
    /// Nach Stats-Screen → nächste Mission aus Queue oder zurück zur Auswahl.
    @MainActor
    func continueAfterResult() {
        // Queue hat nur MissionItems — User muss erst Agent wählen.
        phase = .selection
    }
    
    // MARK: - Stats (Gesamtübersicht)
    @MainActor
    func loadStats() async {
        async let s = fetchStats.execute(())
        async let h = refreshMissionHistory()
        stats = await s
        await h
    }
    
    @MainActor
    func backToInput() {
        phase = .selection
    }
}


