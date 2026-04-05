// CopyService.swift
// Yap

import Foundation
import SwiftUI

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
            var body: [String: Any] = [
                "goal": mission.title,
                "tone": mission.agent.displayName,
                "toneDescription": mission.agent.description,
                "language": userLanguage
            ]
            
            let userName = UserDefaults.standard.string(forKey: "user_display_name") ?? ""
            if !userName.isEmpty {
                body["userName"] = userName
            }
            
            // Special Agents get memory — past missions with this agent
            if mission.agent.isSpecialAgent {
                let memory = await loadAgentMemory(agent: mission.agent)
                if !memory.isEmpty {
                    body["agentMemory"] = memory
                }
            }
            let response: EdgeReactionResponse = try await api.edgeFunction(
                name: "generate-reaction",
                body: .json(body),
                timeout: 10
            )
            let reaction = response.reaction
            // Cache it with the copy if it exists
            if let copy = loadCopy(for: mission.id) {
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
            let body = await requestBody(for: mission)
            let response: EdgeCopyResponse = try await api.edgeFunction(
                name: "generate-copy",
                body: .json(body),
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
    
    private func requestBody(for mission: Mission) async -> [String: Any] {
        let minutesUntilDeadline = max(0, Int(mission.deadline.timeIntervalSinceNow / 60))
        // +2h extension: deadline is close → pushes start in 1 min (same day).
        // +24h extension: deadline is far away (tomorrow 18:00) → pushes start 9 AM next day.
        // Normal missions: first push at 1 min for instant feedback.
        // (pg_cron fires every 60s → real delivery ~1-2 min after mission start)
        let firstPushOffset: Int
        if mission.extended && minutesUntilDeadline > 720 {
            // Long extension (24h) — delay first push to 9 AM on deadline day
            let cal = Calendar.current
            let deadlineDay9 = cal.date(bySettingHour: 9, minute: 0, second: 0,
                                        of: mission.deadline) ?? mission.deadline
            firstPushOffset = max(1, Int(deadlineDay9.timeIntervalSinceNow / 60))
        } else {
            firstPushOffset = 1
        }
        let rawSchedule = EscalationLevel.buildSchedule(
            profile: mission.agent.escalationProfile,
            startOffsetMinutes: firstPushOffset,
            availableMinutes: minutesUntilDeadline
        )
        
        // Quiet Hours: shift notifications that fall into silent period
        let schedule = Self.applyQuietHours(to: rawSchedule, missionStart: mission.createdAt, deadline: mission.deadline)
        let count = min(schedule.count, 24)
        
        let levels = schedule.prefix(count).enumerated().map { i, entry in
            "Message \(i + 1): level=\(entry.level.promptName), sent \(entry.minuteOffset)min after start"
        }.joined(separator: "\n")
        
        let customRoast = UserDefaults.standard.string(forKey: "customRoast") ?? ""
        
        let isPro = ProAccess.isPro
        
        var body: [String: Any] = [
            "goal": mission.title,
            "tone": mission.agent.displayName,
            "toneDescription": mission.agent.description,
            "language": userLanguage,
            "messageCount": count,
            "levels": levels,
            "isPro": isPro,
            "extended": mission.extended
        ]
        
        if !customRoast.isEmpty {
            body["userContext"] = customRoast
        }
        
        let userName = UserDefaults.standard.string(forKey: "user_display_name") ?? ""
        if !userName.isEmpty {
            body["userName"] = userName
        }
        
        // Remote Push: send schedule offsets so server can schedule notifications
        if DeviceService.shared.isRegistered {
            body["goalId"] = mission.id.uuidString
            body["deviceId"] = APIClient.deviceId
            body["agent"] = mission.agent.rawValue
            body["scheduleOffsets"] = schedule.prefix(count).map { entry in
                ["minuteOffset": entry.minuteOffset, "level": entry.level.rawValue]
            }
        }
        
        // Special Agents get memory — past missions with this agent
        if mission.agent.isSpecialAgent {
            let memory = await loadAgentMemory(agent: mission.agent)
            if !memory.isEmpty {
                body["agentMemory"] = memory
            }
        }
        
        return body
    }
    
    // MARK: - Agent Memory
    
    private func loadAgentMemory(agent: Agent) async -> [[String: Any]] {
        struct MemoryEntry: Decodable {
            let title: String
            let status: String
            let timeToCompleteMinutes: Int?
            let createdAt: String?
        }
        
        do {
            let entries: [MemoryEntry] = try await api.rpc(
                function: "get_agent_memory",
                params: .json([
                    "p_device_id": APIClient.deviceId,
                    "p_agent": agent.rawValue
                ])
            )
            return entries.map { entry in
                var dict: [String: Any] = [
                    "goal": entry.title,
                    "outcome": entry.status == "completed" ? "completed" : "gave up"
                ]
                if let mins = entry.timeToCompleteMinutes {
                    dict["minutes"] = mins
                }
                return dict
            }
        } catch {
            print("\u{26A0}\u{FE0F} Agent memory load failed: \(error.localizedDescription)")
            return []
        }
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
        LanguageResolver.currentBackendLang()
    }
    
    // MARK: - Quiet Hours Filter
    
    /// Verschiebt Schedule-Einträge, die in Quiet Hours fallen, zum nächsten erlaubten Zeitpunkt.
    /// Einträge die nach der Deadline landen würden, werden entfernt.
    static func applyQuietHours(
        to schedule: [(minuteOffset: Int, level: EscalationLevel)],
        missionStart: Date,
        deadline: Date
    ) -> [(minuteOffset: Int, level: EscalationLevel)] {
        guard QuietHours.isEnabled else { return schedule }
        
        let minutesUntilDeadline = max(0, Int(deadline.timeIntervalSince(missionStart) / 60))
        
        return schedule.compactMap { entry in
            let fireDate = missionStart.addingTimeInterval(TimeInterval(entry.minuteOffset * 60))
            guard QuietHours.isQuietTime(fireDate) else { return entry }
            
            // Verschiebe auf nächsten erlaubten Zeitpunkt
            let allowed = QuietHours.nextAllowedTime(after: fireDate)
            let newOffset = Int(allowed.timeIntervalSince(missionStart) / 60)
            
            // Nur behalten wenn noch vor Deadline
            guard newOffset < minutesUntilDeadline else { return nil }
            return (minuteOffset: newOffset, level: entry.level)
        }
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
                body: String(body.prefix(150)),
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
