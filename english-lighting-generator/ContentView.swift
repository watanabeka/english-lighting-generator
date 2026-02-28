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
        case .level1: return "ネイティブ 3〜4歳相当"
        case .level2: return "ネイティブ 6歳相当"
        case .level3: return "ネイティブ 10歳相当"
        case .level4: return "ネイティブ 15歳相当"
        case .level5: return "ネイティブ 成人相当"
        }
    }

    var instruction: String {
        switch self {
        case .level1:
            return """
                Level 1 — Native English speaker age 3–4 equivalent.
                Vocabulary: only the simplest, most common words a very young child would know (mommy, daddy, dog, cat, ball, big, little, eat, go, want, like, see, play, happy, good, more, here, yes, please).
                Grammar: very short sentences, present simple only; "I want…" / "I like…" patterns; no complex clauses.
                Structure: 5–8 words; single clause only.
                AVOID: any word a 3-year-old would not know, past tense, modals, relative clauses, or multi-clause sentences.
                Example style: "I like to play with my dog."
                """
        case .level2:
            return """
                Level 2 — Native English speaker age 6 equivalent.
                Vocabulary: words a first-grader knows — school, family, animals, colours, numbers, simple actions, short adjectives (happy, funny, fast, big, small).
                Grammar: simple past, present continuous, "will" for future; basic connectors (and, but, because, so).
                Structure: 8–14 words; may have two short clauses.
                AVOID: idioms, formal vocabulary, relative clauses, conditionals, passive voice.
                Example style: "My cat jumped on the table and knocked over the glass."
                """
        case .level3:
            return """
                Level 3 — Native English speaker age 10 equivalent.
                Vocabulary: common words plus topic-specific words a 4th–5th grader encounters (experiment, environment, competition, surprised, population, communicate).
                Grammar: past perfect, present perfect, relative clauses (who/which/that), modals (should, must, might), simple passive voice.
                Structure: 14–22 words; compound or complex sentences with clear logical relationships.
                AVOID: highly academic vocabulary, subjunctive mood, inversion, or sophisticated rhetorical devices.
                Example style: "The scientist who discovered the new element said it could change the way we produce energy."
                """
        case .level4:
            return """
                Level 4 — Native English speaker age 15 equivalent.
                Vocabulary: high school level — academic and abstract words (analyse, significant, consequence, perspective, contribute, demonstrate, approach, establish).
                Grammar: second/third conditionals, reported speech, passive in various tenses, participle phrases (having done, given that).
                Structure: 20–30 words; sophisticated multi-clause sentences with clear logical flow.
                AVOID: extremely advanced rhetorical devices such as inversion or subjunctive mood.
                Example style: "If stricter environmental regulations had been implemented earlier, many of the ecological consequences we are now facing could have been prevented."
                """
        case .level5:
            return """
                Level 5 — Educated native adult speaker equivalent.
                Vocabulary: sophisticated and precise — naturally use words such as "nuanced", "ephemeral", "juxtapose", "ostensibly", "precipitate", "reconcile", "ubiquitous", or equivalents appropriate to the target word's domain.
                Grammar: subjunctive mood (were it not for…), inversion (Rarely has…, Not only did…, Had I known…), participle clauses (Having considered…, Confronted with…), cleft sentences (It is … that …).
                Style: varied sentence rhythm and rhetorical elegance — quality journalism, academic writing, or literary non-fiction level.
                AVOID: simple or predictable structures; every sentence must demonstrate clear adult-level linguistic sophistication.
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

    func generate() {
        Task { @MainActor in
            isGenerating = true
            errorMessage = ""
            englishResult = ""
            japaneseResult = ""

            let systemPrompt = """
                You are an expert English educator creating example sentences for Japanese learners.
                Your task is to produce ONE sentence at the correct difficulty level plus its Japanese translation.

                IMPORTANT — Word input normalization:
                The target word may be written in Japanese katakana or hiragana (e.g., "コンピュータ" → "computer", "ランゲージ" → "language"), or may contain spelling errors (e.g., "languagi" → "language", "tecnology" → "technology").
                Always identify the correct English word the user intended and use that correctly spelled English word in the sentence.

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
                Target word: "\(word)"
                Level: \(level.rawValue) (\(level.ageDescription))
                Sentence length: \(sentenceLength.rawValue)

                Write the English sentence and its Japanese translation now.
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
                            Label("目標単語", systemImage: "character.cursor.ibeam")
                                .font(.subheadline).fontWeight(.medium)
                            TextField("例: technology", text: $viewModel.word)
                                .textFieldStyle(.roundedBorder)
                            Text("カタカナや綴りのミスはAIが自動補正します")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Sentence length picker
                        VStack(alignment: .leading, spacing: 6) {
                            Label("文章量", systemImage: "text.alignleft")
                                .font(.subheadline).fontWeight(.medium)
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
                                Label("レベル", systemImage: "chart.bar.fill")
                                    .font(.subheadline).fontWeight(.medium)
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
                } label: {
                    Label("文章生成ワード", systemImage: "pencil.circle.fill")
                        .font(.headline)
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

                            // Japanese translation
                            if !viewModel.japaneseResult.isEmpty {
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
            .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
