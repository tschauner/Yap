// QuietHours.swift
// Yap

import Foundation

/// Silent Hours — keine Push-Notifications in diesem Zeitraum.
/// Default: 22:00–08:00, standardmäßig aktiviert.
struct QuietHours {
    
    // MARK: - Keys
    
    static let enabledKey = "quiet_hours_enabled"
    static let startKey = "quiet_hours_start"
    static let endKey = "quiet_hours_end"
    
    // MARK: - Defaults
    
    static let defaultEnabled = true
    static let defaultStart = 22  // 22:00
    static let defaultEnd = 8    // 08:00
    
    // MARK: - Current Values
    
    static var isEnabled: Bool {
        get {
            // First launch: default true (key doesn't exist → return true)
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return defaultEnabled }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
    
    static var start: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: startKey)
            return UserDefaults.standard.object(forKey: startKey) == nil ? defaultStart : val
        }
        set { UserDefaults.standard.set(newValue, forKey: startKey) }
    }
    
    static var end: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: endKey)
            return UserDefaults.standard.object(forKey: endKey) == nil ? defaultEnd : val
        }
        set { UserDefaults.standard.set(newValue, forKey: endKey) }
    }
    
    // MARK: - Logic
    
    /// Prüft ob eine gegebene Uhrzeit in der Ruhezeit liegt.
    static func isQuietTime(_ date: Date) -> Bool {
        guard isEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: date)
        return isQuietHour(hour, start: start, end: end)
    }
    
    /// Prüft ob eine bestimmte Stunde in der Ruhezeit liegt.
    static func isQuietHour(_ hour: Int, start: Int, end: Int) -> Bool {
        if start < end {
            return hour >= start && hour < end
        } else {
            // z.B. 22:00 – 08:00 (über Mitternacht)
            return hour >= start || hour < end
        }
    }
    
    /// Prüft ob ein geplanter Push (basierend auf Mission-Start + Offset) in Quiet Hours fällt.
    static func missionSpansQuietHours(missionStart: Date, deadline: Date) -> Bool {
        guard isEnabled else { return false }
        let cal = Calendar.current
        var cursor = missionStart
        while cursor < deadline {
            if isQuietTime(cursor) { return true }
            cursor = cal.date(byAdding: .hour, value: 1, to: cursor) ?? deadline
        }
        return false
    }
    
    /// Verschiebt einen Zeitpunkt aus Quiet Hours zum nächsten erlaubten Zeitpunkt.
    /// Wenn der Zeitpunkt nicht in Quiet Hours liegt, wird er unverändert zurückgegeben.
    static func nextAllowedTime(after date: Date) -> Date {
        guard isEnabled, isQuietTime(date) else { return date }
        let cal = Calendar.current
        // Setze auf `end` Uhr am selben/nächsten Tag
        var result = cal.date(bySettingHour: end, minute: 0, second: 0, of: date) ?? date
        // Wenn end < start (über Mitternacht), und wir sind vor Mitternacht,
        // dann ist end am nächsten Tag
        if result <= date {
            result = cal.date(byAdding: .day, value: 1, to: result) ?? result
        }
        return result
    }
    
    /// Formatted range string, e.g. "10 PM – 8 AM" or "22:00 – 08:00"
    static var formattedRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        let uses24h = !(formatter.dateFormat?.contains("a") ?? false)
        
        if uses24h {
            return String(format: "%02d:00 – %02d:00", start, end)
        } else {
            let startDate = Calendar.current.date(bySettingHour: start, minute: 0, second: 0, of: Date()) ?? Date()
            let endDate = Calendar.current.date(bySettingHour: end, minute: 0, second: 0, of: Date()) ?? Date()
            let tf = DateFormatter()
            tf.dateFormat = "h a"
            return "\(tf.string(from: startDate)) – \(tf.string(from: endDate))"
        }
    }
}
