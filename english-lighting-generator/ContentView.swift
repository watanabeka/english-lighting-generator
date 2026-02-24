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

// MARK: - English Level

enum EnglishLevel: String, CaseIterable, Identifiable {
    case beginner          = "初級(A1-A2)"
    case lowerIntermediate = "初中級(B1)"
    case intermediate      = "中級(B2)"
    case advanced          = "上級(C1-C2)"

    var id: String { rawValue }

    var instruction: String {
        switch self {
        case .beginner:
            return """
                A1-A2 level.
                Vocabulary: everyday basic words only — family, food, time, places, common verbs (go, eat, have, like, want, see, use).
                Grammar: present simple tense only; "can" for ability is fine.
                Structure: simple Subject + Verb + Object/Complement; one clause only.
                AVOID: past tense, future tense, modal verbs (except "can"), relative clauses, idioms, phrasal verbs, or any word a complete beginner would not know.
                Example style: "I use a computer at work every day."
                """
        case .lowerIntermediate:
            return """
                B1 level.
                Vocabulary: common everyday words plus some topic-specific vocabulary; include one or two words slightly above basic level.
                Grammar: past simple, future (will / going to), present continuous, modals (should, might, could), basic conditionals (if + present + will).
                Structure: compound sentences using connectors (because, so, but, when, after, although).
                Common phrasal verbs and set expressions are encouraged.
                AVOID: relative clauses, present perfect, passive voice, or academic vocabulary.
                Example style: "She decided to study abroad because she wanted to improve her English skills."
                """
        case .intermediate:
            return """
                B2 level.
                Vocabulary: wide-ranging; include at least one formal or academic word that a learner would want to study.
                Grammar: present perfect, past perfect, passive voice, relative clauses (who/which/that), second conditional (if + past + would), reported speech.
                Structure: complex sentences with two or more subordinate clauses that show clear logical relationships.
                Example style: "The report, which was published last year, has significantly influenced the policies that governments are now implementing."
                """
        case .advanced:
            return """
                C1-C2 level.
                Vocabulary: sophisticated and precise — naturally use words such as "nuanced", "ephemeral", "juxtapose", "ostensibly", "precipitate", "reconcile", or equivalents appropriate to the target word's domain.
                Grammar: subjunctive (were it not for…), inversion (Rarely has…, Not only did…, Had I known…), participle clauses (Having considered…, Confronted with…), cleft sentences (It is … that …).
                Style: varied sentence rhythm and rhetorical elegance — the kind of sentence found in quality journalism, academic writing, or literary non-fiction.
                AVOID: simple present/past only sentences; every sentence must demonstrate clear C-level grammar.
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
    var wordCount: Double = 15
    var level: EnglishLevel = .beginner
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

                Level: \(level.rawValue)
                Level requirements:
                \(level.instruction)

                Quality rules:
                - The English sentence must sound completely natural — as if a fluent native speaker wrote it.
                - Strictly follow the vocabulary and grammar constraints for the level. The sentence should feel noticeably different from other levels.
                - The Japanese translation must be natural, fluent Japanese (自然な日本語). Avoid word-for-word translation. Express the meaning using idiomatic Japanese. Match the register of the English (casual or formal).
                """

            let userPrompt = """
                Target word: "\(word)"
                Required length: approximately \(Int(wordCount)) words
                Level: \(level.rawValue)

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
                // Guided generation lets us catch refusals and ask the model why
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
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("English Sentence Generator")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 16)

            Divider()

            // ── Scrollable Body ──────────────────────────────────────────────
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
                            }

                            Divider()

                            // Word count slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label("単語数", systemImage: "slider.horizontal.3")
                                        .font(.subheadline).fontWeight(.medium)
                                    Spacer()
                                    Text("\(Int(viewModel.wordCount)) 語")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: $viewModel.wordCount, in: 5...40, step: 1)
                                    .tint(.blue)
                                HStack {
                                    Text("5").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("40").font(.caption).foregroundStyle(.secondary)
                                }
                            }

                            Divider()

                            // Level picker
                            VStack(alignment: .leading, spacing: 6) {
                                Label("英語レベル", systemImage: "chart.bar.fill")
                                    .font(.subheadline).fontWeight(.medium)
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
                        Label("入力", systemImage: "pencil.circle.fill")
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
