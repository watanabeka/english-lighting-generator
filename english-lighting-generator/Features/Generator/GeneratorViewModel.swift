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
                Create an English example sentence.
                Level: \(level.englishDescription)
                Length: \(sentenceLength.promptInstruction)
                Use target word(s) naturally. Return: englishSentence, normalisedEnglishWord.
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
