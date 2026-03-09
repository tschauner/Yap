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
    @Published var agentReaction: String? = nil
    @Published var missionReady = false
    @Published var pickerState: PickerState = .selection
    @Published var showAgents = true
    @Published var selectedDeadline: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
    @AppStorage("appearance") var appearance: Appearance = .light
    @AppStorage(QuietHours.startKey) var quietHoursStart: Int = QuietHours.defaultStart
    @AppStorage(QuietHours.endKey) var quietHoursEnd: Int = QuietHours.defaultEnd
    @AppStorage("favorite_agent") var favoriteAgentRaw: String = ""
    
    var favoriteAgent: Agent? {
        get { Agent(rawValue: favoriteAgentRaw) }
        set { favoriteAgentRaw = newValue?.rawValue ?? "" }
    }
    
    func toggleFavorite(_ agent: Agent) {
        if favoriteAgent == agent {
            favoriteAgent = nil
        } else {
            favoriteAgent = agent
        }
    }
    
    // Queue
    @Published var queuedMissions: [MissionItem] = []
    
    // Stats (Gesamtübersicht)
    @Published var stats: DeviceStats?
    @Published var missionHistory: [Mission] = []
    @Published var globalLeaderboard: [GlobalAgentStats] = []
    
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
        let fav = favoriteAgent

        return Agent.allCases.sorted { lhs, rhs in
            // Favorite always first
            if lhs == fav && rhs != fav { return true }
            if rhs == fav && lhs != fav { return false }
            
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
    
    private let useCases: MissionUseCaseFacade
    
    init(useCases: MissionUseCaseFacade = .init()) {
        self.useCases = useCases
    }
    
    var canSubmitMission: Bool {
        !missionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Lifecycle
    
    @MainActor
    func onAppear() async {
        if let active = await useCases.fetchActiveMission.execute(()) {
            missionReady = true
            phase = .activeMission(active)
        } else {
            phase = .selection
        }
        
        // Queue im Hintergrund laden
        queuedMissions = await useCases.fetchQueue.execute(())
        
        // History für Agent Stats laden
        await refreshMissionHistory()
    }

    @MainActor
    private func refreshMissionHistory() async {
        missionHistory = await useCases.fetchMissionHistory.execute(())
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
        
        // Step 1: Create mission (fast DB call, ~1s)
        guard let mission = await useCases.createMission.execute(.init(
            title: title,
            agent: agent,
            deadline: selectedDeadline
        )) else {
            error = "Mission konnte nicht erstellt werden."
            return
        }
        
        // Step 2: Show ActiveMissionView in loading state
        missionReady = false
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .activeMission(mission)
        }
        
        // Step 3: Short delay for the loading feel, then reveal stats
        try? await Task.sleep(for: .seconds(2))
        withAnimation(.easeInOut(duration: 0.4)) {
            missionReady = true
        }
        
        await refreshMissionHistory()
        
        // Fire-and-forget: Generate reaction + full notification copy in background
        if ProAccess.canUseAICopy {
            Task {
                let reaction = await useCases.generateReaction.execute(mission)
                await MainActor.run { agentReaction = reaction }
                await useCases.generateCopy.execute(mission)
            }
        }
    }
    
    /// MissionItem zur Queue hinzufügen — nur Titel, kein Agent.
    @MainActor
    func addMissionToQueue(_ title: String) async {
        guard let item = await useCases.addToQueue.execute(title) else { return }
        queuedMissions.append(item)
    }
    
    /// MissionItem aus der Queue löschen.
    @MainActor
    func removeMissionFromQueue(_ item: MissionItem) async {
        await useCases.removeFromQueue.execute(item.id)
        queuedMissions.removeAll { $0.id == item.id }
    }
    
    // MARK: - Active Mission Actions
    
    /// Mission erledigt → Stats-Screen.
    @MainActor
    func markMissionDone(_ mission: Mission) async {
        guard let result = await useCases.completeMission.execute(mission.id) else { return }
        phase = .completed(result)
        await refreshMissionHistory()
    }
    
    /// Mission aufgeben → Loser-Stats-Screen.
    @MainActor
    func giveUp(_ mission: Mission) async {
        guard let result = await useCases.giveUpMission.execute(mission.id) else { return }
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
        guard let updated = await useCases.extendMission.execute(mission.id) else { return }
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
        async let fetch = useCases.fetchStats.execute(())
        async let refresh: () = refreshMissionHistory()
        stats = await fetch
        await refresh
    }
    
    @MainActor
    func loadGlobalLeaderboard() async {
        globalLeaderboard = await useCases.fetchGlobalLeaderboard.execute(())
    }
    
    @MainActor
    func backToInput() {
        phase = .selection
    }
}


