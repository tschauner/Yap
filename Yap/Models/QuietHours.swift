// QuietHours.swift
// Yap

import Foundation
import SwiftUI

/// Ruhezeiten für Notifications — keine Pushes zwischen Start und Ende.
/// Verwendet AppStorage Keys für Settings.
struct QuietHours {
    
    static let startKey = "quiet_hours_start"
    static let endKey = "quiet_hours_end"
    
    /// Default values
    static let defaultStart = 22
    static let defaultEnd = 8
    
    /// Prüft ob eine gegebene Uhrzeit in der Ruhezeit liegt.
    static func isQuietTime(_ date: Date, start: Int, end: Int) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        
        if start < end {
            // z.B. 08:00 - 18:00 (tagsüber ruhig)
            return hour >= start && hour < end
        } else {
            // z.B. 22:00 - 08:00 (nachts ruhig)
            return hour >= start || hour < end
        }
    }
    
    /// Prüft ob eine Notification zur gegebenen Zeit geplant werden sollte.
    static func shouldScheduleNotification(at date: Date, start: Int, end: Int) -> Bool {
        !isQuietTime(date, start: start, end: end)
    }
}
