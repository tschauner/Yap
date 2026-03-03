// Config.swift
// Yap

import Foundation

enum Config {
    
    // MARK: - Supabase (shared project with FiveThings, Pro tier)
    
    static let supabaseURL = "https://dbxpzxtxhcxbsbkcpuak.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRieHB6eHR4aGN4YnNia2NwdWFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4OTExNjAsImV4cCI6MjA4MTQ2NzE2MH0.COHWXncaNZTWIfv5MLYljk3WQaL7DCeZ6JLKCFjrQtI"
    
    /// Edge Function URL für Copy-Generierung
    static var generateCopyURL: URL {
        URL(string: "\(supabaseURL)/functions/v1/generate-copy")!
    }
    
    // MARK: - Firebase
    
    // TODO: Firebase Analytics setup
}
