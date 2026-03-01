//
//  ContentView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import FoundationModels

// MARK: - Generable Output

@available(macOS 26.0, *)
@Generable
struct SentenceOutput {
    @Guide(description: "A single, grammatically correct English sentence that a native speaker would naturally write or say. The target word must be used meaningfully in context.")
    var englishSentence: String

    @Guide(description: "A natural, fluent Japanese translation (自然な日本語). Do NOT translate word-for-word. Use Japanese expressions that convey the same meaning naturally and match the register (casual or formal) of the English sentence.")
    var japaneseTranslation: String
}

// MARK: - Sentence Length

enum SentenceLength: String, CaseIterable, Identifiable {
    case short  = "少ない"
    case normal = "普通"
    case long   = "多い"

    var id: String { rawValue }

    var instruction: String {
        switch self {
        case .short:
            return "Keep the sentence short and concise (approximately 8–12 words)."
        case .normal:
            return "Write a sentence of moderate length (approximately 18–25 words)."
        case .long:
            return "Write a longer, more detailed sentence (approximately 35–50 words)."
        }
    }
}

// MARK: - English Level

enum EnglishLevel: String, CaseIterable, Identifiable {
    case level1 = "レベル1"
    case level2 = "レベル2"
    case level3 = "レベル3"
    case level4 = "レベル4"
    case level5 = "レベル5"

    var id: String { rawValue }

    var ageDescription: String {
        switch self {
        case .level1: return "英検4・5級 / TOEIC 300以下"
        case .level2: return "英検3級 / TOEIC 300〜500"
        case .level3: return "英検準2級・2級 / TOEIC 500〜650"
        case .level4: return "英検準1級 / TOEIC 650〜800"
        case .level5: return "英検1級 / TOEIC 800以上"
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

    func generate() {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            englishResult = ""
            japaneseResult = ""
            isJapaneseVisible = false

            let systemPrompt = """
                You are an expert English educator creating example sentences for Japanese learners.
                Your task is to produce ONE sentence at the correct difficulty level plus its Japanese translation.

                CRITICAL REQUIREMENT — Target word/phrase usage:
                The user will provide one or more target words or phrases (e.g., "technology", "would like", or "technology, would like").
                - You MUST use ALL of the target words/phrases in the generated English sentence.
                - If the input contains katakana, hiragana, or spelling errors, interpret the intended English word/phrase and use the correct form.
                - If multiple words/phrases are provided (comma-separated), include ALL of them naturally in a single sentence.
                - The target words/phrases must be used meaningfully, not artificially inserted.

                Level: \(level.rawValue) (\(level.ageDescription))
                Level requirements:
                \(level.instruction)

                Sentence length: \(sentenceLength.rawValue)
                Length requirement: \(sentenceLength.instruction)

                Quality rules:
                - The English sentence must sound completely natural — as if a native speaker of the appropriate age group wrote it.
                - Strictly follow the vocabulary and grammar constraints for the level. The sentence should feel noticeably different from other levels.
                - The Japanese translation must be natural, fluent Japanese (自然な日本語). Avoid word-for-word translation. Express the meaning using idiomatic Japanese. Match the register of the English (casual or formal).
                """

            let userPrompt = """
                Target word(s)/phrase(s): "\(word)"
                Level: \(level.rawValue) (\(level.ageDescription))
                Sentence length: \(sentenceLength.rawValue)

                Generate an English sentence that includes ALL of the target word(s)/phrase(s) above, along with its Japanese translation.
                Remember: Every target word or phrase must appear in the sentence.
                """

            let session = LanguageModelSession(instructions: systemPrompt)

            do {
                let response = try await session.respond(
                    to: userPrompt,
                    generating: SentenceOutput.self
                )
                withAnimation(.spring(duration: 0.5)) {
                    englishResult = response.content.englishSentence
                    japaneseResult = response.content.japaneseTranslation
                }
            } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
                do {
                    let explanation = try await refusal.explanation
                    errorMessage = "[Refusal] \(explanation.content)"
                } catch {
                    errorMessage = "[Refusal] 詳細を取得できませんでした: \(error.localizedDescription)"
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
    var body: some View {
        if #available(macOS 26.0, *) {
            AvailabilityGateView()
        } else {
            UnavailableView(reason: "macOS 26.0 以降が必要です。")
        }
    }
}

// MARK: - Availability Gate View

@available(macOS 26.0, *)
struct AvailabilityGateView: View {
    var body: some View {
        switch SystemLanguageModel.default.availability {
        case .available:
            MainView()
        default:
            UnavailableView(reason: "Apple Intelligence のオンデバイス言語モデルがこのデバイスまたはシステムで利用できません。")
        }
    }
}

// MARK: - Unavailable View

struct UnavailableView: View {
    let reason: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Foundation Models を利用できません")
                .font(.title2)
                .fontWeight(.semibold)

            Text(reason)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main View

@available(macOS 26.0, *)
struct MainView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Input Group ──────────────────────────────────────────
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {

                        // Word field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("文章生成ワード")
                                .font(.subheadline).fontWeight(.bold)
                            TextField("例: technology, would like", text: $viewModel.word)
                                .textFieldStyle(.roundedBorder)
                            Text("単語や熟語を入力してください（複数可：カンマ区切り）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Sentence length picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("文章量")
                                .font(.subheadline).fontWeight(.bold)
                            Picker("文章量", selection: $viewModel.sentenceLength) {
                                ForEach(SentenceLength.allCases) { length in
                                    Text(length.rawValue).tag(length)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        // Level picker
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("レベル")
                                    .font(.subheadline).fontWeight(.bold)
                                Spacer()
                                Text(viewModel.level.ageDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Picker("レベル", selection: $viewModel.level) {
                                ForEach(EnglishLevel.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(4)
                }

                // ── Generate Button ──────────────────────────────────────
                Button(action: { viewModel.generate() }) {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView().controlSize(.small).padding(.trailing, 4)
                            Text("生成中...")
                        } else {
                            Image(systemName: "wand.and.sparkles")
                            Text("英文を生成")
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

                // ── Error Message ────────────────────────────────────────
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

                // ── Output Group ─────────────────────────────────────────
                if !viewModel.englishResult.isEmpty || !viewModel.japaneseResult.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {

                            // English sentence
                            if !viewModel.englishResult.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("English", systemImage: "e.circle.fill")
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                    Text(viewModel.englishResult)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            .blue.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                            }

                            // Japanese translation toggle button
                            if !viewModel.japaneseResult.isEmpty {
                                Button(action: {
                                    withAnimation(.spring(duration: 0.35)) {
                                        viewModel.isJapaneseVisible.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: viewModel.isJapaneseVisible ? "eye.slash.fill" : "eye.fill")
                                        Text(viewModel.isJapaneseVisible ? "日本語訳を隠す" : "日本語訳を表示")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }

                            // Japanese translation
                            if !viewModel.japaneseResult.isEmpty && viewModel.isJapaneseVisible {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("日本語訳", systemImage: "j.circle.fill")
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(.orange)
                                    Text(viewModel.japaneseResult)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            .orange.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(4)
                    } label: {
                        Label("出力", systemImage: "sparkles")
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
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
