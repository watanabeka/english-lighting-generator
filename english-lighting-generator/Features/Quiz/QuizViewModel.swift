//
//  QuizViewModel.swift
//  english-lighting-generator
//
//  ViewModel for the word-order quiz feature.
//

import FoundationModels
import SwiftData
import SwiftUI

// MARK: - Word Token

struct WordToken: Identifiable, Equatable {
    let id: Int
    let word: String
}

// MARK: - Quiz ViewModel

@available(macOS 26.0, *)
@Observable
final class QuizViewModel {
    var word: String = ""
    var selectedLength: SentenceLength = .normal
    var selectedLevel: EnglishLevel = .level1

    var quiz: WordOrderQuizOutput? = nil
    var translation: String = ""
    var bankTokens: [WordToken] = []
    var placedTokens: [WordToken] = []
    var userSentence: String = ""
    var isChecked: Bool = false
    var isCorrect: Bool = false
    var isGenerating: Bool = false
    var errorMessage: String = ""

    var allPlaced: Bool { bankTokens.isEmpty && !placedTokens.isEmpty }

    private var recentTopics: [String] = []
    private let maxRecentTopics = 5
    private static let validationErrorDomain = "QuizValidation"

    // MARK: - User Actions

    func tapBank(_ token: WordToken) {
        guard !isChecked else { return }
        bankTokens.removeAll { $0.id == token.id }
        placedTokens.append(token)
    }

    func tapPlaced(_ token: WordToken) {
        guard !isChecked else { return }
        placedTokens.removeAll { $0.id == token.id }
        bankTokens.append(token)
    }

    func checkAnswer(modelContext: ModelContext) {
        userSentence = placedTokens.map(\.word).joined(separator: " ")
        isCorrect = userSentence == quiz?.correctSentence
        withAnimation(.spring(duration: 0.3)) { isChecked = true }
        recordUsage(quiz: true, modelContext: modelContext)
        let trimmed = word.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { saveWordHistory(trimmed, modelContext: modelContext) }
    }

    func reset() {
        quiz = nil
        translation = ""
        bankTokens = []
        placedTokens = []
        userSentence = ""
        isChecked = false
        isCorrect = false
        errorMessage = ""
    }

    // MARK: - Generation

    func generate() {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            quiz = nil
            bankTokens = []
            placedTokens = []
            userSentence = ""
            isChecked = false
            isCorrect = false

            let wordHint = word.trimmingCharacters(in: .whitespaces)
            let topicHint = wordHint.isEmpty ? "" : "\nTopic hint: incorporate \"\(wordHint)\" if natural."
            let topicConstraint = recentTopics.isEmpty
                ? "any topic"
                : "avoid [\(recentTopics.joined(separator: ", "))]"

            let systemPrompt = """
                Create a word-order scramble sentence in English.
                Level: \(selectedLevel.quizGrammarHint)
                Topic: \(topicConstraint)\(topicHint)
                No contractions. 6-12 words.
                Return: correctSentence, topic, explanationEnglish, translationEnglish.
                """

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(to: "Generate now.", generating: WordOrderQuizOutput.self)
                let output = response.content

                if !wordHint.isEmpty {
                    guard output.correctSentence.lowercased().contains(wordHint.lowercased()) else {
                        throw NSError(domain: Self.validationErrorDomain, code: 3)
                    }
                }

                let words = output.correctSentence.components(separatedBy: " ").filter { !$0.isEmpty }
                guard words.count >= 6 && words.count <= 12 else {
                    throw NSError(domain: Self.validationErrorDomain, code: 2)
                }

                var shuffled = words.shuffled()
                var attempts = 0
                while shuffled == words && words.count > 1 && attempts < 10 {
                    shuffled = words.shuffled()
                    attempts += 1
                }

                recentTopics.append(output.topic)
                if recentTopics.count > maxRecentTopics { recentTopics.removeFirst() }

                let tokens = shuffled.enumerated().map { WordToken(id: $0.offset, word: $0.element) }
                let translated = try await translateToNative(output.translationEnglish)

                withAnimation(.spring(duration: 0.4)) {
                    quiz = output
                    translation = translated
                    bankTokens = tokens
                }
            } catch {
                if (error as NSError).domain == Self.validationErrorDomain {
                    await Task.yield()
                    generate()
                    return
                }
                errorMessage = await resolveGenerationError(error)
            }
            isGenerating = false
        }
    }
}
