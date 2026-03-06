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

    @Guide(description: "Brief explanation (1-2 sentences in English) of the key grammar point illustrated by this sentence.")
    var explanation: String

    @Guide(description: "Natural Japanese translation of the sentence (自然な日本語). Not word-for-word.")
    var japaneseTranslation: String
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
    var quiz: WordOrderQuizOutput? = nil
    var bankTokens: [WordToken] = []
    var placedTokens: [WordToken] = []
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
        let placed = placedTokens.map(\.word).joined(separator: " ")
        isCorrect = placed == quiz?.correctSentence
        withAnimation(.spring(duration: 0.3)) {
            isChecked = true
        }

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

    func generate(historyWords: [String]) {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            quiz = nil
            bankTokens = []
            placedTokens = []
            isChecked = false
            isCorrect = false

            let vocabContext: String
            if historyWords.isEmpty {
                vocabContext = "No history yet. Use common English vocabulary appropriate for intermediate learners."
            } else {
                let sample = historyWords.prefix(30).joined(separator: ", ")
                vocabContext = "The learner has recently studied: \(sample)"
            }

            let levelHint: String
            switch historyWords.count {
            case 0..<5:   levelHint = "TOEIC under 300"
            case 5..<15:  levelHint = "TOEIC 300–400"
            case 15..<30: levelHint = "TOEIC 400–500"
            default:      levelHint = "TOEIC 600–700"
            }

            let topicConstraint: String
            if recentTopics.isEmpty {
                topicConstraint = "Choose any topic from: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health."
            } else {
                let avoided = recentTopics.joined(separator: ", ")
                topicConstraint = "Avoid recently used topics [\(avoided)]. Choose from: workplace, travel, food, technology, daily life, sports, nature, relationships, education, health."
            }

            let systemPrompt = """
                You are an English language educator creating word-order practice sentences for Japanese learners.

                ## Task
                Generate ONE natural English sentence for a word-order scramble exercise.

                ## Learner profile
                - Level: \(levelHint)
                - \(vocabContext)

                ## Sentence requirements
                - Must be grammatically correct and completely natural
                - Length: 6–12 words (short enough to rearrange, long enough to be educational)
                - \(topicConstraint)
                - Target grammar appropriate for the learner's level
                  (e.g., TOEIC <300: simple present; 400–500: passive voice, relative clauses; 600–700: conditionals, advanced modals)
                - Avoid trivially simple sentences that require no grammar knowledge
                - Do NOT use contractions or parenthetical clauses

                ## Output fields
                - correctSentence: the complete, correct English sentence
                - topic: subject domain (e.g. workplace, travel, food)
                - explanation: brief explanation of the key grammar point (1–2 sentences, in English)
                - japaneseTranslation: natural Japanese translation (idiomatic, not word-for-word)
                """

            let userPrompt = "Generate one word-order quiz sentence now."

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(
                    to: userPrompt,
                    generating: WordOrderQuizOutput.self
                )
                let output = response.content

                // Validate word count (6–12)
                let words = output.correctSentence
                    .components(separatedBy: " ")
                    .filter { !$0.isEmpty }
                guard words.count >= 6 && words.count <= 12 else {
                    throw NSError(
                        domain: "QuizValidation", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Word count out of range: \(words.count)"]
                    )
                }

                // Shuffle on Swift side; guarantee result differs from original
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
                let L = LocalizationManager.shared
                do {
                    let explanation = try await refusal.explanation
                    errorMessage = "[Refusal] \(explanation.content)"
                } catch {
                    errorMessage = "[Refusal] \(L["error.refusalDetail"])\(error.localizedDescription)"
                }
            } catch {
                if (error as NSError).domain == "QuizValidation" {
                    await Task.yield()
                    generate(historyWords: historyWords)
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
    @Environment(LocalizationManager.self) private var L

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

    private var historyWords: [String] { historyItems.map(\.englishWord) }

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
                            .font(.subheadline).foregroundStyle(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // ── Word Order Card ───────────────────────────────────────
                if viewModel.quiz != nil {
                    WordOrderCard(viewModel: viewModel, L: L, modelContext: modelContext)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else if !viewModel.isGenerating {
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
                    .padding(.top, 40)
                }
            }
            .padding()
            .animation(.spring(duration: 0.45), value: viewModel.quiz?.correctSentence)
            .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Word Order Card

@available(macOS 26.0, *)
private struct WordOrderCard: View {
    let viewModel: QuizViewModel
    let L: LocalizationManager
    let modelContext: ModelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Instruction ───────────────────────────────────────────────
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label(L["quiz.questionLabel"], systemImage: "text.word.spacing")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text(L["quiz.instruction"])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            }

            // ── Word Bank ─────────────────────────────────────────────────
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.bankLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    WrapLayout(spacing: 8) {
                        ForEach(viewModel.bankTokens) { token in
                            WordChip(
                                word: token.word,
                                isPlaced: false,
                                isDisabled: viewModel.isChecked
                            ) {
                                withAnimation(.spring(duration: 0.2)) {
                                    viewModel.tapBank(token)
                                }
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
                                            ? (viewModel.isCorrect
                                                ? Color.green.opacity(0.5)
                                                : Color.red.opacity(0.5))
                                            : Color.primary.opacity(0.12),
                                        lineWidth: 1.5
                                    )
                            )
                        if viewModel.placedTokens.isEmpty {
                            Text(L["quiz.answerPlaceholder"])
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(10)
                        } else {
                            WrapLayout(spacing: 8) {
                                ForEach(viewModel.placedTokens) { token in
                                    WordChip(
                                        word: token.word,
                                        isPlaced: true,
                                        isDisabled: viewModel.isChecked
                                    ) {
                                        withAnimation(.spring(duration: 0.2)) {
                                            viewModel.tapPlaced(token)
                                        }
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
                ResultSection(quiz: quiz, isCorrect: viewModel.isCorrect, L: L)
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
    let isCorrect: Bool
    let L: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Correct / Incorrect badge
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCorrect ? .green : .red)
                Text(isCorrect ? L["quiz.correct"] : L["quiz.incorrect"])
                    .font(.headline)
                    .foregroundStyle(isCorrect ? .green : .red)
            }

            // Show correct sentence only when wrong
            if !isCorrect {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L["quiz.correctSentenceLabel"])
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(quiz.correctSentence)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding(4)
                }
            }

            // Explanation
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Label(L["quiz.explanationLabel"], systemImage: "lightbulb.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.yellow)
                    Text(quiz.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(4)
            }

            // Japanese translation
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Label(L["output.japaneseLabel"], systemImage: "j.circle.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    Text(quiz.japaneseTranslation)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
                .padding(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isCorrect ? Color.green : Color.red).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((isCorrect ? Color.green : Color.red).opacity(0.2), lineWidth: 1)
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
