//
//  LanguageResolver.swift
//  FiveThings
//
//  Created by Philipp Tschauner on 08.09.25.
//

import Foundation

enum LanguageResolver {
    /// Alle im App-Bundle vorhandenen Localizations (ohne "Base"), normalisiert.
    /// Portugiesisch wird immer zu "pt-br" normalisiert.
    static func appLocalizations() -> [String] {
        Bundle.main.localizations
            .filter { $0.lowercased() != "base" }
            .map(normalize)
    }

    /// Bevorzugte App-Sprache (aus deinen Localizations) – normalisiert
    static var preferredAppLang: String {
        if let preferred = Bundle.main.preferredLocalizations.first {
            return normalize(preferred)
        }
        if #available(iOS 16, *) {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return "en"
    }

    /// Liefert die Sprache, die auch vom Backend unterstützt wird (Fallback auf first allowed)
    static func currentBackendLang(allowed: Set<String> = ["en", "de", "fr", "es", "pt-br"]) -> String {
        let pref = preferredAppLang
        if allowed.contains(pref) { return pref }

        // Nimm die erste deiner App-Localizations, die im Backend erlaubt ist
        for code in appLocalizations() where allowed.contains(code) {
            return code
        }
        // Fallback
        return allowed.first ?? "en"
    }

    /// "de-DE" -> "de", "en-GB" -> "en"
    /// Portugiesisch wird immer zu "pt-br" normalisiert (wir verwenden nur PT-BR)
    private static func normalize(_ code: String) -> String {
        let lower = code.lowercased()
        // All Portuguese variants → pt-br
        if lower.hasPrefix("pt") { return "pt-br" }
        return lower.split(separator: "-").first.map(String.init) ?? lower
    }
}
