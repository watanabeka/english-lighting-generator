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
        withAnimation(.spring(duration: 0.3)) { isChecked = true }
        recordUsage(quiz: true, modelContext: modelContext)
        let wordToSave = word.trimmingCharacters(in: .whitespaces)
        if !wordToSave.isEmpty { saveWordHistory(wordToSave, modelContext: modelContext) }
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
                topicConstraint = "avoid [\(recentTopics.joined(separator: ", "))]"
            }

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
                        throw NSError(domain: "QuizValidation", code: 3, userInfo: [NSLocalizedDescriptionKey: "Input word not found"])
                    }
                }

                let words = output.correctSentence.components(separatedBy: " ").filter { !$0.isEmpty }
                guard words.count >= 6 && words.count <= 12 else {
                    throw NSError(domain: "QuizValidation", code: 2, userInfo: [NSLocalizedDescriptionKey: "Word count out of range"])
                }

                var shuffled = words.shuffled()
                var attempts = 0
                while shuffled == words && words.count > 1 && attempts < 10 {
                    shuffled = words.shuffled(); attempts += 1
                }

                recentTopics.append(output.topic)
                if recentTopics.count > maxRecentTracking { recentTopics.removeFirst() }

                let tokens = shuffled.enumerated().map { WordToken(id: $0.offset, word: $0.element) }

                let translationSession = LanguageModelSession(instructions: "Translate English to \(nativeLang).")
                let translationResponse = try await translationSession.respond(to: output.translationEnglish, generating: TranslationOutput.self)

                withAnimation(.spring(duration: 0.4)) {
                    quiz = output
                    translation = translationResponse.content.translation
                    bankTokens = tokens
                }
            } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
                do {
                    let content = try await Task.detached { try await refusal.explanation.content }.value
                    errorMessage = "[Refusal] \(content)"
                } catch { errorMessage = "[Refusal] \(error.localizedDescription)" }
            } catch {
                if (error as NSError).domain == "QuizValidation" { await Task.yield(); generate(); return }
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
                case .available: QuizContentView()
                default:         UnavailableView(reasonKey: "unavailable.aiUnavailable")
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

    var body: some View {
        ZStack {
            if viewModel.isGenerating {
                // ── Loading ──────────────────────────────────────────────
                GlowLoadingBar(subtitle: L["button.generating"] + "...")
                    .transition(.opacity)

            } else if viewModel.quiz != nil {
                // ── Quiz active ───────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 20) {
                        if !viewModel.errorMessage.isEmpty { errorBanner }
                        WordOrderCard(viewModel: viewModel, modelContext: modelContext)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                        if viewModel.isChecked { nextButtons.transition(.opacity) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .animation(.spring(duration: 0.3), value: viewModel.isChecked)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))

            } else {
                // ── Input (vertically centred) ────────────────────────────
                VStack(spacing: 14) {
                    if !viewModel.errorMessage.isEmpty {
                        errorBanner.padding(.horizontal, 16)
                    }
                    Spacer(minLength: 0)
                    settingsCard.padding(.horizontal, 16)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 20)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.30), value: viewModel.isGenerating)
        .animation(.spring(duration: 0.45), value: viewModel.quiz?.correctSentence)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
    }

    // MARK: Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's Challenge")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cardSub)

            VStack(alignment: .leading, spacing: 6) {
                Text(L["input.wordLabel"])
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cardSub)
                TextField(L["quiz.wordHintPlaceholder"], text: $viewModel.word)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.cardText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.96)))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L["input.levelLabel"])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.cardSub)
                    Spacer()
                    Text(L[viewModel.selectedLevel.descriptionKey])
                        .font(.system(size: 11))
                        .foregroundStyle(Color.cardSub)
                }
                BlueSegmentedPicker(
                    options: EnglishLevel.allCases,
                    label: { L[$0.rawValue] },
                    selection: $viewModel.selectedLevel
                )
            }

            generateButton
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.20), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private var isWordEmpty: Bool { viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty }

    private var generateButton: some View {
        Button(action: { viewModel.generate() }) {
            HStack(spacing: 8) {
                Image(systemName: "dice.fill").font(.system(size: 14, weight: .semibold))
                Text(L["quiz.generateButton"]).font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color.btnBlue.opacity(0.40), radius: 12, y: 5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isWordEmpty)
        .opacity(isWordEmpty ? 0.45 : 1.0)
    }

    // MARK: Error Banner

    private var errorBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.25))
            Text(viewModel.errorMessage).font(.subheadline).foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.15))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.82)).shadow(color: .black.opacity(0.06), radius: 8, y: 3))
    }

    // MARK: Next / Reset Buttons

    private var nextButtons: some View {
        VStack(spacing: 10) {
            Button(action: { viewModel.reset(); viewModel.generate() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .semibold))
                    Text("問題を再生成").font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color.btnBlue.opacity(0.40), radius: 12, y: 5)
                )
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.reset() }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle").font(.system(size: 14, weight: .semibold))
                    Text("完了").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.btnBlue)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Capsule().fill(Color.white.opacity(0.75)).shadow(color: Color.btnBlue.opacity(0.15), radius: 10, y: 4))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Word Order Card

@available(macOS 26.0, *)
private struct WordOrderCard: View {
    let viewModel: QuizViewModel
    let modelContext: ModelContext
    @Environment(LocalizationManager.self) private var L

    var body: some View {
        VStack(spacing: 14) {
            // Question card
            if viewModel.quiz != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Label(L["quiz.questionLabel"], systemImage: "text.word.spacing")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.btnBlue)
                    Text(viewModel.translation)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.cardText)
                        .textSelection(.enabled)
                    Text(L["quiz.instruction"])
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cardSub)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.82))
                        .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.18), radius: 16, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                )
            }

            // Word bank + answer (hidden after check)
            if !viewModel.isChecked {
                // Bank
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.bankLabel"])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cardSub)
                    WrapLayout(spacing: 8) {
                        ForEach(viewModel.bankTokens) { token in
                            QuizWordChip(word: token.word, style: .bank) {
                                withAnimation(.spring(duration: 0.2)) { viewModel.tapBank(token) }
                            }
                        }
                    }
                    .frame(minHeight: 36)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.82))
                        .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.12), radius: 12, x: 0, y: 4)
                )

                // Answer area
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["quiz.answerLabel"])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cardSub)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.96))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.placedTokens.isEmpty
                                            ? Color.cardSub.opacity(0.20)
                                            : Color.btnBlue.opacity(0.45),
                                        lineWidth: 1.5
                                    )
                            )

                        if viewModel.placedTokens.isEmpty {
                            Text(L["quiz.answerPlaceholder"])
                                .font(.subheadline)
                                .foregroundStyle(Color.cardSub.opacity(0.60))
                                .padding(12)
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
                    .frame(minHeight: 52)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.82))
                        .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.12), radius: 12, x: 0, y: 4)
                )

                // Check button
                Button(action: { viewModel.checkAnswer(modelContext: modelContext) }) {
                    Text(L["quiz.checkButton"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(
                            Capsule()
                                .fill(
                                    viewModel.allPlaced
                                        ? LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.cardSub.opacity(0.35), Color.cardSub.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: viewModel.allPlaced ? Color.btnBlue.opacity(0.38) : .clear, radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.allPlaced)
            }

            // Result
            if viewModel.isChecked, let quiz = viewModel.quiz {
                QuizResultSection(quiz: quiz, userSentence: viewModel.userSentence, isCorrect: viewModel.isCorrect, translation: viewModel.translation)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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

    private var accent: Color { isCorrect ? Color(red: 0.12, green: 0.68, blue: 0.40) : Color(red: 0.88, green: 0.22, blue: 0.22) }
    private var badgeIcon: String { isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill" }

    private func searchInSafari() {
        let query = "問題文: \(translation)\n自分の回答: \(userSentence)\n正答: \(quiz.correctSentence)\nこの問題を解説、ポイントを教えてください"
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
            HStack(spacing: 8) {
                Image(systemName: badgeIcon).font(.title3).foregroundStyle(accent)
                Text(isCorrect ? L["quiz.correct"] : L["quiz.incorrect"])
                    .font(.headline).fontWeight(.bold).foregroundStyle(accent)
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)

            Divider().padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
                Text(L["quiz.yourSentenceLabel"]).font(.caption).fontWeight(.semibold).foregroundStyle(Color.cardSub)
                Text(userSentence).font(.body).textSelection(.enabled)
                    .foregroundStyle(isCorrect ? Color.cardText : accent)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            Divider().padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
                Text(L["quiz.correctSentenceLabel"]).font(.caption).fontWeight(.semibold).foregroundStyle(Color.cardSub)
                Text(quiz.correctSentence).font(.body).textSelection(.enabled)
                    .foregroundStyle(Color(red: 0.12, green: 0.60, blue: 0.38))
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            Button(action: { searchInSafari() }) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.system(size: 13))
                    Text(L["quiz.searchButton"]).font(.subheadline).fontWeight(.medium)
                }
                .foregroundStyle(Color.btnBlue)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.btnBlue.opacity(0.07))
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.18), radius: 16, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
}

// MARK: - Wrap Layout

private struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0; var rowWidth: CGFloat = 0; var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing; rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bgColor, in: Capsule())
                .overlay(Capsule().stroke(borderColor, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var bgColor: Color {
        switch style {
        case .bank:   return Color.white.opacity(0.80)
        case .placed: return Color.btnBlue.opacity(0.12)
        }
    }
    private var borderColor: Color {
        switch style {
        case .bank:   return Color.cardSub.opacity(0.30)
        case .placed: return Color.btnBlue.opacity(0.50)
        }
    }
    private var textColor: Color {
        switch style {
        case .bank:   return Color.cardText
        case .placed: return Color.btnBlue
        }
    }
}

// MARK: - Preview

#Preview {
    QuizView()
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
