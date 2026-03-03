// HomeViewModel.swift
// Yap

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    enum Phase: Equatable {
        case onboarding      // Erster Start
        case activeGoal(Goal) // Laufendes Goal — Notifications aktiv
        case input           // Textfeld sichtbar
        case pickAgent       // Agent/Tone auswählen
        case generating      // Copy wird generiert
        case completed(Goal) // Gerade erledigt — Celebration
        case gaveUp(Goal)    // Aufgegeben — Loser Screen
    }
    
    @Published var goalText: String = ""
    @Published var selectedTone: NagTone? = nil
    @Published var phase: Phase = .input
    @Published var error: String? = nil
    @Published var showPaywall: Bool = false
    
    private let onboardingKey = "yap_onboarding_complete"
    
    var canSubmitGoal: Bool {
        !goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Lifecycle
    
    /// Beim App-Start: Onboarding nötig? Aktives Goal vorhanden?
    func onAppear() async {
        // Onboarding Check
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            phase = .onboarding
            return
        }
        
        // Aktives Goal laden
        if let activeGoal = await GoalService.shared.activeGoals().first {
            phase = .activeGoal(activeGoal)
        } else {
            phase = .input
        }
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        phase = .input
    }
    
    // MARK: - Goal Flow
    
    /// User hat Goal-Text bestätigt → weiter zur Agent-Auswahl.
    func submitGoalText() {
        guard canSubmitGoal else { return }
        phase = .pickAgent
    }
    
    /// User hat Agent gewählt → Pro-Check → Goal speichern + Copy generieren.
    func selectAgent(_ tone: NagTone) {
        // Pro-Gate: gesperrte Agents brauchen Pro
        if ProAccess.requiresPro(tone) && !StoreManager.shared.isPro {
            showPaywall = true
            return
        }
        
        selectedTone = tone
        phase = .generating
        
        Task {
            let title = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Goal persistieren
            var goal = await GoalService.shared.createGoal(title: title, tone: tone)
            
            // AI Copy nur für Pro, sonst Fallback
            if ProAccess.canUseAICopy {
                _ = await CopyService.shared.generateCopy(for: goal)
            }
            
            // Notifications starten
            let scheduled = await NagService.shared.scheduleEscalation(for: goal)
            
            // Scheduled Count speichern
            await GoalService.shared.updateNotificationsScheduled(goal.id, count: scheduled)
            goal.notificationsScheduled = scheduled
            
            // Direkt in den aktiven Zustand
            phase = .activeGoal(goal)
            goalText = ""
            selectedTone = nil
        }
    }
    
    // MARK: - Active Goal Actions
    
    /// Goal erledigt.
    func markGoalDone(_ goal: Goal) async {
        _ = await GoalService.shared.completeGoal(goal.id)
        await NagService.shared.goalCompleted(goal.id)
        phase = .completed(goal)
    }
    
    /// Goal aufgeben → Loser Screen.
    func giveUpGoal(_ goal: Goal) async {
        await NagService.shared.cancelNotifications(for: goal.id)
        await CopyService.shared.deleteCopy(for: goal.id)
        // Goal nicht sofort löschen — wir brauchen die Stats für den Loser Screen
        phase = .gaveUp(goal)
    }
    
    /// Loser Screen bestätigt → Goal löschen + zurück zum Input.
    func confirmGaveUp(_ goal: Goal) async {
        await GoalService.shared.deleteGoal(goal.id)
        phase = .input
    }
    
    /// 24h Verlängerung (nur 1× pro Goal).
    func extendGoal(_ goal: Goal) async {
        guard !goal.extended else { return }
        
        // Goal als extended markieren
        guard let updated = await GoalService.shared.extendGoal(goal.id) else { return }
        
        // Alte Notifications canceln
        await NagService.shared.cancelNotifications(for: goal.id)
        
        // Neue Notifications planen (Schedule startet wieder von vorne)
        await NagService.shared.scheduleEscalation(for: updated)
        
        phase = .activeGoal(updated)
    }
    
    /// Nach Celebration → zurück zum Input.
    func backToInput() {
        phase = .input
    }
}
