//
//  QuizView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import SwiftData
import FoundationModels

// MARK: - AI Output Model

@available(macOS 26.0, *)
@Generable
struct WordOrderQuizOutput {
    @Guide(description: "A grammatically correct, natural English sentence for a word-order scramble exercise. Must be 6 to 12 words long. No contractions, no parentheses.")
    var correctSentence: String

    @Guide(description: "The topic/domain of this sentence (e.g., 'workplace', 'travel', 'food', 'technology', 'daily life', 'sports', 'nature', 'relationships'). Used for topic diversity.")
    var topic: String

    @Guide(description: "Brief explanation (1-2 sentences) of the key grammar point illustrated by this sentence. Write in the learner's native language as specified in the prompt.")
    var explanation: String

    @Guide(description: "Natural translation of the sentence in the learner's native language. Not word-for-word.")
    var translation: String
}

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
    var bankTokens: [WordToken] = []
    var placedTokens: [WordToken] = []
    var userSentence: String = ""
    var isChecked: Bool = false
    var isCorrect: Bool = false
    var isGenerating: Bool = false
    var errorMessage: String = ""

    private var recentTopics: [String] = []
    private let maxRecentTracking = 5

    var allPlaced: Bool { bankTokens.isEmpty && !placedTokens.isEmpty }

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
        withAnimation(.spring(duration: 0.3)) {
            isChecked = true
        }
        recordUsage(quiz: true, modelContext: modelContext)
    }

    func reset() {
        quiz = nil
        bankTokens = []
        placedTokens = []
        userSentence = ""
        isChecked = false
        isCorrect = false
        errorMessage = ""
    }

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

            let nativeLang = LocalizationManager.shared.nativeLanguageName
            let wordHint = word.trimmingCharacters(in: .whitespaces)
            let topicHint = wordHint.isEmpty ? "" : "\nTopic hint: incorporate \"\(wordHint)\" if natural."

            let topicConstraint: String
            if recentTopics.isEmpty {
                topicConstraint = "Choose any topic: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health."
            } else {
                let avoided = recentTopics.joined(separator: ", ")
                topicConstraint = "Avoid recently used topics [\(avoided)]. Choose from: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health."
            }

            let systemPrompt = """
                You are an English language educator creating word-order practice sentences.

                ## Task
                Generate ONE natural English sentence for a word-order scramble exercise.

                ## Level
                \(selectedLevel.quizGrammarHint)

                ## Sentence requirements
                - Grammatically correct and completely natural
                - \(topicConstraint)\(topicHint)
                - Do NOT use contractions or parenthetical clauses

                ## Output fields
                - correctSentence: the complete, correct English sentence
                - topic: subject domain (e.g. workplace, travel, food)
                - explanation: key grammar point in \(nativeLang) (1–2 sentences)
                - translation: natural \(nativeLang) translation (idiomatic, not word-for-word)
                """

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(
                    to: "Generate one word-order quiz sentence now.",
                    generating: WordOrderQuizOutput.self
                )
                let output = response.content

                let words = output.correctSentence
                    .components(separatedBy: " ")
                    .filter { !$0.isEmpty }
                guard words.count >= 6 && words.count <= 12 else {
                    throw NSError(
                        domain: "QuizValidation", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Word count out of range: \(words.count)"]
                    )
                }

                var shuffled = words.shuffled()
                var attempts = 0
                while shuffled == words && words.count > 1 && attempts < 10 {
                    shuffled = words.shuffled()
                    attempts += 1
                }

                recentTopics.append(output.topic)
                if recentTopics.count > maxRecentTracking { recentTopics.removeFirst() }

                let tokens = shuffled.enumerated().map { WordToken(id: $0.offset, word: $0.element) }
                withAnimation(.spring(duration: 0.4)) {
                    quiz = output
                    bankTokens = tokens
                }
            } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
                do {
                    let content = try await Task.detached { try await refusal.explanation.content }.value
                    errorMessage = "[Refusal] \(content)"
                } catch {
                    errorMessage = "[Refusal] \(error.localizedDescription)"
                }
            } catch {
                if (error as NSError).domain == "QuizValidation" {
                    await Task.yield()
                    generate()
                    return
                }
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }
}

// MARK: - Quiz View (Root)

struct QuizView: View {
    var body: some View {
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
    }
}

// MARK: - Quiz Content View

@available(macOS 26.0, *)
private struct QuizContentView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = QuizViewModel()
    @State private var isInputVisible = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if isInputVisible {
                    inputSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.errorMessage.isEmpty {
                    errorView
                }

                if viewModel.isGenerating && !isInputVisible {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .transition(.opacity)
                }

                if viewModel.quiz != nil {
                    WordOrderCard(viewModel: viewModel, modelContext: modelContext)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))

                    if viewModel.isChecked {
                        ActionButtonsView(
                            onReset: {
                                viewModel.reset()
                                withAnimation(.spring(duration: 0.45)) { isInputVisible = true }
                            },
                            onRegenerate: {
                                viewModel.reset()
                                viewModel.generate()
                            }
                        )
                        .transition(.opacity)
                    }
                } else if !viewModel.isGenerating && isInputVisible {
                    promptPlaceholder
                }
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 5)
            .animation(.spring(duration: 0.45), value: isInputVisible)
            .animation(.spring(duration: 0.45), value: viewModel.quiz?.correctSentence)
            .animation(.spring(duration: 0.3), value: viewModel.isChecked)
            .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.quiz?.correctSentence) { _, sentence in
            if sentence != nil {
                withAnimation(.spring(duration: 0.45)) { isInputVisible = false }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: L["input.wordLabel"]) {
                        TextField(L["quiz.wordHintPlaceholder"], text: $viewModel.word)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    FormSection(title: L["input.sentenceLengthLabel"]) {
                        Picker(L["input.sentenceLengthLabel"], selection: $viewModel.selectedLength) {
                            ForEach(SentenceLength.allCases) { length in
                                Text(L[length.rawValue]).tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Divider()
                    FormSection(title: L["input.levelLabel"], badge: L[viewModel.selectedLevel.descriptionKey]) {
                        Picker(L["input.levelLabel"], selection: $viewModel.selectedLevel) {
                            ForEach(EnglishLevel.allCases) { level in
                                Text(L[level.rawValue]).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(4)
            }

            Button(action: { viewModel.generate() }) {
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
        }
    }

    private var errorView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
            Text(viewModel.errorMessage)
                .font(.subheadline).foregroundStyle(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private var promptPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.word.spacing")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text(L["quiz.prompt"])
                .font(.headline).foregroundStyle(.secondary)
            Text(L["quiz.promptDetail"])
                .font(.subheadline).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Word Order Card

@available(macOS 26.0, *)
private struct WordOrderCard: View {
    let viewModel: QuizViewModel
    let modelContext: ModelContext

    @Environment(LocalizationManager.self) private var L

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Question (translation as prompt) ──────────────────────────
            if let quiz = viewModel.quiz {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L["quiz.questionLabel"], systemImage: "text.word.spacing")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.tint)
                        Text(quiz.translation)
                            .font(.body)
                            .textSelection(.enabled)
                        Text(L["quiz.instruction"])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }
            }

            // ── Word Bank ─────────────────────────────────────────────────
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.bankLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    WrapLayout(spacing: 8) {
                        ForEach(viewModel.bankTokens) { token in
                            WordChip(word: token.word, isPlaced: false, isDisabled: viewModel.isChecked) {
                                withAnimation(.spring(duration: 0.2)) { viewModel.tapBank(token) }
                            }
                        }
                    }
                    .frame(minHeight: 36)
                }
                .padding(4)
            }

            // ── Answer Area ───────────────────────────────────────────────
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.answerLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        viewModel.isChecked
                                            ? (viewModel.isCorrect ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
                                            : Color.primary.opacity(0.12),
                                        lineWidth: 1.5
                                    )
                            )
                        if viewModel.placedTokens.isEmpty {
                            Text(L["quiz.answerPlaceholder"])
                                .font(.subheadline).foregroundStyle(.tertiary)
                                .padding(10)
                        } else {
                            WrapLayout(spacing: 8) {
                                ForEach(viewModel.placedTokens) { token in
                                    WordChip(word: token.word, isPlaced: true, isDisabled: viewModel.isChecked) {
                                        withAnimation(.spring(duration: 0.2)) { viewModel.tapPlaced(token) }
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                    .frame(minHeight: 52)
                }
                .padding(4)
            }

            // ── Check Button ──────────────────────────────────────────────
            if !viewModel.isChecked {
                Button(action: { viewModel.checkAnswer(modelContext: modelContext) }) {
                    Text(L["quiz.checkButton"])
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.allPlaced)
            }

            // ── Result ────────────────────────────────────────────────────
            if viewModel.isChecked, let quiz = viewModel.quiz {
                ResultSection(quiz: quiz, userSentence: viewModel.userSentence, isCorrect: viewModel.isCorrect)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.bankTokens.count)
        .animation(.spring(duration: 0.3), value: viewModel.placedTokens.count)
        .animation(.spring(duration: 0.3), value: viewModel.isChecked)
    }
}

// MARK: - Result Section

@available(macOS 26.0, *)
private struct ResultSection: View {
    let quiz: WordOrderQuizOutput
    let userSentence: String
    let isCorrect: Bool

    @Environment(LocalizationManager.self) private var L

    private var accentColor: Color { isCorrect ? .green : .red }
    private var badgeIcon: String { isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill" }
    private var userSentenceColor: Color { isCorrect ? .primary : Color.red.opacity(0.8) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Badge
            HStack(spacing: 8) {
                Image(systemName: badgeIcon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                Text(isCorrect ? L["quiz.correct"] : L["quiz.incorrect"])
                    .font(.headline)
                    .foregroundStyle(accentColor)
            }

            // User's sentence
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L["quiz.yourSentenceLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(userSentence)
                        .font(.body)
                        .textSelection(.enabled)
                        .foregroundStyle(userSentenceColor)
                }
                .padding(4)
            }

            // Correct sentence (always shown)
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L["quiz.correctSentenceLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(quiz.correctSentence)
                        .font(.body)
                        .textSelection(.enabled)
                        .foregroundStyle(Color.green.opacity(0.9))
                }
                .padding(4)
            }

            // Explanation
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Label(L["quiz.explanationLabel"], systemImage: "lightbulb.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.yellow)
                    Text(quiz.explanation)
                        .font(.subheadline).textSelection(.enabled)
                }
                .padding(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Wrap Layout

private struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Word Chip

private struct WordChip: View {
    let word: String
    let isPlaced: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(bgColor, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var bgColor: Color {
        isPlaced ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06)
    }

    private var borderColor: Color {
        isPlaced ? Color.blue.opacity(0.4) : Color.primary.opacity(0.12)
    }
}

// MARK: - Preview

#Preview {
    QuizView()
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
