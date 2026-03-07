//
//  Date+Extension.swift
//  Yap
//
//  Created by Philipp Tschauner on 06.03.26.
//

import Foundation

extension Date {
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
    
    var isFuture: Bool {
        self > Date()
    }
    
    func isYesterday(comparedTo otherDate: Date = Date()) -> Bool {
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: otherDate) {
            return calendar.isDate(yesterday, inSameDayAs: self)
        }
        return false
    }
    
    var isYesterday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInYesterday(self)
    }
    
    var isYesterdayOrOlder: Bool {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return isYesterday || self < yesterday
    }
    
    var isBirthdayToday: Bool {
        let calendar = Calendar.current
        let birthdayComponents = calendar.dateComponents([.month, .day], from: self)
        let todayComponents = calendar.dateComponents([.month, .day], from: .now)
        return birthdayComponents.month == todayComponents.month && birthdayComponents.day == todayComponents.day
    }
    
    static var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
    
    // Gibt das Datum von heute zurück (normalisiert auf Mitternacht)
    static var today: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return calendar.date(from: components)!
    }
    
    var age: Int {
        let calendar = Calendar.current
        let today = Date()
        let altersKomponente = calendar.dateComponents([.year], from: self, to: today)
        return altersKomponente.year ?? 0
    }
    // Berechnet, wie viele Tage zwischen dem aktuellen Datum und einem anderen Datum liegen
    var daysAgo: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: Date())
        return components.day ?? 0
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: self)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: self)
    }
    
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    static var nextWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    static var twoWeeks: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    }
    
    var isFirstDayOfMonth: Bool {
        Calendar.current.component(.day, from: self) == 1
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    var today7pm: Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 0
        return Calendar.current.date(from: components)
    }
    
    func today(at hour: Int, minute: Int = 0) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }
    
    func daysInbetween(endDate: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: .now, to: endDate)
        return components.day
    }

    
    /// Berechnet die Anzahl der Tage seit einem gegebenen Datum
    func daysAgo(since date: Date, calendar: Calendar = Calendar.current) -> Int {
        return calendar.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
}

extension Date {
    // Initializer, um ein Date zu erstellen, das 'daysAgo' Tage in der Vergangenheit liegt
    init(daysAgo: Int) {
        let calendar = Calendar.current
        self = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
    }
    
    init?(age: Int) {
        let calendar = Calendar.current
        let today = Date()
        
        // Berechne das Geburtsdatum basierend auf dem Alter
        guard let birthdate = calendar.date(byAdding: .year, value: -age, to: today) else {
            return nil
        }
        
        self = birthdate
    }
    
    init?(year: Int, month: Int, day: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // Stelle sicher, dass die Zeitkomponenten auf Mitternacht gesetzt sind
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let date = calendar.date(from: components) else {
            return nil
        }
        self = date
    }
}

extension Calendar {
    private var currentDate: Date { return Date() }
    
    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .month)
    }
    
    func isDateInNextWeek(_ date: Date) -> Bool {
        guard let nextWeek = self.date(byAdding: DateComponents(weekOfYear: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
    }
    
    func isDateInNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    func isDateInFollowingMonth(_ date: Date) -> Bool {
        guard let followingMonth = self.date(byAdding: DateComponents(month: 2), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: followingMonth, toGranularity: .month)
    }
}

extension Array where Element == Date {
    func streak() -> Int {
        // Sortiere das Array in aufsteigender Reihenfolge
        let sortedDates = self.sorted()
        guard !sortedDates.isEmpty else { return 0 }
        
        // Variable für den aktuellen Streak und den maximalen Streak
        var currentStreak = 1
        var maxStreak = 0  // Wir starten mit 0, weil ein Streak mindestens 2 Tage haben muss
        
        // Durch das Array iterieren und die Differenz zwischen aufeinanderfolgenden Tagen prüfen
        for i in 1..<sortedDates.count {
            let currentDate = sortedDates[i]
            let previousDate = sortedDates[i - 1]
            
            // Wenn der Unterschied genau 1 Tag beträgt, dann ist es ein fortgesetzter Streak
            if Calendar.current.isDate(currentDate, inSameDayAs: previousDate.addingTimeInterval(86400)) {
                currentStreak += 1
            } else {
                // Wenn der aktuelle Streak mindestens 2 Tage umfasst, aktualisiere den maximalen Streak
                if currentStreak >= 2 {
                    maxStreak = Swift.max(maxStreak, currentStreak)
                }
                currentStreak = 1
            }
        }
        
        // Am Ende des Arrays den letzten Streak überprüfen
        if currentStreak >= 2 {
            maxStreak = Swift.max(maxStreak, currentStreak)
        }
        
        return maxStreak
    }
}
