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

    @Guide(description: "The topic/domain of this sentence in English (e.g., 'workplace', 'travel', 'food', 'technology', 'daily life', 'sports', 'nature', 'relationships').")
    var topic: String

    @Guide(description: "Brief explanation (1-2 sentences) in English of the key grammar point illustrated by this sentence.")
    var explanationEnglish: String

    @Guide(description: "Natural translation of the sentence in English.")
    var translationEnglish: String
}

// Translation output
@available(macOS 26.0, *)
@Generable
struct TranslationOutput {
    @Guide(description: "The translated sentence in the target language.")
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
    var translation: String = ""
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

        let wordToSave = word.trimmingCharacters(in: .whitespaces)
        if !wordToSave.isEmpty {
            saveWordHistory(wordToSave, modelContext: modelContext)
        }
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
                topicConstraint = "any topic"
            } else {
                let avoided = recentTopics.joined(separator: ", ")
                topicConstraint = "avoid [\(avoided)]"
            }

            let systemPrompt = """
                Create a word-order scramble sentence in English.

                Level: \(selectedLevel.quizGrammarHint)
                Topic: \(topicConstraint)\(topicHint)
                No contractions. 6-12 words.

                Return: correctSentence, topic, explanationEnglish (grammar explanation in English), translationEnglish (natural English translation).
                """

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                let response = try await session.respond(
                    to: "Generate now.",
                    generating: WordOrderQuizOutput.self
                )
                let output = response.content

                if !wordHint.isEmpty {
                    let sentenceLower = output.correctSentence.lowercased()
                    let wordLower = wordHint.lowercased()
                    guard sentenceLower.contains(wordLower) else {
                        throw NSError(
                            domain: "QuizValidation", code: 3,
                            userInfo: [NSLocalizedDescriptionKey: "Input word '\(wordHint)' not found in sentence"]
                        )
                    }
                }

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

                let translationSession = LanguageModelSession(instructions: "Translate English to \(nativeLang).")
                let translationResponse = try await translationSession.respond(
                    to: output.translationEnglish,
                    generating: TranslationOutput.self
                )
                let translated = translationResponse.content

                withAnimation(.spring(duration: 0.4)) {
                    quiz = output
                    translation = translated.translation
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
        ZStack {
            if viewModel.isGenerating && !isInputVisible {
                AIGeneratingView(
                    headline: L["button.generating"],
                    subtitle: "問題を生成しています..."
                )
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        if isInputVisible {
                            screenTitle
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if !viewModel.errorMessage.isEmpty {
                            errorCard
                        }

                        if isInputVisible {
                            settingsCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if viewModel.quiz != nil {
                            WordOrderCard(viewModel: viewModel, modelContext: modelContext)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))

                            if viewModel.isChecked {
                                nextButtons
                                    .transition(.opacity)
                            }
                        } else if !viewModel.isGenerating && isInputVisible {
                            promptPlaceholder
                        }
                    }
                    .padding(.bottom, 24)
                    .animation(.spring(duration: 0.45), value: isInputVisible)
                    .animation(.spring(duration: 0.45), value: viewModel.quiz?.correctSentence)
                    .animation(.spring(duration: 0.3), value: viewModel.isChecked)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.quiz?.correctSentence) { _, sentence in
            if sentence != nil {
                withAnimation(.spring(duration: 0.45)) { isInputVisible = false }
            }
        }
    }

    // MARK: Screen Title

    private var screenTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L["tab.quiz"])
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("単語を並べて英文を完成させよう")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.58))
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: Settings Card

    private var settingsCard: some View {
        VStack(spacing: 0) {
            // Word hint
            cardRow {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L["input.wordLabel"])
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Color.appCardSub)
                    TextField(L["quiz.wordHintPlaceholder"], text: $viewModel.word)
                        .font(.body)
                        .foregroundStyle(Color.appCardText)
                }
            }

            cardDivider

            // Level
            cardRow {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L["input.levelLabel"])
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Color.appCardSub)
                        Spacer()
                        Text(L[viewModel.selectedLevel.descriptionKey])
                            .font(.caption2)
                            .foregroundStyle(Color.appCardSub)
                    }
                    Picker("", selection: $viewModel.selectedLevel) {
                        ForEach(EnglishLevel.allCases) { level in
                            Text(L[level.rawValue]).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            generateButton
                .padding(.horizontal, 16)
                .offset(y: 60)
        }
        .padding(.bottom, 72)
    }

    private func cardRow<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(Color.appCardSub.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    private var generateButton: some View {
        Button(action: { viewModel.generate() }) {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(viewModel.isGenerating ? L["button.generating"] : L["quiz.generateButton"])
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.appBlue, Color.appBlueDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.appBlue.opacity(0.45), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isGenerating)
        .opacity(viewModel.isGenerating ? 0.6 : 1.0)
    }

    // MARK: Error Card

    private var errorCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.8, green: 0.1, blue: 0.1))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    // MARK: Prompt Placeholder

    private var promptPlaceholder: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white.opacity(0.70))
            }
            VStack(spacing: 8) {
                Text(L["quiz.prompt"])
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(L["quiz.promptDetail"])
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    // MARK: Next / Reset Buttons

    private var nextButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.reset()
                viewModel.generate()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("次の問題")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.appBlue, Color.appBlueDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.appBlue.opacity(0.40), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Button(action: {
                viewModel.reset()
                withAnimation(.spring(duration: 0.45)) { isInputVisible = true }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "house")
                        .font(.system(size: 15, weight: .semibold))
                    Text("設定に戻る")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white.opacity(0.14))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
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

            // Question card (white)
            if viewModel.quiz != nil {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "text.word.spacing")
                            .font(.caption)
                            .foregroundStyle(Color.appBlue)
                        Text(L["quiz.questionLabel"])
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appBlue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 10)

                    Rectangle()
                        .fill(Color.appCardSub.opacity(0.12))
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)

                    // Translation / question sentence
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.translation)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.appCardText)
                            .textSelection(.enabled)
                        Text(L["quiz.instruction"])
                            .font(.caption)
                            .foregroundStyle(Color.appCardSub)
                    }
                    .padding(20)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
                .padding(.horizontal, 16)
            }

            // Word bank + answer area (hidden after check)
            if !viewModel.isChecked {
                // Bank
                VStack(alignment: .leading, spacing: 12) {
                    Text(L["quiz.bankLabel"])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white.opacity(0.65))
                        .padding(.horizontal, 20)

                    WrapLayout(spacing: 8) {
                        ForEach(viewModel.bankTokens) { token in
                            QuizWordChip(word: token.word, style: .bank) {
                                withAnimation(.spring(duration: 0.2)) { viewModel.tapBank(token) }
                            }
                        }
                    }
                    .frame(minHeight: 40)
                    .padding(.horizontal, 16)
                }

                // Answer area
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.answerLabel"])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white.opacity(0.65))
                        .padding(.horizontal, 20)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        viewModel.placedTokens.isEmpty
                                            ? Color.white.opacity(0.20)
                                            : Color.appBlue.opacity(0.55),
                                        lineWidth: 1.5
                                    )
                            )

                        if viewModel.placedTokens.isEmpty {
                            Text(L["quiz.answerPlaceholder"])
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.35))
                                .padding(14)
                        } else {
                            WrapLayout(spacing: 8) {
                                ForEach(viewModel.placedTokens) { token in
                                    QuizWordChip(word: token.word, style: .placed) {
                                        withAnimation(.spring(duration: 0.2)) { viewModel.tapPlaced(token) }
                                    }
                                }
                            }
                            .padding(10)
                        }
                    }
                    .frame(minHeight: 56)
                    .padding(.horizontal, 16)
                }

                // Check button
                Button(action: { viewModel.checkAnswer(modelContext: modelContext) }) {
                    Text(L["quiz.checkButton"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            viewModel.allPlaced
                                ? LinearGradient(colors: [Color.appBlue, Color.appBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: viewModel.allPlaced ? Color.appBlue.opacity(0.40) : .clear, radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.allPlaced)
                .padding(.horizontal, 16)
            }

            // Result
            if viewModel.isChecked, let quiz = viewModel.quiz {
                QuizResultSection(
                    quiz: quiz,
                    userSentence: viewModel.userSentence,
                    isCorrect: viewModel.isCorrect,
                    translation: viewModel.translation
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .padding(.horizontal, 16)
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.bankTokens.count)
        .animation(.spring(duration: 0.3), value: viewModel.placedTokens.count)
        .animation(.spring(duration: 0.3), value: viewModel.isChecked)
    }
}

// MARK: - Quiz Result Section

@available(macOS 26.0, *)
private struct QuizResultSection: View {
    let quiz: WordOrderQuizOutput
    let userSentence: String
    let isCorrect: Bool
    let translation: String

    @Environment(LocalizationManager.self) private var L

    private var accent: Color { isCorrect ? Color(red: 0.15, green: 0.72, blue: 0.45) : Color(red: 0.90, green: 0.25, blue: 0.25) }
    private var badgeIcon: String { isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill" }

    private func searchInSafari() {
        let query = """
            問題文: \(translation)
            自分の回答: \(userSentence)
            正答: \(quiz.correctSentence)
            この問題を解説、ポイントを教えてください
            """
        if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.google.com/search?q=\(encoded)&udm=50") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Result banner
            HStack(spacing: 10) {
                Image(systemName: badgeIcon)
                    .font(.title3)
                    .foregroundStyle(accent)
                Text(isCorrect ? L["quiz.correct"] : L["quiz.incorrect"])
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(accent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.appCardSub.opacity(0.12))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // Your answer
            VStack(alignment: .leading, spacing: 6) {
                Text(L["quiz.yourSentenceLabel"])
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Color.appCardSub)
                Text(userSentence)
                    .font(.body)
                    .textSelection(.enabled)
                    .foregroundStyle(isCorrect ? Color.appCardText : accent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.appCardSub.opacity(0.12))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // Correct answer
            VStack(alignment: .leading, spacing: 6) {
                Text(L["quiz.correctSentenceLabel"])
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Color.appCardSub)
                Text(quiz.correctSentence)
                    .font(.body)
                    .textSelection(.enabled)
                    .foregroundStyle(Color(red: 0.15, green: 0.65, blue: 0.40))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Search button
            Button(action: { searchInSafari() }) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                    Text(L["quiz.searchButton"])
                        .font(.subheadline).fontWeight(.medium)
                }
                .foregroundStyle(Color.appBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appBlue.opacity(0.08))
            }
            .buttonStyle(.plain)
            .cornerRadius(0)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
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

// MARK: - Quiz Word Chip

private struct QuizWordChip: View {
    enum ChipStyle { case bank, placed }

    let word: String
    let style: ChipStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bgColor, in: Capsule())
                .overlay(
                    Capsule().stroke(borderColor, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var bgColor: Color {
        switch style {
        case .bank:   return Color.white.opacity(0.14)
        case .placed: return Color.appBlue.opacity(0.18)
        }
    }
    private var borderColor: Color {
        switch style {
        case .bank:   return Color.white.opacity(0.30)
        case .placed: return Color.appBlue.opacity(0.60)
        }
    }
    private var textColor: Color {
        switch style {
        case .bank:   return Color.white.opacity(0.90)
        case .placed: return Color.white
        }
    }
}

// MARK: - Preview

#Preview {
    QuizView()
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
