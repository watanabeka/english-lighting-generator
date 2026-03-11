//
//  AppTypes.swift
//  english-lighting-generator
//
//  Domain models: level/length enums, AI output structs, app-wide constants.
//

import Foundation
import FoundationModels

// MARK: - App Constants

enum AppConstants {
    /// App Store ID — replace with the actual ID when published.
    static let appStoreID           = "REPLACE_WITH_APP_ID"
    static let appStoreReviewURL    = "itms-apps://itunes.apple.com/app/id\(appStoreID)?action=write-review"
    static let macAppStoreReviewURL = "macappstore://apps.apple.com/app/id\(appStoreID)?action=write-review"
    static let googleSearchURL      = "https://www.google.com/search?q=%@&udm=50"
}

// MARK: - Sentence Length

enum SentenceLength: String, CaseIterable, Identifiable {
    case short  = "sentenceLength.short"
    case normal = "sentenceLength.normal"
    case long   = "sentenceLength.long"

    var id: String { rawValue }

    /// Word-count guidance string used in the AI system prompt.
    var promptInstruction: String {
        switch self {
        case .short:  return "8-12 words"
        case .normal: return "18-25 words"
        case .long:   return "35-50 words"
        }
    }
}

// MARK: - English Level

enum EnglishLevel: String, CaseIterable, Identifiable {
    case level1 = "level.level1"
    case level2 = "level.level2"
    case level3 = "level.level3"
    case level4 = "level.level4"
    case level5 = "level.level5"

    var id: String { rawValue }

    /// Localization key for the level description label shown in UI.
    var descriptionKey: String { "\(rawValue).description" }

    /// CEFR/exam description used in the sentence-generation AI prompt.
    var englishDescription: String {
        switch self {
        case .level1: return "Eiken Grade 4-5 / TOEIC under 300 (A1)"
        case .level2: return "Eiken Grade 3 / TOEIC 300-500 (A2)"
        case .level3: return "Eiken Grade Pre-2 to 2 / TOEIC 500-650 (B1-B2)"
        case .level4: return "Eiken Grade Pre-1 / TOEIC 650-800 (B2-C1)"
        case .level5: return "Eiken Grade 1 / TOEIC 800+ (C1-C2)"
        }
    }

    /// Grammar-hint string used in the quiz-generation AI prompt.
    var quizGrammarHint: String {
        switch self {
        case .level1: return "Simple present tense; basic S+V+O; 6-8 words."
        case .level2: return "Past simple, future will/going to, basic connectors; 7-9 words."
        case .level3: return "Present perfect, passive voice, relative clauses, conditionals; 8-10 words."
        case .level4: return "Advanced modals, participle phrases, third conditional; 9-11 words."
        case .level5: return "Subjunctive, inversion, cleft sentences, C-level sophistication; 10-12 words."
        }
    }
}

// MARK: - AI Output Models  (require macOS 26+ / Apple Intelligence)

@available(macOS 26.0, *)
@Generable
struct SentenceOutput {
    @Guide(description: "A single, grammatically correct English sentence that a native speaker would naturally write or say. The target word must be used meaningfully in context.")
    var englishSentence: String

    @Guide(description: "The normalised English form of the input. For multiple comma-separated inputs, return them comma-separated in the same order. Convert katakana, hiragana, romaji, or misspelled input to correct English. If already correct English, return unchanged.")
    var normalisedEnglishWord: String
}

@available(macOS 26.0, *)
@Generable
struct WordOrderQuizOutput {
    @Guide(description: "A grammatically correct, natural English sentence for a word-order scramble exercise. Must be 6 to 12 words long. No contractions, no parentheses.")
    var correctSentence: String

    @Guide(description: "The topic/domain of this sentence in English (e.g., 'workplace', 'travel', 'food', 'technology', 'daily life', 'sports', 'nature', 'relationships').")
    var topic: String

    @Guide(description: "Brief explanation (1-2 sentences) in English of the key grammar point illustrated by this sentence.")
    var explanationEnglish: String

    @Guide(description: "Natural translation of the sentence in English.")
    var translationEnglish: String
}

/// Shared translation output type used by both Generator and Quiz AI sessions.
@available(macOS 26.0, *)
@Generable
struct AITranslation {
    @Guide(description: "Natural translation of the given text in the target language.")
    var translation: String
}
