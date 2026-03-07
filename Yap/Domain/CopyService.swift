// CopyService.swift
// Yap

import Foundation

// MARK: - Protocol

protocol CopyProviding {
    func generateCopy(for mission: Mission) async -> GeneratedCopy
    func deleteCopy(for missionId: UUID)
}

/// Generiert alle Notification-Texte für eine Mission via Supabase Edge Function (GPT-Proxy).
/// Ein einziger API-Call pro Mission → alle ~24 Messages vorproduziert.
/// Fallback auf statische NagCopy-Templates wenn offline/Fehler.
final class CopyService: CopyProviding {
    
    static let shared = CopyService()
    
    private let api: APIClient
    private let storageKey = "yap_generated_copy"
    
    init(api: APIClient = .init()) {
        self.api = api
    }
    
    // MARK: - Public
    
    func generateCopy(for mission: Mission) async -> GeneratedCopy {
        if let cached = loadCopy(for: mission.id) { return cached }
        
        do {
            let response: EdgeCopyResponse = try await api.edgeFunction(
                name: "generate-copy",
                body: .json(requestBody(for: mission)),
                timeout: 30
            )
            let copy = GeneratedCopy(
                missionId: mission.id,
                messages: response.messages.map { $0.toCopyMessage() },
                generatedAt: Date()
            )
            saveCopy(copy)
            return copy
        } catch {
            print("⚠️ Copy generation failed: \(error.localizedDescription). Using fallback.")
            return fallbackCopy(for: mission)
        }
    }
    
    func deleteCopy(for missionId: UUID) {
        var all = loadAllCopy()
        all.removeAll { $0.missionId == missionId }
        saveAllCopy(all)
    }
    
    // MARK: - Request
    
    private func requestBody(for mission: Mission) -> [String: Any] {
        let schedule = EscalationLevel.buildSchedule(profile: mission.agent.escalationProfile)
        let count = min(schedule.count, 24)
        
        let levels = schedule.prefix(count).enumerated().map { i, entry in
            "Message \(i + 1): level=\(entry.level.promptName), sent \(entry.minuteOffset)min after start"
        }.joined(separator: "\n")
        
        return [
            "goal": mission.title,
            "tone": mission.agent.displayName,
            "toneDescription": mission.agent.description,
            "language": userLanguage,
            "messageCount": count,
            "levels": levels
        ]
    }
    
    // MARK: - Fallback
    
    private func fallbackCopy(for mission: Mission) -> GeneratedCopy {
        let messages = EscalationLevel.buildSchedule(profile: mission.agent.escalationProfile).prefix(24).enumerated().map { i, entry in
            let resolved = NagCopy.template(agent: mission.agent, level: entry.level, index: i)
                .resolved(with: mission.title)
            return GeneratedCopy.Message(title: resolved.title, body: resolved.body, level: entry.level.rawValue)
        }
        return GeneratedCopy(missionId: mission.id, messages: messages, generatedAt: Date())
    }
    
    // MARK: - Cache (UserDefaults)
    
    func loadCopy(for missionId: UUID) -> GeneratedCopy? {
        loadAllCopy().first { $0.missionId == missionId }
    }
    
    private func loadAllCopy() -> [GeneratedCopy] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([GeneratedCopy].self, from: data)) ?? []
    }
    
    private func saveCopy(_ copy: GeneratedCopy) {
        var all = loadAllCopy()
        all.removeAll { $0.missionId == copy.missionId }
        all.append(copy)
        saveAllCopy(all)
    }
    
    private func saveAllCopy(_ copies: [GeneratedCopy]) {
        guard let data = try? JSONEncoder().encode(copies) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    // MARK: - Helpers
    
    private var userLanguage: String {
        guard let code = Locale.current.language.languageCode?.identifier else { return "English" }
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
}

// MARK: - Edge Function Response

private struct EdgeCopyResponse: Decodable {
    let messages: [EdgeMessage]
    
    struct EdgeMessage: Decodable {
        let title: String
        let body: String
        let level: Int
        
        func toCopyMessage() -> GeneratedCopy.Message {
            .init(
                title: String(title.prefix(40)),
                body: String(body.prefix(120)),
                level: level
            )
        }
    }
}

// MARK: - EscalationLevel Prompt Helper

private extension EscalationLevel {
    var promptName: String {
        switch self {
        case .gentle:   "gentle (friendly, calm)"
        case .nudge:    "nudge (a bit more insistent)"
        case .push:     "push (clearly impatient)"
        case .urgent:   "urgent (losing it)"
        case .meltdown: "meltdown (completely unhinged)"
        }
    }
}
