// CopyService.swift
// Yap

import Foundation

// MARK: - Protocol

protocol CopyProviding {
    func generateReaction(for mission: Mission) async -> String?
    func generateCopy(for mission: Mission) async -> GeneratedCopy
    func loadReaction(for missionId: UUID) -> String?
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
    
    /// Fast call — only generates the agent's reaction (~2s).
    func generateReaction(for mission: Mission) async -> String? {
        do {
            let body: [String: Any] = [
                "goal": mission.title,
                "tone": mission.agent.displayName,
                "toneDescription": mission.agent.description,
                "language": userLanguage
            ]
            let response: EdgeReactionResponse = try await api.edgeFunction(
                name: "generate-reaction",
                body: .json(body),
                timeout: 10
            )
            let reaction = response.reaction
            // Cache it with the copy if it exists
            if var copy = loadCopy(for: mission.id) {
                let updated = GeneratedCopy(missionId: copy.missionId, messages: copy.messages, reaction: reaction, generatedAt: copy.generatedAt)
                saveCopy(updated)
            } else {
                // Save a placeholder so loadReaction works before messages arrive
                saveReaction(reaction, for: mission.id)
            }
            return reaction.isEmpty ? nil : reaction
        } catch {
            print("\u{26A0}\u{FE0F} Reaction generation failed: \(error.localizedDescription)")
            return nil
        }
    }
    
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
                reaction: response.reaction ?? "",
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
        return GeneratedCopy(missionId: mission.id, messages: messages, reaction: "", generatedAt: Date())
    }
    
    // MARK: - Cache (UserDefaults)
    
    func loadCopy(for missionId: UUID) -> GeneratedCopy? {
        loadAllCopy().first { $0.missionId == missionId }
    }
    
    /// Agent's spontaneous reaction to the mission goal, shown during loading.
    func loadReaction(for missionId: UUID) -> String? {
        // Check reaction cache first, then full copy
        if let cached = UserDefaults.standard.string(forKey: reactionKey(for: missionId)), !cached.isEmpty {
            return cached
        }
        guard let copy = loadCopy(for: missionId), !copy.reaction.isEmpty else { return nil }
        return copy.reaction
    }
    
    private func saveReaction(_ reaction: String, for missionId: UUID) {
        UserDefaults.standard.set(reaction, forKey: reactionKey(for: missionId))
    }
    
    private func reactionKey(for missionId: UUID) -> String {
        "yap_reaction_\(missionId.uuidString)"
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

// MARK: - Edge Function Responses

private struct EdgeReactionResponse: Decodable {
    let reaction: String
}

private struct EdgeCopyResponse: Decodable {
    let messages: [EdgeMessage]
    let reaction: String?
    
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
