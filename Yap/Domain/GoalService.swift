// GoalService.swift
// Yap

import Foundation

/// Manages goal persistence and lifecycle.
/// v1: UserDefaults-basiert. Später SwiftData wenn nötig.
actor GoalService {
    
    static let shared = GoalService()
    private init() {}
    
    private let key = "yap_goals"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - CRUD
    
    /// Neues Goal erstellen. Notifications werden NICHT automatisch geplant.
    func createGoal(title: String, tone: NagTone) -> Goal {
        var goals = loadAll()
        let goal = Goal(title: title, tone: tone)
        goals.append(goal)
        save(goals)
        return goal
    }
    
    /// Goal als erledigt markieren.
    func completeGoal(_ id: UUID) -> Goal? {
        var goals = loadAll()
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return nil }
        goals[index].completedAt = Date()
        save(goals)
        return goals[index]
    }
    
    /// Goal löschen.
    func deleteGoal(_ id: UUID) {
        var goals = loadAll()
        goals.removeAll { $0.id == id }
        save(goals)
    }
    
    /// Goal als extended markieren (24h Verlängerung, nur 1×).
    func extendGoal(_ id: UUID) -> Goal? {
        var goals = loadAll()
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return nil }
        goals[index].extended = true
        save(goals)
        return goals[index]
    }
    
    /// Anzahl der geplanten Notifications speichern.
    func updateNotificationsScheduled(_ id: UUID, count: Int) {
        var goals = loadAll()
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].notificationsScheduled = count
        save(goals)
    }
    
    /// Alle Goals laden.
    func getAllGoals() -> [Goal] {
        loadAll()
    }
    
    /// Nur aktive (nicht erledigte) Goals.
    func activeGoals() -> [Goal] {
        loadAll().filter { !$0.isCompleted }
    }
    
    /// Goals für heute.
    func todaysGoals() -> [Goal] {
        let today = dayKey(for: Date())
        return loadAll().filter { $0.dayKey == today }
    }
    
    // MARK: - Persistence (UserDefaults)
    
    private func loadAll() -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? decoder.decode([Goal].self, from: data)) ?? []
    }
    
    private func save(_ goals: [Goal]) {
        guard let data = try? encoder.encode(goals) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
