//
//  GeneratorViewModel.swift
//  english-lighting-generator
//
//  ViewModel for the English sentence generator feature.
//

import FoundationModels
import SwiftData
import SwiftUI

@available(macOS 26.0, *)
@Observable
final class GeneratorViewModel {
    var word: String = ""
    var sentenceLength: SentenceLength = .normal
    var level: EnglishLevel = .level1
    var englishResult: String = ""
    var translationResult: String = ""
    var isGenerating: Bool = false
    var errorMessage: String = ""
    var isTranslationVisible: Bool = false

    func reset() {
        englishResult = ""
        translationResult = ""
        errorMessage = ""
        isTranslationVisible = false
    }

    func generate(modelContext: ModelContext) {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            englishResult = ""
            translationResult = ""

            let systemPrompt = """
                You are a helpful English teacher creating natural example sentences for language learners.

                Task: Create ONE grammatically correct, natural English sentence using the target word(s).

                Requirements:
                - Level: \(level.englishDescription) — use vocabulary and grammar appropriate for this level
                - Length: approximately \(sentenceLength.promptInstruction)
                - The sentence must sound natural in everyday spoken English
                - Prefer common expressions used by native speakers
                - Avoid formal or academic style
                - Use ALL target words naturally in context (not forced or artificial)

                Rules:
                - DO NOT create unnatural or textbook-style sentences

                Output format:
                - englishSentence: the example sentence in English
                - normalisedEnglishWord: the base form of the target word (lowercase, no punctuation)

                Example:

                englishSentence: "I usually drink coffee in the morning."
                normalisedEnglishWord: "drink"

                Before returning the answer, verify:
                1. The sentence uses the target word(s) naturally
                2. The sentence is natural everyday English
                3. The grammar is correct
                4. The vocabulary matches the level
                """

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(
                    to: "Target: \"\(word)\"",
                    generating: SentenceOutput.self
                )
                let content = response.content

                let inputWords = word.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces).lowercased()
                }
                let sentenceLower = content.englishSentence.lowercased()
                guard inputWords.allSatisfy({ !$0.isEmpty && sentenceLower.contains($0) }) else {
                    generate(modelContext: modelContext)
                    return
                }

                let translated = try await translateToNative(content.englishSentence)
                withAnimation(.spring(duration: 0.5)) {
                    englishResult = content.englishSentence
                    translationResult = translated
                }

                let normWord = content.normalisedEnglishWord.trimmingCharacters(in: .whitespacesAndNewlines)
                saveWordHistory(normWord.isEmpty ? word : normWord, modelContext: modelContext)
                recordUsage(sentence: true, modelContext: modelContext)

            } catch {
                errorMessage = await resolveGenerationError(error)
            }

            isGenerating = false
        }
    }
}
