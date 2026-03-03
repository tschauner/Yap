// CopyService.swift
// Yap

import Foundation

/// Generiert alle Notification-Texte für ein Goal via Supabase Edge Function (GPT-Proxy).
/// Ein einziger API-Call pro Goal → alle ~24 Messages vorproduziert.
/// Fallback auf statische NagCopy-Templates wenn offline/Fehler.
actor CopyService {
    
    static let shared = CopyService()
    private init() {}
    
    private let storageKey = "yap_generated_copy"
    
    // MARK: - Public
    
    /// Generiert Copy für ein Goal. Gibt GeneratedCopy zurück.
    /// Bei API-Fehler: Fallback auf statische Templates.
    func generateCopy(for goal: Goal) async -> GeneratedCopy {
        // Zuerst prüfen ob wir schon Copy haben
        if let existing = loadCopy(for: goal.id) {
            return existing
        }
        
        do {
            let messages = try await callEdgeFunction(goal: goal)
            let copy = GeneratedCopy(
                goalId: goal.id,
                messages: messages,
                generatedAt: Date()
            )
            saveCopy(copy)
            return copy
        } catch {
            print("⚠️ Copy generation failed: \(error.localizedDescription). Using fallback.")
            return buildFallbackCopy(for: goal)
        }
    }
    
    /// Löscht gespeicherte Copy für ein Goal.
    func deleteCopy(for goalId: UUID) {
        var allCopy = loadAllCopy()
        allCopy.removeAll { $0.goalId == goalId }
        saveAllCopy(allCopy)
    }
    
    // MARK: - Device Language
    
    /// Gibt die bevorzugte Sprache des Users zurück (z.B. "German", "English", "Spanish").
    private var userLanguage: String {
        guard let langCode = Locale.current.language.languageCode?.identifier else {
            return "English"
        }
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: langCode) ?? "English"
    }
    
    // MARK: - Edge Function Call
    
    private func callEdgeFunction(goal: Goal) async throws -> [GeneratedCopy.Message] {
        let schedule = EscalationLevel.buildSchedule()
        let messageCount = min(schedule.count, 24)
        
        let levelDescriptions = schedule.prefix(messageCount).enumerated().map { index, entry in
            let levelName: String = switch entry.level {
            case .gentle: "gentle (friendly, calm)"
            case .nudge: "nudge (a bit more insistent)"
            case .push: "push (clearly impatient)"
            case .urgent: "urgent (losing it)"
            case .meltdown: "meltdown (completely unhinged)"
            }
            return "Message \(index + 1): level=\(levelName), sent \(entry.minuteOffset) minutes after goal was set"
        }.joined(separator: "\n")
        
        let requestBody: [String: Any] = [
            "goal": goal.title,
            "tone": goal.tone.displayName,
            "toneDescription": goal.tone.description,
            "language": userLanguage,
            "messageCount": messageCount,
            "levels": levelDescriptions
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: Config.generateCopyURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw CopyError.apiError(statusCode: statusCode)
        }
        
        let decoded = try JSONDecoder().decode(EdgeResponse.self, from: data)
        
        return decoded.messages.map {
            GeneratedCopy.Message(
                title: String($0.title.prefix(40)),
                body: String($0.body.prefix(120)),
                level: $0.level
            )
        }
    }
    
    // MARK: - Fallback (statische Templates)
    
    private func buildFallbackCopy(for goal: Goal) -> GeneratedCopy {
        let schedule = EscalationLevel.buildSchedule()
        let messages = schedule.prefix(24).enumerated().map { index, entry in
            let template = NagCopy.template(tone: goal.tone, level: entry.level, index: index)
            let resolved = template.resolved(with: goal.title)
            return GeneratedCopy.Message(
                title: resolved.title,
                body: resolved.body,
                level: entry.level.rawValue
            )
        }
        
        return GeneratedCopy(
            goalId: goal.id,
            messages: messages,
            generatedAt: Date()
        )
    }
    
    // MARK: - Persistence
    
    func loadCopy(for goalId: UUID) -> GeneratedCopy? {
        loadAllCopy().first { $0.goalId == goalId }
    }
    
    private func loadAllCopy() -> [GeneratedCopy] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([GeneratedCopy].self, from: data)) ?? []
    }
    
    private func saveCopy(_ copy: GeneratedCopy) {
        var all = loadAllCopy()
        all.removeAll { $0.goalId == copy.goalId }
        all.append(copy)
        saveAllCopy(all)
    }
    
    private func saveAllCopy(_ copies: [GeneratedCopy]) {
        guard let data = try? JSONEncoder().encode(copies) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    // MARK: - Types
    
    private struct EdgeResponse: Decodable {
        let messages: [EdgeMessage]
    }
    
    private struct EdgeMessage: Decodable {
        let title: String
        let body: String
        let level: Int
    }
    
    enum CopyError: LocalizedError {
        case apiError(statusCode: Int)
        case parseError
        
        var errorDescription: String? {
            switch self {
            case .apiError(let code): "Edge Function error (HTTP \(code))"
            case .parseError: "Failed to parse response"
            }
        }
    }
}
