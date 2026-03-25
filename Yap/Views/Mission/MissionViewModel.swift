// MissionViewModel.swift
// Yap

import Foundation
import Combine
import UserNotifications
import StoreKit
import SwiftUI

final class MissionViewModel: ObservableObject {
    
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
    @Published var showExtendAlert = false
    @Published var isFocused = false
    @Published var agentReaction: String? = nil
    @Published var missionReady = false
    @Published var currentNagMessage: String? = nil
    
    private var pushObserver: AnyCancellable?
    @Published var pickerState: PickerState = .selection
    @Published var showAgents = true
    @Published var showAllAgents = false
    @Published var missionIsCompleting = false
    @Published var selectedDeadline: Date = .nextSixPM
    @AppStorage("favorite_agent") var favoriteAgentRaw: String = ""
    @AppStorage("dismissedAgents") var dismissedAgentsRaw: String = ""
    
    private let appId = "6738916276"
    
    var appURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appId)")
    }
    
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
    
    
    // MARK: - Dismissed Agents (Roster)
    
    var dismissedAgents: Set<String> {
        get {
            guard !dismissedAgentsRaw.isEmpty else { return [] }
            return Set(dismissedAgentsRaw.components(separatedBy: ","))
        }
        set {
            dismissedAgentsRaw = newValue.sorted().joined(separator: ",")
        }
    }
    
    func isDismissed(_ agent: Agent) -> Bool {
        dismissedAgents.contains(agent.rawValue)
    }
    
    func dismissAgent(_ agent: Agent) {
        var set = dismissedAgents
        set.insert(agent.rawValue)
        dismissedAgents = set
        if favoriteAgent == agent { favoriteAgent = nil }
        if selectedAgent == agent { selectedAgent = nil }
    }
    
    func deployAgent(_ agent: Agent) {
        var set = dismissedAgents
        set.remove(agent.rawValue)
        dismissedAgents = set
    }
    
    func orderAgentList() -> [Agent] {
        let indexByAgent = Dictionary(uniqueKeysWithValues: Agent.allCases.enumerated().map { ($1, $0) })
        let fav = favoriteAgent
        let dismissed = dismissedAgents
        
        // Unlocked + not dismissed
        let available = Agent.allCases.filter { agent in
            guard !dismissed.contains(agent.rawValue) else { return false }
            return ProAccess.isAgentUnlocked(agent)
        }

        return available.sorted { lhs, rhs in
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
        if let active = await useCases.fetchActiveMission.execute(()), 
           !active.isFailed {
            // Only show as active if not failed (expired or given up)
            missionReady = true
            phase = .activeMission(active)
            // Restore cached reaction so the quote doesn't reset to pitch
            if agentReaction == nil {
                agentReaction = useCases.loadReaction.execute(active.id)
            }
            // Load locally saved push body (only shows messages that actually arrived)
            loadSavedPushBody(for: active.id)
            observePushArrivals(for: active.id)
        } else {
            phase = .selection
            // Reset badge when no active mission (expired/failed)
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
        
        // History für Agent Stats laden
        await refreshMissionHistory()
    }

    @MainActor
    private func refreshMissionHistory() async {
        #if DEBUG
        if MockData.isEnabled {
            missionHistory = MockData.missionHistory
            return
        }
        #endif
        missionHistory = await useCases.fetchMissionHistory.execute(())
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        phase = .selection
    }
    
    // MARK: - Mission Flow
    @MainActor
    func selectAgent(_ agent: Agent, title: String) async {
        // Daily limit check: Free users get 1 mission/day
        
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
            showAgents = true
            phase = .activeMission(mission)
        }
        
        // Step 2b: Fire reaction immediately (fast ~2s call) — shown during loading screen
        Task { [weak self] in
            if let reaction = await self?.useCases.generateReaction.execute(mission) {
                await MainActor.run {
                    self?.agentReaction = reaction
                }
            }
        }
        
        // Step 3: Short delay for the loading feel, then reveal stats
        try? await Task.sleep(for: .seconds(3))
        withAnimation(.easeInOut(duration: 0.4)) {
            missionReady = true
        }
        
        await refreshMissionHistory()
        
        // Fire-and-forget: Generate full notification copy in background
        // First push is scheduled at +5 min (see CopyService.requestBody)
        if ProAccess.canUseAICopy {
            Task { [weak self] in
                await self?.useCases.generateCopy.execute(mission)
                // Refresh mission so notificationsScheduled is updated in UI
                if let updated = await self?.useCases.fetchActiveMission.execute(()),
                   !updated.isFailed {
                    await MainActor.run {
                        self?.phase = .activeMission(updated)
                        self?.missionReady = true
                    }
                    // Push body will arrive via foreground observer — no DB fetch needed
                }
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
        defer { missionIsCompleting = false }
        missionIsCompleting = true
        guard let result = await useCases.completeMission.execute(mission.id) else { return }
        phase = .completed(result)
        await refreshMissionHistory()
        requestReviewIfEligible()
    }
    
    /// Mission aufgeben → Loser-Stats-Screen.
    @MainActor
    func giveUp(_ mission: Mission) async {
        guard let result = await useCases.giveUpMission.execute(mission.id) else { return }
        phase = .gaveUp(result)
        await refreshMissionHistory()
    }
    
    /// Extension (nur 1× pro Mission, Pro-only). +2h or +24h.
    @MainActor
    func extend(_ mission: Mission, hours: Int) async {
        guard ProAccess.canExtend else {
            showPaywall = true
            return
        }
        guard !mission.extended else { return }
        guard let updated = await useCases.extendMission.execute(mission.id, hours: hours) else { return }
        phase = .activeMission(updated)
        
        // Delete old cached copy and generate fresh notifications for the extension
        CopyService.shared.deleteCopy(for: updated.id)
        
        Task { [weak self] in
            await self?.useCases.generateCopy.execute(updated)
            if let refreshed = await self?.useCases.fetchActiveMission.execute(()),
               !refreshed.isFailed {
                await MainActor.run {
                    self?.phase = .activeMission(refreshed)
                }
            }
        }
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
        #if DEBUG
        if MockData.isEnabled {
            globalLeaderboard = MockData.globalLeaderboard
            return
        }
        #endif
        globalLeaderboard = await useCases.fetchGlobalLeaderboard.execute(())
    }
    
    // MARK: - Nag Message
    
    /// Load the last push body that was saved locally when a notification arrived.
    @MainActor
    func loadSavedPushBody(for missionId: UUID) {
        let key = "lastPushBody_\(missionId.uuidString)"
        currentNagMessage = UserDefaults.standard.string(forKey: key)
    }
    
    /// Observe foreground push arrivals so the UI updates immediately.
    private func observePushArrivals(for missionId: UUID) {
        pushObserver?.cancel()
        pushObserver = NotificationCenter.default
            .publisher(for: .yapPushReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let goalId = notification.userInfo?["goalId"] as? String,
                      goalId == missionId.uuidString,
                      let body = notification.userInfo?["body"] as? String else { return }
                self?.currentNagMessage = body
            }
    }
    
    @MainActor
    func backToInput() {
        missionText = ""
        selectedAgent = nil
        phase = .selection
    }
    
    // MARK: - App Store Rating
    
    @AppStorage("completedMissionCount") private var completedMissionCount = 0
    
    private func requestReviewIfEligible() {
        completedMissionCount += 1
        // Ask after 1st and 5th completed mission
        guard completedMissionCount == 1 || completedMissionCount == 5 else { return }
        // Small delay so the completion animation plays first
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let scene = UIApplication.shared
                .connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            AppStore.requestReview(in: scene)
        }
    }
}


