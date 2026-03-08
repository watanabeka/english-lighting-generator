//
//  ContentView.swift
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
struct SentenceOutput {
    @Guide(description: "A single, grammatically correct English sentence that a native speaker would naturally write or say. The target word must be used meaningfully in context.")
    var englishSentence: String

    @Guide(description: "The normalised English form of the input in English. For multiple comma-separated inputs, return them comma-separated in the same order. Convert katakana, hiragana, romaji, or misspelled input to correct English. If already correct English, return unchanged.")
    var normalisedEnglishWord: String
}

// Simple translation output
@available(macOS 26.0, *)
@Generable
struct SimpleTranslation {
    @Guide(description: "The translated text in the target language.")
    var translation: String
}

// MARK: - Sentence Length

enum SentenceLength: String, CaseIterable, Identifiable {
    case short  = "sentenceLength.short"
    case normal = "sentenceLength.normal"
    case long   = "sentenceLength.long"

    var id: String { rawValue }

    var englishName: String {
        switch self {
        case .short:  return "Short"
        case .normal: return "Normal"
        case .long:   return "Long"
        }
    }

    var instruction: String {
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
    var descriptionKey: String { "\(rawValue).description" }

    var englishName: String {
        switch self {
        case .level1: return "Level 1"
        case .level2: return "Level 2"
        case .level3: return "Level 3"
        case .level4: return "Level 4"
        case .level5: return "Level 5"
        }
    }

    var englishDescription: String {
        switch self {
        case .level1: return "Eiken Grade 4-5 / TOEIC under 300 (A1)"
        case .level2: return "Eiken Grade 3 / TOEIC 300-500 (A2)"
        case .level3: return "Eiken Grade Pre-2 to 2 / TOEIC 500-650 (B1-B2)"
        case .level4: return "Eiken Grade Pre-1 / TOEIC 650-800 (B2-C1)"
        case .level5: return "Eiken Grade 1 / TOEIC 800+ (C1-C2)"
        }
    }

    var instruction: String {
        switch self {
        case .level1:
            return """
                Level 1 — Eiken Grade 4-5 / TOEIC under 300 (A1 beginner).
                Vocabulary: only the most basic everyday words (family, food, animals, colours, numbers, simple actions: go, eat, have, like, want, see, use, play).
                Grammar: present simple tense only; "can" for ability is acceptable.
                Structure: simple Subject + Verb + Object; one clause only; 6-10 words.
                AVOID: past tense, future tense, modal verbs (except "can"), relative clauses, idioms, phrasal verbs, or any word a complete beginner would not know.
                Example style: "I use a computer at school every day."
                """
        case .level2:
            return """
                Level 2 — Eiken Grade 3 / TOEIC 300-500 (A2 elementary).
                Vocabulary: common everyday words plus simple topic words (school subjects, hobbies, weather, shopping, travel); short adjectives and adverbs.
                Grammar: past simple, future (will / going to), present continuous; basic connectors (and, but, because, so, when).
                Structure: compound sentences with two short clauses; 10-16 words.
                AVOID: relative clauses, perfect tenses, passive voice, conditionals, idioms, or academic vocabulary.
                Example style: "She studied hard because she wanted to pass the exam."
                """
        case .level3:
            return """
                Level 3 — Eiken Grade Pre-2 to 2 / TOEIC 500-650 (B1-B2 intermediate).
                Vocabulary: wider everyday and topic-specific vocabulary (environment, technology, health, society); include one or two words slightly above basic level.
                Grammar: present perfect, past perfect, passive voice, relative clauses (who/which/that), second conditional (if + past + would), modals (should, must, might, could).
                Structure: complex sentences with one or two subordinate clauses; 16-24 words.
                AVOID: subjunctive mood, inversion, cleft sentences, or C-level academic/literary vocabulary.
                Example style: "The report, which was released last month, has significantly changed the policies that many companies are now following."
                """
        case .level4:
            return """
                Level 4 — Eiken Grade Pre-1 / TOEIC 650-800 (B2-C1 upper-intermediate).
                Vocabulary: academic and professional vocabulary (analyse, consequence, perspective, demonstrate, contribute, fundamental, facilitate, inevitable).
                Grammar: third conditional, reported speech, passive in various tenses, participle phrases (having done..., given that..., compared with...), advanced modals.
                Structure: sophisticated multi-clause sentences with clear logical and rhetorical flow; 22-32 words.
                AVOID: inverted structures (Rarely has...), subjunctive (were it not for...), or highly literary vocabulary.
                Example style: "Had the government introduced stricter regulations earlier, many of the environmental consequences that society is currently grappling with could have been avoided."
                """
        case .level5:
            return """
                Level 5 — Eiken Grade 1 / TOEIC 800+ (C1-C2 advanced).
                Vocabulary: sophisticated and precise — naturally use words such as "nuanced", "ephemeral", "juxtapose", "ostensibly", "precipitate", "reconcile", "ubiquitous", or equivalents suited to the target word's domain.
                Grammar: subjunctive mood (were it not for...), inversion (Rarely has..., Not only did..., Had I known...), participle clauses (Having considered..., Confronted with...), cleft sentences (It is ... that ...).
                Style: varied sentence rhythm and rhetorical elegance — quality journalism, academic writing, or literary non-fiction level.
                AVOID: simple or predictable structures; every sentence must demonstrate clear C-level linguistic sophistication.
                Example style: "Rarely has a single technological breakthrough so profoundly reshaped the way societies communicate as the advent of the internet did."
                """
        }
    }

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

// MARK: - Shared Views

struct ActionButtonsView: View {
    let onReset: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        HStack(spacing: 48) {
            Spacer()
            Button(action: onReset) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            Button(action: onRegenerate) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - ViewModel

@available(macOS 26.0, *)
@Observable
class AppViewModel {
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

            let nativeLang = LocalizationManager.shared.nativeLanguageName

            let systemPrompt = """
                Create an English example sentence.

                Level \(level.englishName.replacingOccurrences(of: "Level ", with: "")): \(level.englishDescription)
                Length: \(sentenceLength.instruction)

                Use target word(s) naturally. Return: englishSentence, normalisedEnglishWord.
                """

            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                // Step 1: Generate English sentence
                let response = try await session.respond(
                    to: "Target: \"\(word)\"",
                    generating: SentenceOutput.self
                )
                let content = response.content

                // Check if input word is included in the generated sentence
                let inputWords = word.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                let sentenceLower = content.englishSentence.lowercased()
                let allWordsIncluded = inputWords.allSatisfy { inputWord in
                    !inputWord.isEmpty && sentenceLower.contains(inputWord)
                }

                guard allWordsIncluded else {
                    // Retry generation if input word(s) not found
                    generate(modelContext: modelContext)
                    return
                }

                // Step 2: Translate to native language
                let translationSession = LanguageModelSession(instructions: "Translate English to \(nativeLang).")
                let translationResponse = try await translationSession.respond(
                    to: content.englishSentence,
                    generating: SimpleTranslation.self
                )
                let translated = translationResponse.content

                withAnimation(.spring(duration: 0.5)) {
                    englishResult = content.englishSentence
                    translationResult = translated.translation
                }

                let normWord = content.normalisedEnglishWord.trimmingCharacters(in: .whitespacesAndNewlines)
                let wordToSave = normWord.isEmpty ? word : normWord
                saveWordHistory(wordToSave, modelContext: modelContext)
                recordUsage(sentence: true, modelContext: modelContext)

            } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
                do {
                    let content = try await Task.detached { try await refusal.explanation.content }.value
                    errorMessage = "[Refusal] \(content)"
                } catch {
                    errorMessage = "[Refusal] \(error.localizedDescription)"
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var L = LocalizationManager.shared
    @State private var selectedTab: Int = 0
    @State private var prefillWord: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L["tab.aiSentence"], systemImage: "square.and.pencil", value: 0) {
                if #available(macOS 26.0, *) {
                    AvailabilityGateView(prefillWord: $prefillWord)
                } else {
                    UnavailableView(reasonKey: "unavailable.osRequired")
                }
            }
            Tab(L["tab.quiz"], systemImage: "text.word.spacing", value: 1) {
                QuizView()
            }
            Tab(L["tab.history"], systemImage: "chart.bar.fill", value: 2) {
                AnalyticsView(onSelectWord: { word in
                    prefillWord = word
                    selectedTab = 0
                })
            }
            Tab(L["tab.settings"], systemImage: "gearshape.fill", value: 3) {
                SettingsView()
            }
        }
        .environment(L)
    }
}

// MARK: - Availability Gate

@available(macOS 26.0, *)
struct AvailabilityGateView: View {
    @Binding var prefillWord: String

    var body: some View {
        switch SystemLanguageModel.default.availability {
        case .available:
            GeneratorView(prefillWord: $prefillWord)
        default:
            UnavailableView(reasonKey: "unavailable.aiUnavailable")
        }
    }
}

// MARK: - Unavailable View

struct UnavailableView: View {
    @Environment(LocalizationManager.self) private var L
    let reasonKey: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text(L["unavailable.title"])
                .font(.title2).fontWeight(.semibold)
            Text(L[reasonKey])
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Generator View

@available(macOS 26.0, *)
struct GeneratorView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AppViewModel()
    @State private var isInputVisible = true
    @Binding var prefillWord: String

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

                if !viewModel.englishResult.isEmpty {
                    outputSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    ActionButtonsView(
                        onReset: {
                            viewModel.reset()
                            withAnimation(.spring(duration: 0.45)) { isInputVisible = true }
                        },
                        onRegenerate: {
                            viewModel.generate(modelContext: modelContext)
                        }
                    )
                    .transition(.opacity)
                }
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 5)
            .animation(.spring(duration: 0.45), value: isInputVisible)
            .animation(.spring(duration: 0.45), value: viewModel.englishResult.isEmpty)
            .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.englishResult) { _, result in
            if !result.isEmpty {
                withAnimation(.spring(duration: 0.45)) { isInputVisible = false }
            }
        }
        .onChange(of: prefillWord) { _, newWord in
            guard !newWord.isEmpty else { return }
            viewModel.word = newWord
            viewModel.reset()
            withAnimation(.spring(duration: 0.45)) { isInputVisible = true }
            prefillWord = ""
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: L["input.wordLabel"]) {
                        TextField(L["input.wordPlaceholder"], text: $viewModel.word)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    FormSection(title: L["input.sentenceLengthLabel"]) {
                        Picker(L["input.sentenceLengthLabel"], selection: $viewModel.sentenceLength) {
                            ForEach(SentenceLength.allCases) { length in
                                Text(L[length.rawValue]).tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Divider()
                    FormSection(title: L["input.levelLabel"], badge: L[viewModel.level.descriptionKey]) {
                        Picker(L["input.levelLabel"], selection: $viewModel.level) {
                            ForEach(EnglishLevel.allCases) { level in
                                Text(L[level.rawValue]).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(4)
            }

            Button(action: { viewModel.generate(modelContext: modelContext) }) {
                HStack {
                    if viewModel.isGenerating {
                        ProgressView().controlSize(.small).padding(.trailing, 4)
                        Text(L["button.generating"])
                    } else {
                        Image(systemName: "wand.and.sparkles")
                        Text(L["button.generate"])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isGenerating)
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

    private var outputSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                ResultCard(
                    label: L["output.englishLabel"],
                    systemImage: "globe",
                    color: .blue,
                    text: viewModel.englishResult
                )
                if viewModel.isTranslationVisible {
                    ResultCard(
                        label: L["output.japaneseLabel"],
                        systemImage: "character.bubble",
                        color: .orange,
                        text: viewModel.translationResult
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button(action: {
                        withAnimation(.spring(duration: 0.35)) {
                            viewModel.isTranslationVisible = true
                        }
                    }) {
                        Label(L["button.showJapanese"], systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .transition(.opacity)
                }
            }
            .padding(4)
        } label: {
            Label(L["output.title"], systemImage: "sparkles").font(.headline)
        }
        .animation(.spring(duration: 0.35), value: viewModel.isTranslationVisible)
    }
}

// MARK: - Reusable Subviews

struct FormSection<Content: View>: View {
    let title: String
    var badge: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.bold)
                if let badge {
                    Spacer()
                    Text(badge).font(.caption).foregroundStyle(.secondary)
                }
            }
            content()
        }
    }
}

struct ResultCard: View {
    let label: String
    let systemImage: String
    let color: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: systemImage)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(color)
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
