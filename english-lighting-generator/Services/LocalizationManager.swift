//
//  LocalizationManager.swift
//  english-lighting-generator
//
//  Loads JSON-based localization strings and exposes them via subscript.
//  Supports 7 languages; falls back to Japanese if no match is found.
//

import Foundation
import Observation

// MARK: - Supported Language

struct SupportedLanguage: Identifiable, Hashable {
    let id: String
    let displayName: String

    static let all: [SupportedLanguage] = [
        SupportedLanguage(id: "ja",     displayName: "日本語"),
        SupportedLanguage(id: "pt-BR",  displayName: "Português (Brasil)"),
        SupportedLanguage(id: "es-419", displayName: "Español (Latinoamérica)"),
        SupportedLanguage(id: "id",     displayName: "Bahasa Indonesia"),
        SupportedLanguage(id: "vi",     displayName: "Tiếng Việt"),
        SupportedLanguage(id: "ar",     displayName: "العربية"),
        SupportedLanguage(id: "fr",     displayName: "Français"),
    ]

    static let `default` = all[0] // Japanese
}

// MARK: - Localization Manager

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    private(set) var currentLanguage: SupportedLanguage
    private var strings: [String: String] = [:]

    private static let savedLanguageKey = "selectedLanguageID"

    private init() {
        let savedID = UserDefaults.standard.string(forKey: Self.savedLanguageKey)
        if let savedID, let saved = SupportedLanguage.all.first(where: { $0.id == savedID }) {
            currentLanguage = saved
        } else {
            currentLanguage = Self.detectDeviceLanguage()
        }
        loadStrings()
    }

    // MARK: - Language Detection

    private static func detectDeviceLanguage() -> SupportedLanguage {
        for preferred in Locale.preferredLanguages {
            if let match = SupportedLanguage.all.first(where: { preferred.hasPrefix($0.id) }) {
                return match
            }
        }
        return .default
    }

    // MARK: - Language Selection

    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.id, forKey: Self.savedLanguageKey)
        loadStrings()
    }

    // MARK: - String Loading

    private func loadStrings() {
        strings = Self.loadJSON(for: currentLanguage) ?? Self.loadJSON(for: .default) ?? [:]
    }

    private static func loadJSON(for language: SupportedLanguage) -> [String: String]? {
        let url = Bundle.main.url(forResource: language.id, withExtension: "json", subdirectory: "Localization")
            ?? Bundle.main.url(forResource: language.id, withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }

    // MARK: - Subscript

    subscript(key: String) -> String {
        strings[key] ?? key
    }
}

// MARK: - Native Language Name (for AI prompts)

extension LocalizationManager {
    /// Returns the English name of the current UI language, used in AI translation prompts.
    var nativeLanguageName: String {
        switch currentLanguage.id {
        case "pt-BR":  return "Brazilian Portuguese"
        case "es-419": return "Latin American Spanish"
        case "id":     return "Indonesian"
        case "vi":     return "Vietnamese"
        case "ar":     return "Arabic"
        case "fr":     return "French"
        default:       return "Japanese"
        }
    }
}
