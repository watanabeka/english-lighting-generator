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

    @Guide(description: "A natural, fluent Japanese translation (自然な日本語). Do NOT translate word-for-word. Use Japanese expressions that convey the same meaning naturally and match the register (casual or formal) of the English sentence.")
    var japaneseTranslation: String

    @Guide(description: "The normalised English form of the input word or phrase. If the input was katakana, hiragana, romaji, or another language, write the correct English equivalent here. If the input was already correct English, repeat it unchanged.")
    var normalisedEnglishWord: String
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
        case .short:  return "Keep the sentence short and concise (approximately 8–12 words)."
        case .normal: return "Write a sentence of moderate length (approximately 18–25 words)."
        case .long:   return "Write a longer, more detailed sentence (approximately 35–50 words)."
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
                Level 1 — Eiken Grade 4–5 / TOEIC under 300 (A1 beginner).
                Vocabulary: only the most basic everyday words (family, food, animals, colours, numbers, simple actions: go, eat, have, like, want, see, use, play).
                Grammar: present simple tense only; "can" for ability is acceptable.
                Structure: simple Subject + Verb + Object; one clause only; 6–10 words.
                AVOID: past tense, future tense, modal verbs (except "can"), relative clauses, idioms, phrasal verbs, or any word a complete beginner would not know.
                Example style: "I use a computer at school every day."
                """
        case .level2:
            return """
                Level 2 — Eiken Grade 3 / TOEIC 300–500 (A2 elementary).
                Vocabulary: common everyday words plus simple topic words (school subjects, hobbies, weather, shopping, travel); short adjectives and adverbs.
                Grammar: past simple, future (will / going to), present continuous; basic connectors (and, but, because, so, when).
                Structure: compound sentences with two short clauses; 10–16 words.
                AVOID: relative clauses, perfect tenses, passive voice, conditionals, idioms, or academic vocabulary.
                Example style: "She studied hard because she wanted to pass the exam."
                """
        case .level3:
            return """
                Level 3 — Eiken Grade Pre-2 to 2 / TOEIC 500–650 (B1–B2 intermediate).
                Vocabulary: wider everyday and topic-specific vocabulary (environment, technology, health, society); include one or two words slightly above basic level.
                Grammar: present perfect, past perfect, passive voice, relative clauses (who/which/that), second conditional (if + past + would), modals (should, must, might, could).
                Structure: complex sentences with one or two subordinate clauses; 16–24 words.
                AVOID: subjunctive mood, inversion, cleft sentences, or C-level academic/literary vocabulary.
                Example style: "The report, which was released last month, has significantly changed the policies that many companies are now following."
                """
        case .level4:
            return """
                Level 4 — Eiken Grade Pre-1 / TOEIC 650–800 (B2–C1 upper-intermediate).
                Vocabulary: academic and professional vocabulary (analyse, consequence, perspective, demonstrate, contribute, fundamental, facilitate, inevitable).
                Grammar: third conditional, reported speech, passive in various tenses, participle phrases (having done…, given that…, compared with…), advanced modals.
                Structure: sophisticated multi-clause sentences with clear logical and rhetorical flow; 22–32 words.
                AVOID: inverted structures (Rarely has…), subjunctive (were it not for…), or highly literary vocabulary.
                Example style: "Had the government introduced stricter regulations earlier, many of the environmental consequences that society is currently grappling with could have been avoided."
                """
        case .level5:
            return """
                Level 5 — Eiken Grade 1 / TOEIC 800+ (C1–C2 advanced).
                Vocabulary: sophisticated and precise — naturally use words such as "nuanced", "ephemeral", "juxtapose", "ostensibly", "precipitate", "reconcile", "ubiquitous", or equivalents suited to the target word's domain.
                Grammar: subjunctive mood (were it not for…), inversion (Rarely has…, Not only did…, Had I known…), participle clauses (Having considered…, Confronted with…), cleft sentences (It is … that …).
                Style: varied sentence rhythm and rhetorical elegance — quality journalism, academic writing, or literary non-fiction level.
                AVOID: simple or predictable structures; every sentence must demonstrate clear C-level linguistic sophistication.
                Example style: "Rarely has a single technological breakthrough so profoundly reshaped the way societies communicate as the advent of the internet did."
                """
        }
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
    var japaneseResult: String = ""
    var isGenerating: Bool = false
    var errorMessage: String = ""
    var isJapaneseVisible: Bool = false

    func generate(modelContext: ModelContext) {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            englishResult = ""
            japaneseResult = ""
            isJapaneseVisible = false

            let systemPrompt = """
                You are an expert English educator creating example sentences for Japanese learners.

                ## Output fields (return ALL three, always)
                - englishSentence: the generated sentence
                - japaneseTranslation: natural Japanese translation (idiomatic, register-matched)
                - normalisedEnglishWord: the standard English form of the user's raw input
                  (katakana/hiragana/romaji → convert to English; already English → return unchanged;
                   multiple inputs → return comma-separated normalised forms in the same order)

                ## Target word rules
                - Use ALL provided target words/phrases exactly once, meaningfully integrated
                - If multiple words feel forced together, prioritise naturalness over mechanical inclusion
                - Correct typos/non-English input silently; reflect correction in normalisedEnglishWord

                ## Level: \(level.englishName) — \(level.englishDescription)
                \(level.instruction)

                ## Sentence length: \(sentenceLength.englishName)
                \(sentenceLength.instruction)

                ## Quality
                - Native-speaker naturalness is the highest priority
                - Vocabulary and grammar must feel distinctly appropriate for the level
                - Japanese: never word-for-word; use idiomatic phrasing; match English register
                """

            let userPrompt = """
                Target: "\(word)"
                Generate now.
                """

            let session = LanguageModelSession(instructions: systemPrompt)

            do {
                let response = try await session.respond(
                    to: userPrompt,
                    generating: SentenceOutput.self
                )
                let content = response.content
                withAnimation(.spring(duration: 0.5)) {
                    englishResult = content.englishSentence
                    japaneseResult = content.japaneseTranslation
                }

                // ── Save to History ─────────────────────────────────────
                let today = String.todayDateKey
                let normWord = content.normalisedEnglishWord.trimmingCharacters(in: .whitespacesAndNewlines)
                let wordToSave = normWord.isEmpty ? word : normWord

                // Check if the same word was already used today
                let descriptor = FetchDescriptor<WordHistoryItem>(
                    predicate: #Predicate { $0.date == today && $0.englishWord == wordToSave }
                )
                if let existing = try? modelContext.fetch(descriptor).first {
                    existing.generationCount += 1
                } else {
                    let item = WordHistoryItem(date: today, englishWord: wordToSave)
                    modelContext.insert(item)
                }

                // ── Update Usage Record ─────────────────────────────────
                let usageDescriptor = FetchDescriptor<UsageRecord>(
                    predicate: #Predicate { $0.date == today }
                )
                if let record = try? modelContext.fetch(usageDescriptor).first {
                    record.aiSentenceCount += 1
                } else {
                    let record = UsageRecord(date: today, aiSentenceCount: 1, aiQuizCount: 0)
                    modelContext.insert(record)
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
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var L = LocalizationManager.shared
    // Tab selection shared between tabs (History → AI Sentence prefill)
    @State private var selectedTab: Int = 0
    @State private var prefillWord: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: AI Sentence
            Tab(L["tab.aiSentence"], systemImage: "pencil.and.sparkles", value: 0) {
                if #available(macOS 26.0, *) {
                    AvailabilityGateView(prefillWord: $prefillWord)
                } else {
                    UnavailableView(reasonKey: "unavailable.osRequired")
                }
            }

            // Tab 1: History
            Tab(L["tab.history"], systemImage: "clock.fill", value: 1) {
                HistoryView(onSelectWord: { word in
                    prefillWord = word
                    selectedTab = 0
                })
            }

            // Tab 2: AI Quiz
            Tab(L["tab.quiz"], systemImage: "questionmark.bubble.fill", value: 2) {
                QuizView()
            }

            // Tab 3: Settings
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
                .font(.title2)
                .fontWeight(.semibold)

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
    @Binding var prefillWord: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Input Group ───────────────────────────────────────────
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

                    // ── Generate Button ───────────────────────────────────────
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
                    .disabled(
                        viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty
                        || viewModel.isGenerating
                    )

                    // ── Error Message ─────────────────────────────────────────
                    if !viewModel.errorMessage.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(viewModel.errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // ── Output Group ──────────────────────────────────────────
                    if !viewModel.englishResult.isEmpty || !viewModel.japaneseResult.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 16) {

                                if !viewModel.englishResult.isEmpty {
                                    ResultCard(
                                        label: L["output.englishLabel"],
                                        systemImage: "e.circle.fill",
                                        color: .blue,
                                        text: viewModel.englishResult
                                    )
                                }

                                if !viewModel.japaneseResult.isEmpty {
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.35)) {
                                            viewModel.isJapaneseVisible.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: viewModel.isJapaneseVisible ? "eye.slash.fill" : "eye.fill")
                                            Text(L[viewModel.isJapaneseVisible ? "button.hideJapanese" : "button.showJapanese"])
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                }

                                if !viewModel.japaneseResult.isEmpty && viewModel.isJapaneseVisible {
                                    ResultCard(
                                        label: L["output.japaneseLabel"],
                                        systemImage: "j.circle.fill",
                                        color: .orange,
                                        text: viewModel.japaneseResult
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(4)
                        } label: {
                            Label(L["output.title"], systemImage: "sparkles")
                                .font(.headline)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            )
                        )
                    }
                }
                .padding()
                .animation(.spring(duration: 0.45), value: viewModel.englishResult)
                .animation(.spring(duration: 0.45), value: viewModel.japaneseResult)
                .animation(.spring(duration: 0.35), value: viewModel.isJapaneseVisible)
                .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(L["tab.aiSentence"])
        }
        // When History tab sends a word, pre-fill the text field
        .onChange(of: prefillWord) { _, newWord in
            if !newWord.isEmpty {
                viewModel.word = newWord
                prefillWord = ""
            }
        }
    }
}

// MARK: - Common Subviews

/// Labeled form section with an optional badge text (e.g. level description).
struct FormSection<Content: View>: View {
    let title: String
    var badge: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline).fontWeight(.bold)
                if let badge {
                    Spacer()
                    Text(badge)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
    }
}

/// Colored text result card used for English and Japanese output.
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
