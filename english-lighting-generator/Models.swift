//
//  Models.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import Foundation
import SwiftData

// MARK: - Word History Item
//
// Stores one entry per word/phrase the user submitted.
// `date` is a "yyyy-MM-dd" string so all generations on the same
// calendar day share the same value and can be grouped easily.
// `englishWord` always holds the English form (the app normalises
// katakana / other-language input before saving).
// `generationCount` is incremented each time the user taps Generate
// for this word on the same day.

@Model
final class WordHistoryItem {
    var date: String = ""           // "yyyy-MM-dd"
    var englishWord: String = ""    // normalised English word / phrase
    var generationCount: Int = 0
    var compositeKey: String = ""   // app-side uniqueness key

    init(date: String, englishWord: String, generationCount: Int = 1) {
        self.date = date
        self.englishWord = englishWord
        self.generationCount = generationCount
        self.compositeKey = "\(date)|\(englishWord)"
    }
}

// MARK: - Usage Record
//
// One record per calendar day, keyed by `date` ("yyyy-MM-dd").
// Tracks how many times each AI feature was invoked that day.
// Used for future subscription throttling.
//
// • `aiSentenceCount`  – taps of "Generate sentence" in the AI Sentence tab
// • `aiQuizCount`      – quiz generations in the AI Quiz tab

@Model
final class UsageRecord {
    var date: String = ""  // "yyyy-MM-dd" - one record per day
    var aiSentenceCount: Int = 0
    var aiQuizCount: Int = 0

    init(date: String, aiSentenceCount: Int = 0, aiQuizCount: Int = 0) {
        self.date = date
        self.aiSentenceCount = aiSentenceCount
        self.aiQuizCount = aiQuizCount
    }
}

// MARK: - Date Helpers

extension String {
    /// Returns today's date as a "yyyy-MM-dd" string.
    static var todayDateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}
