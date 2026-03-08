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
                let response = try await session.respond(
                    to: "Target: \"\(word)\"",
                    generating: SentenceOutput.self
                )
                let content = response.content

                let inputWords = word.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                let sentenceLower = content.englishSentence.lowercased()
                let allWordsIncluded = inputWords.allSatisfy { inputWord in
                    !inputWord.isEmpty && sentenceLower.contains(inputWord)
                }

                guard allWordsIncluded else {
                    generate(modelContext: modelContext)
                    return
                }

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

// MARK: - Design System

extension Color {
    static let appNavyDeep  = Color(red: 0.052, green: 0.076, blue: 0.258)
    static let appNavyMid   = Color(red: 0.088, green: 0.126, blue: 0.368)
    static let appTabBg     = Color(red: 0.036, green: 0.054, blue: 0.188)
    static let appBlue      = Color(red: 0.260, green: 0.440, blue: 0.940)
    static let appBlueDark  = Color(red: 0.180, green: 0.350, blue: 0.840)
    static let appCardText  = Color(red: 0.130, green: 0.130, blue: 0.240)
    static let appCardSub   = Color(red: 0.440, green: 0.460, blue: 0.580)
}

// MARK: - App Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.appNavyDeep, .appNavyMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stars / particle field
            StarfieldView()

            // Top-left corner ambient glow
            RadialGradient(
                colors: [Color.white.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 320
            )

            // Diagonal light beam
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.055),
                                Color.appBlue.opacity(0.09),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geo.size.width * 2, height: 240)
                    .rotationEffect(.degrees(-28))
                    .offset(y: geo.size.height * 0.22)
                    .blur(radius: 18)
            }

            // Bottom center glow
            RadialGradient(
                colors: [Color.appBlue.opacity(0.38), .clear],
                center: UnitPoint(x: 0.5, y: 1.1),
                startRadius: 10,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Starfield

private struct StarfieldView: View {
    private struct Star: Identifiable {
        let id: Int
        let x, y, size: CGFloat
        let opacity: Double
    }

    private let stars: [Star] = (0..<55).map { i in
        Star(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 1.0...2.8),
            opacity: Double.random(in: 0.12...0.50)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { s in
                Circle()
                    .fill(Color.white.opacity(s.opacity))
                    .frame(width: s.size, height: s.size)
                    .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
            }
        }
    }
}

// MARK: - Robot Mascot

struct RobotMascotView: View {
    var size: CGFloat = 88
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.appBlue.opacity(0.45), lineWidth: 1.5)
                .frame(width: size * 1.95, height: size * 1.95)
                .scaleEffect(pulse ? 1.14 : 1.0)
                .opacity(pulse ? 0.18 : 0.50)
                .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: pulse)

            // Inner glow
            Circle()
                .fill(Color.appBlue.opacity(0.20))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 20)
                .scaleEffect(pulse ? 1.10 : 0.94)
                .animation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true), value: pulse)

            // Antenna
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .shadow(color: Color.appBlue, radius: 6)
                Rectangle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 2, height: size * 0.26)
            }
            .offset(y: -(size * 0.48 + size * 0.20))

            // Head
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.09)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.24)
                            .stroke(Color.white.opacity(0.44), lineWidth: 1.5)
                    )
                    .frame(width: size, height: size * 0.96)

                VStack(spacing: size * 0.10) {
                    HStack(spacing: size * 0.22) {
                        robotEye
                        robotEye
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<4) { _ in
                            Capsule()
                                .fill(Color.white.opacity(0.72))
                                .frame(width: size * 0.085, height: size * 0.058)
                        }
                    }
                }
            }
        }
        .onAppear { pulse = true }
    }

    private var robotEye: some View {
        ZStack {
            Circle().fill(Color.white)
                .frame(width: size * 0.21, height: size * 0.21)
            Circle().fill(Color.appBlue)
                .frame(width: size * 0.12, height: size * 0.12)
            Circle().fill(Color.white.opacity(0.85))
                .frame(width: size * 0.055, height: size * 0.055)
                .offset(x: -size * 0.032, y: -size * 0.032)
        }
    }
}

// MARK: - AI Generating View

struct AIGeneratingView: View {
    var headline: String
    var subtitle: String
    @State private var animated = false

    var body: some View {
        VStack(spacing: 0) {
            // Title at top
            Text(headline)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer()

            RobotMascotView(size: 90)

            Spacer()

            VStack(spacing: 14) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.80), Color.appBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (animated ? 0.80 : 0.22), height: 5)
                            .animation(
                                .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                                value: animated
                            )
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 48)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { animated = true }
    }
}

// MARK: - App Header

struct AppHeaderView: View {
    var title: String = "Hello!"

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            HStack(spacing: 18) {
                Image(systemName: "bell")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white.opacity(0.72))
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(LocalizationManager.self) private var L

    private var items: [(String, String, String)] {
        [
            ("house",           "house.fill",         L["tab.aiSentence"]),
            ("text.word.spacing", "text.word.spacing", L["tab.quiz"]),
            ("chart.bar",       "chart.bar.fill",     L["tab.history"]),
            ("gearshape",       "gearshape.fill",     L["tab.settings"])
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, activeIcon, label) = items[i]
                let isOn = selectedTab == i
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = i }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isOn ? activeIcon : icon)
                            .font(.system(size: 21, weight: isOn ? .semibold : .regular))
                        Text(label)
                            .font(.system(size: 10, weight: isOn ? .semibold : .regular))
                    }
                    .foregroundStyle(isOn ? Color.white : Color.white.opacity(0.36))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
        .background(Color.appTabBg)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var L = LocalizationManager.shared
    @State private var selectedTab: Int = 0
    @State private var prefillWord: String = ""

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                AppHeaderView()

                ZStack {
                    if selectedTab == 0 {
                        if #available(macOS 26.0, *) {
                            AvailabilityGateView(prefillWord: $prefillWord)
                        } else {
                            UnavailableView(reasonKey: "unavailable.osRequired")
                        }
                    } else if selectedTab == 1 {
                        QuizView()
                    } else if selectedTab == 2 {
                        AnalyticsView(onSelectWord: { word in
                            prefillWord = word
                            selectedTab = 0
                        })
                    } else {
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
                .environment(L)
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
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 90, height: 90)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.orange)
            }
            VStack(spacing: 10) {
                Text(L["unavailable.title"])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(L[reasonKey])
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.60))
                    .font(.subheadline)
                    .padding(.horizontal, 32)
            }
        }
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
        ZStack {
            if viewModel.isGenerating && !isInputVisible {
                AIGeneratingView(
                    headline: L["button.generating"],
                    subtitle: "AIが英文を生成しています..."
                )
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        if isInputVisible {
                            screenTitle
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if isInputVisible {
                            inputCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !viewModel.errorMessage.isEmpty {
                            errorCard
                        }

                        if !viewModel.englishResult.isEmpty {
                            outputCard
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            actionButtons
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 24)
                    .animation(.spring(duration: 0.45), value: isInputVisible)
                    .animation(.spring(duration: 0.45), value: viewModel.englishResult.isEmpty)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
                }
            }
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

    // MARK: Screen Title

    private var screenTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L["tab.aiSentence"])
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("単語を入力してAIが英文を生成します")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.58))
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: Input Card

    private var inputCard: some View {
        VStack(spacing: 0) {
            // Word
            cardRow {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L["input.wordLabel"])
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appCardSub)
                    TextField(L["input.wordPlaceholder"], text: $viewModel.word)
                        .font(.body)
                        .foregroundStyle(Color.appCardText)
                }
            }

            cardDivider

            // Length
            cardRow {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L["input.sentenceLengthLabel"])
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appCardSub)
                    Picker("", selection: $viewModel.sentenceLength) {
                        ForEach(SentenceLength.allCases) { l in
                            Text(L[l.rawValue]).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            cardDivider

            // Level
            cardRow {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L["input.levelLabel"])
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appCardSub)
                        Spacer()
                        Text(L[viewModel.level.descriptionKey])
                            .font(.caption2)
                            .foregroundStyle(Color.appCardSub)
                    }
                    Picker("", selection: $viewModel.level) {
                        ForEach(EnglishLevel.allCases) { l in
                            Text(L[l.rawValue]).tag(l)
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
        Button(action: { viewModel.generate(modelContext: modelContext) }) {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Image(systemName: viewModel.isGenerating ? "" : "wand.and.sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text(viewModel.isGenerating ? L["button.generating"] : L["button.generate"])
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
        .disabled(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isGenerating)
        .opacity(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1.0)
    }

    // MARK: Error Card

    private var errorCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
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

    // MARK: Output Card

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // English result
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(Color.appBlue)
                    Text(L["output.englishLabel"])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appBlue)
                }
                Text(viewModel.englishResult)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appCardText)
                    .textSelection(.enabled)
            }
            .padding(20)

            if viewModel.isTranslationVisible {
                Rectangle()
                    .fill(Color.appCardSub.opacity(0.15))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "character.bubble")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                        Text(L["output.japaneseLabel"])
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.orange)
                    }
                    Text(viewModel.translationResult)
                        .font(.body)
                        .foregroundStyle(Color.appCardText)
                        .textSelection(.enabled)
                }
                .padding(20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button(action: {
                    withAnimation(.spring(duration: 0.35)) {
                        viewModel.isTranslationVisible = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 14))
                        Text(L["button.showJapanese"])
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.08))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
        .padding(.horizontal, 16)
        .animation(.spring(duration: 0.35), value: viewModel.isTranslationVisible)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Next / regenerate
            Button(action: {
                viewModel.reset()
                viewModel.generate(modelContext: modelContext)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("新しい英文を生成")
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

            // Done / save
            Button(action: {
                viewModel.reset()
                withAnimation(.spring(duration: 0.45)) { isInputVisible = true }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 15, weight: .semibold))
                    Text("完了・覚えた")
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

// MARK: - Reusable Subviews (legacy support)

struct FormSection<Content: View>: View {
    let title: String
    var badge: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appCardSub)
                if let badge {
                    Spacer()
                    Text(badge)
                        .font(.caption2)
                        .foregroundStyle(Color.appCardSub)
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
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: systemImage)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .foregroundStyle(Color.appCardText)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
