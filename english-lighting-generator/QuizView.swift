//
//  QuizView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import SwiftData
import FoundationModels

// MARK: - Quiz Output Model

@available(macOS 26.0, *)
@Generable
struct QuizOutput {
    @Guide(description: "The English word or phrase being tested. Should come from or relate to the user's word history.")
    var targetWord: String

    @Guide(description: "Part of speech of the correct answer. Use exactly one of: noun, verb, adjective, adverb.")
    var answerPos: String

    @Guide(description: "Semantic meaning category of the correct answer. A single lowercase English noun describing the word's meaning domain, e.g. collaboration, emotion, movement, technology, finance, nature.")
    var answerCategory: String

    @Guide(description: "The general topic/domain of this question (e.g., 'workplace', 'travel', 'food', 'technology', 'daily life', 'sports', 'nature', 'relationships', 'education', 'health'). Must be varied across questions.")
    var topic: String

    @Guide(description: "A fill-in-the-blank sentence where the target word is replaced by ___. The blank must require a word of the same part of speech as answerPos.")
    var questionSentence: String

    @Guide(description: "The correct answer: the exact target word or phrase that fills the blank.")
    var correctAnswer: String

    @Guide(description: "Exactly 3 wrong answer options. All must share the same part of speech as answerPos. No duplicates. The correct answer must not appear here.")
    var wrongAnswers: [String]

    @Guide(description: "One reason label per wrong answer, in the same order as wrongAnswers. Each label must be exactly one of: pos_mismatch, register_mismatch, collocation_mismatch, meaning_mismatch. All three labels must be different from each other.")
    var distractorReasons: [String]

    @Guide(description: "A brief explanation (1-2 sentences) of why the correct answer is right and why each wrong answer fails.")
    var explanation: String
}

// MARK: - Quiz State

@available(macOS 26.0, *)
@Observable
final class QuizViewModel {
    var quiz: QuizOutput? = nil
    var selectedAnswer: String? = nil
    var isGenerating: Bool = false
    var errorMessage: String = ""
    var showExplanation: Bool = false
    
    // Track recent topics and words to enforce diversity
    private var recentTopics: [String] = []
    private var recentTargetWords: [String] = []
    private let maxRecentTracking = 5

    var isAnswered: Bool { selectedAnswer != nil }

    var shuffledOptions: [String] {
        guard let quiz else { return [] }
        return ([quiz.correctAnswer] + quiz.wrongAnswers).shuffled()
    }

    func generate(historyWords: [String]) {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            quiz = nil
            selectedAnswer = nil
            showExplanation = false

            // Build vocabulary context from history
            let vocabContext: String
            if historyWords.isEmpty {
                vocabContext = "No history yet. Use common English vocabulary appropriate for intermediate learners."
            } else {
                // Take up to 30 most recent words to keep prompt short
                let sample = historyWords.prefix(30).joined(separator: ", ")
                vocabContext = "The learner has recently studied these words/phrases: \(sample)"
            }

            // Infer approximate level from history breadth using TOEIC-style bands
            let levelHint: String
            switch historyWords.count {
            case 0..<5:   levelHint = "TOEIC under 300"
            case 5..<15:  levelHint = "TOEIC 300-400"
            case 15..<30: levelHint = "TOEIC 400-500"
            default:      levelHint = "TOEIC 600-700"
            }
            
            // Build topic diversity constraint
            let topicConstraint: String
            if recentTopics.isEmpty {
                topicConstraint = "Vary topics across: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health, hobbies, science, entertainment."
            } else {
                let avoided = recentTopics.joined(separator: ", ")
                topicConstraint = "Choose a topic DIFFERENT from recently used: [\(avoided)]. Select from: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health, hobbies, science, entertainment."
            }
            
            // Build word diversity constraint
            let wordConstraint: String
            if recentTargetWords.isEmpty {
                wordConstraint = "Choose any appropriate target word for the learner's level."
            } else {
                let avoided = recentTargetWords.joined(separator: ", ")
                wordConstraint = "Do NOT reuse these recently tested words: [\(avoided)]. Choose a different word from the learner's history or introduce a new related word."
            }

            let systemPrompt = """
                You are an English vocabulary quiz generator for a language-learning app.
                Your task is to create ONE multiple-choice vocabulary question.

                Learner profile:
                - Estimated level (TOEIC-style band): \(levelHint)
                - \(vocabContext)

                DIVERSITY CONSTRAINTS (CRITICAL):
                - Topic diversity: \(topicConstraint)
                - Word diversity: \(wordConstraint)
                - NEVER generate questions about museums, exhibits, or art galleries repeatedly.
                - NEVER use the same adjectives (interesting, fascinating, amazing, boring) in consecutive questions.

                Quiz format rules:
                - Choose a target word/phrase that is educationally valuable at the learner's level.
                - Prefer words from the learner's history if available; occasionally introduce a related new word to expand vocabulary.
                - Write a natural, context-rich fill-in-the-blank sentence.
                - Provide exactly 3 wrong answers.
                - ALL 4 options (1 correct + 3 wrong) must have the SAME part of speech when used in this specific context.
                  Example: If the blank requires an adjective, all 4 options must be adjectives.
                - Each wrong answer must fail for a DIFFERENT, identifiable reason:
                  • One: wrong part of speech (e.g., adverb instead of adjective) OR clearly different meaning
                  • One: wrong register (too formal/informal for the context)
                  • One: wrong collocation (doesn't naturally pair with the surrounding words)
                - The options must contain exactly 4 DISTINCT words (1 correct + 3 distractors).
                - Never repeat the same word in the options.

                Context strength — CRITICAL REQUIREMENTS:
                - The sentence must NOT contain context clues that directly contradict or confirm any specific option.
                - Avoid adjectives or phrases that strongly imply semantic fields (e.g., "interactive elements" → eliminates "boring", confirms "interesting/amazing").
                - The learner must know the target word's PRECISE MEANING to choose it — not just eliminate wrong ones by logic or general context.
                - Example of BAD question:
                  "The museum featured _ artifacts with interactive elements."
                  → "interactive" is too strong a hint; "boring" is eliminated instantly.
                - Example of GOOD question:
                  "The curator chose _ artifacts that were rarely seen outside of private collections."
                  → No strong semantic hint; requires knowing "interesting" means "worthy of attention."

                Distractor quality:
                - At least ONE distractor must be clearly wrong (wrong part of speech, wrong collocation, or clearly different meaning) — not just a near-synonym.
                  This ensures the question has a solvable baseline and avoids "all answers seem correct" scenarios.
                - Each distractor must be plausible in isolation but fail for its stated reason (part of speech, register, or collocation).
                - Do NOT create distractors that are semantically opposite to context clues in the sentence.
                - The remaining 2 distractors can be more subtle (near-synonyms with wrong register or slight collocation issues).

                Output fields:
                - answerPos: part of speech of the correct answer (noun / verb / adjective / adverb)
                - answerCategory: semantic meaning category of the correct answer (e.g. emotion, collaboration, movement)
                - topic: subject domain of the sentence (e.g. workplace, travel, food)
                - distractorReasons: exactly 3 labels in the same order as wrongAnswers; each must be one of: pos_mismatch, register_mismatch, collocation_mismatch, meaning_mismatch; all three must differ
                - All content must be in English.
                - Ensure exactly ONE correct answer.
                """

            let userPrompt = "Generate one fill-in-the-blank vocabulary quiz question now."

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(
                    to: userPrompt,
                    generating: QuizOutput.self
                )
                
                // Defensive post-processing: ensure options are distinct and blank is hidden
                var processedQuiz = response.content
                
                // Track topic and word for diversity
                recentTopics.append(processedQuiz.topic)
                if recentTopics.count > maxRecentTracking {
                    recentTopics.removeFirst()
                }
                recentTargetWords.append(processedQuiz.targetWord.lowercased())
                if recentTargetWords.count > maxRecentTracking {
                    recentTargetWords.removeFirst()
                }
                
                // De-duplicate options while preserving order
                var seen = Set<String>()
                let all = ([processedQuiz.correctAnswer] + processedQuiz.wrongAnswers)
                var uniqueOrdered: [String] = []
                for w in all where !seen.contains(w) {
                    seen.insert(w)
                    uniqueOrdered.append(w)
                }
                // If we lost entries due to duplicates, bail out to trigger a re-generation
                if uniqueOrdered.count != 4 {
                    throw NSError(domain: "QuizValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Duplicate options detected"])
                }

                // Replace any bracketed placeholder like [word] with an underscore blank
                let blanked = processedQuiz.questionSentence.replacingOccurrences(of: #"\[.*?\]"#, with: "______", options: .regularExpression)
                processedQuiz = QuizOutput(
                    targetWord: processedQuiz.targetWord,
                    answerPos: processedQuiz.answerPos,
                    answerCategory: processedQuiz.answerCategory,
                    topic: processedQuiz.topic,
                    questionSentence: blanked,
                    correctAnswer: processedQuiz.correctAnswer,
                    wrongAnswers: Array(uniqueOrdered.dropFirst()),
                    distractorReasons: processedQuiz.distractorReasons,
                    explanation: processedQuiz.explanation
                )
                
                withAnimation(.spring(duration: 0.4)) {
                    quiz = processedQuiz
                }
            } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
                let L = LocalizationManager.shared
                do {
                    let explanation = try await refusal.explanation
                    let explanationContent = explanation.content
                    errorMessage = "[Refusal] \(explanationContent)"
                } catch {
                    errorMessage = "[Refusal] \(L["error.refusalDetail"])\(error.localizedDescription)"
                }
            } catch {
                if (error as NSError).domain == "QuizValidation" {
                    // One-shot retry on validation failure
                    await Task.yield()
                    generate(historyWords: historyWords)
                    return
                }
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }

    func select(answer: String, modelContext: ModelContext) {
        guard !isAnswered else { return }
        withAnimation(.spring(duration: 0.3)) {
            selectedAnswer = answer
            showExplanation = true
        }

        // Increment quiz usage count for today
        let today = String.todayDateKey
        let descriptor = FetchDescriptor<UsageRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            record.aiQuizCount += 1
        } else {
            let record = UsageRecord(date: today, aiSentenceCount: 0, aiQuizCount: 1)
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}

// MARK: - Quiz View

struct QuizView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WordHistoryItem.date, order: .reverse)
    private var historyItems: [WordHistoryItem]

    var body: some View {
        NavigationStack {
            Group {
                if #available(macOS 26.0, *) {
                    switch SystemLanguageModel.default.availability {
                    case .available:
                        QuizContentView()
                    default:
                        UnavailableView(reasonKey: "unavailable.aiUnavailable")
                    }
                } else {
                    UnavailableView(reasonKey: "unavailable.osRequired")
                }
            }
            .navigationTitle(L["tab.quiz"])
        }
    }
}

// MARK: - Quiz Content View

@available(macOS 26.0, *)
private struct QuizContentView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WordHistoryItem.date, order: .reverse)
    private var historyItems: [WordHistoryItem]

    @State private var viewModel = QuizViewModel()

    private var historyWords: [String] {
        historyItems.map(\.englishWord)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Generate Button ───────────────────────────────────────
                Button(action: { viewModel.generate(historyWords: historyWords) }) {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView().controlSize(.small).padding(.trailing, 4)
                            Text(L["button.generating"])
                        } else {
                            Image(systemName: "dice.fill")
                            Text(L["quiz.generateButton"])
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isGenerating)

                // ── Error ─────────────────────────────────────────────────
                if !viewModel.errorMessage.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                        Text(viewModel.errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // ── Quiz Card ─────────────────────────────────────────────
                if let quiz = viewModel.quiz {
                    QuizCard(
                        quiz: quiz,
                        options: viewModel.shuffledOptions,
                        selectedAnswer: viewModel.selectedAnswer,
                        showExplanation: viewModel.showExplanation,
                        L: L,
                        onSelect: { answer in
                            viewModel.select(answer: answer, modelContext: modelContext)
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        )
                    )
                } else if !viewModel.isGenerating {
                    // Prompt state
                    VStack(spacing: 14) {
                        Image(systemName: "questionmark.bubble.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.tint)
                        Text(L["quiz.prompt"])
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(L["quiz.promptDetail"])
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
            .animation(.spring(duration: 0.45), value: viewModel.quiz?.targetWord)
            .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Quiz Card

@available(macOS 26.0, *)
private struct QuizCard: View {
    let quiz: QuizOutput
    let options: [String]
    let selectedAnswer: String?
    let showExplanation: Bool
    let L: LocalizationManager
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── Question ─────────────────────────────────────────────────
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L["quiz.questionLabel"], systemImage: "text.bubble.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text(quiz.questionSentence)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(4)
            }

            // ── Choices ───────────────────────────────────────────────────
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    ChoiceButton(
                        text: option,
                        state: choiceState(for: option),
                        isDisabled: selectedAnswer != nil,
                        action: { onSelect(option) }
                    )
                }
            }

            // ── Explanation ───────────────────────────────────────────────
            if showExplanation {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L["quiz.explanationLabel"], systemImage: "lightbulb.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                        Text(quiz.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(4)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func choiceState(for option: String) -> ChoiceButton.State {
        guard let selected = selectedAnswer else { return .normal }
        if option == quiz.correctAnswer { return .correct }
        if option == selected { return .incorrect }
        return .dimmed
    }
}

// MARK: - Choice Button

private struct ChoiceButton: View {
    enum State {
        case normal, correct, incorrect, dimmed
    }

    let text: String
    let state: State
    let isDisabled: Bool
    let action: () -> Void

    private var bgColor: Color {
        switch state {
        case .normal:    return Color.primary.opacity(0.06)
        case .correct:   return Color.green.opacity(0.15)
        case .incorrect: return Color.red.opacity(0.15)
        case .dimmed:    return Color.primary.opacity(0.03)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:    return Color.primary.opacity(0.12)
        case .correct:   return Color.green
        case .incorrect: return Color.red
        case .dimmed:    return Color.primary.opacity(0.06)
        }
    }

    private var trailingIcon: String? {
        switch state {
        case .correct:   return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        default:         return nil
        }
    }

    private var iconColor: Color {
        state == .correct ? .green : .red
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(state == .dimmed ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(bgColor, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.spring(duration: 0.25), value: state == .correct)
        .animation(.spring(duration: 0.25), value: state == .incorrect)
    }
}

#Preview {
    QuizView()
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
