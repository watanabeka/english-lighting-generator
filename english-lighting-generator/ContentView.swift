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
            return "Level 1 — Eiken Grade 4-5 / TOEIC under 300 (A1 beginner). Vocabulary: only the most basic everyday words. Grammar: present simple tense only. Structure: simple S+V+O; one clause only; 6-10 words."
        case .level2:
            return "Level 2 — Eiken Grade 3 / TOEIC 300-500 (A2 elementary). Vocabulary: common everyday words. Grammar: past simple, future, present continuous; basic connectors. Structure: 10-16 words."
        case .level3:
            return "Level 3 — Eiken Grade Pre-2 to 2 / TOEIC 500-650 (B1-B2 intermediate). Grammar: present perfect, passive voice, relative clauses, conditionals. Structure: 16-24 words."
        case .level4:
            return "Level 4 — Eiken Grade Pre-1 / TOEIC 650-800 (B2-C1 upper-intermediate). Vocabulary: academic and professional. Grammar: third conditional, participle phrases, advanced modals. Structure: 22-32 words."
        case .level5:
            return "Level 5 — Eiken Grade 1 / TOEIC 800+ (C1-C2 advanced). Vocabulary: sophisticated and precise. Grammar: subjunctive, inversion, cleft sentences. Style: C-level sophistication."
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
                let allWordsIncluded = inputWords.allSatisfy { !$0.isEmpty && sentenceLower.contains($0) }

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
    // Sky-blue light palette (matches reference image)
    static let skyTop      = Color(red: 0.50, green: 0.67, blue: 0.86)
    static let skyMid      = Color(red: 0.70, green: 0.83, blue: 0.93)
    static let skyBottom   = Color(red: 0.87, green: 0.93, blue: 0.98)

    // Card & text
    static let cardText    = Color(red: 0.18, green: 0.24, blue: 0.42)
    static let cardSub     = Color(red: 0.48, green: 0.56, blue: 0.72)

    // Button / accent
    static let btnBlue     = Color(red: 0.22, green: 0.40, blue: 0.72)
    static let btnBlueDark = Color(red: 0.15, green: 0.30, blue: 0.60)
}

// MARK: - Blue Segmented Picker

struct BlueSegmentedPicker<T: Hashable & Identifiable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options) { option in
                let isOn = selection == option
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = option }
                }) {
                    Text(label(option))
                        .font(.system(size: 12, weight: isOn ? .bold : .medium))
                        .foregroundStyle(isOn ? .white : Color(red: 0.30, green: 0.46, blue: 0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    isOn
                                        ? AnyShapeStyle(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color.clear)
                                )
                                .shadow(color: isOn ? Color.btnBlue.opacity(0.30) : .clear, radius: 5, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Color(red: 0.82, green: 0.89, blue: 0.97))
        )
    }
}

// MARK: - App Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            // Base sky gradient
            LinearGradient(
                colors: [.skyTop, .skyMid, .skyBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Central cloud/haze glow
            RadialGradient(
                colors: [Color.white.opacity(0.65), Color.white.opacity(0.10), .clear],
                center: UnitPoint(x: 0.70, y: 0.36),
                startRadius: 20,
                endRadius: 260
            )

            // Top-right soft highlight
            RadialGradient(
                colors: [Color.white.opacity(0.30), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 200
            )

            // Bottom ambient
            RadialGradient(
                colors: [Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.25), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glow Loading Bar (replaces robot mascot)

struct GlowLoadingBar: View {
    var subtitle: String
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            // Sweeping light bar
            GeometryReader { geo in
                let w = geo.size.width
                let streakW = w * 0.38
                let span = w + streakW

                ZStack {
                    // Track — navy tinted
                    Capsule()
                        .fill(Color.btnBlue.opacity(0.18))
                        .frame(width: w, height: 5)

                    // Sweep streak — dark navy
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.btnBlue.opacity(0.55),
                                    Color.btnBlueDark,
                                    Color.btnBlue.opacity(0.55),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: streakW, height: 5)
                        .shadow(color: Color.btnBlue.opacity(0.55), radius: 8, x: 0, y: 0)
                        .shadow(color: Color.btnBlueDark.opacity(0.35), radius: 16, x: 0, y: 0)
                        .offset(x: phase * span - span / 2)
                }
                .frame(width: w, height: 14, alignment: .center)
                .clipped()
            }
            .frame(height: 14)
            .padding(.horizontal, 44)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cardSub)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.55).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(LocalizationManager.self) private var L

    private var items: [(String, String, String)] {
        [
            ("house",             "house.fill",         L["tab.aiSentence"]),
            ("text.word.spacing", "text.word.spacing",  L["tab.quiz"]),
            ("chart.bar",         "chart.bar.fill",     L["tab.history"]),
            ("gearshape",         "gearshape.fill",     L["tab.settings"])
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
                            .font(.system(size: 20, weight: isOn ? .semibold : .regular))
                        Text(label)
                            .font(.system(size: 10, weight: isOn ? .semibold : .regular))
                    }
                    .foregroundStyle(isOn ? Color.white : Color.white.opacity(0.50))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
        .background(
            LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .leading, endPoint: .trailing)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.30))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var L = LocalizationManager.shared
    @State private var selectedTab: Int = 0
    @State private var prefillWord: String = ""
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer: Bool = false
    @State private var showDisclaimer: Bool = false

    var body: some View {
        ZStack {
            AppBackground()

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
                    SettingsView(showDisclaimer: $showDisclaimer)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
                .environment(L)
        }
        .overlay {
            if showDisclaimer {
                DisclaimerDialog(isPresented: $showDisclaimer)
                    .environment(L)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.spring(duration: 0.35), value: showDisclaimer)
        .environment(L)
        .onAppear {
            if !hasSeenDisclaimer {
                hasSeenDisclaimer = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showDisclaimer = true
                }
            }
        }
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
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 90, height: 90)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.20))
            }
            VStack(spacing: 10) {
                Text(L["unavailable.title"])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.cardText)
                Text(L[reasonKey])
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.cardSub)
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
    @State private var showSubscriptionDialog = false
    @Binding var prefillWord: String

    private var store: StoreManager { StoreManager.shared }

    private func generateWithLimitCheck() {
        if !store.isPremium && todayTotalUsage(modelContext: modelContext) >= dailyFreeLimit {
            showSubscriptionDialog = true
            return
        }
        viewModel.generate(modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            if viewModel.isGenerating {
                // ── Loading ──────────────────────────────────────────────
                GlowLoadingBar(subtitle: L["button.generating"] + "...")
                    .transition(.opacity)

            } else if !viewModel.englishResult.isEmpty {
                // ── Result (vertically centred, scrollable) ──────────────
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 20) {
                            if !viewModel.errorMessage.isEmpty {
                                errorBanner.padding(.horizontal, 16)
                            }
                            Spacer(minLength: 0)
                            outputCard.padding(.horizontal, 16)
                            actionButtons.padding(.horizontal, 16)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))

            } else {
                // ── Input (vertically centred, scrollable) ────────────────
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 14) {
                            if !viewModel.errorMessage.isEmpty {
                                errorBanner.padding(.horizontal, 16)
                            }
                            Spacer(minLength: 0)
                            inputCard.padding(.horizontal, 16)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.30), value: viewModel.isGenerating)
        .animation(.spring(duration: 0.45), value: viewModel.englishResult.isEmpty)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        .overlay {
            if showSubscriptionDialog {
                SubscriptionDialog(isPresented: $showSubscriptionDialog)
                    .environment(L)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.spring(duration: 0.35), value: showSubscriptionDialog)
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { showSubscriptionDialog = false }
        }
        .onChange(of: prefillWord) { _, newWord in
            guard !newWord.isEmpty else { return }
            viewModel.word = newWord
            viewModel.reset()
            prefillWord = ""
        }
    }

    // MARK: Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            Text(L["output.challenge"])
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cardSub)

            // Word field
            VStack(alignment: .leading, spacing: 6) {
                Text(L["input.wordLabel"])
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cardSub)
                TextField(L["input.wordPlaceholder"], text: $viewModel.word)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.cardText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.96))
                    )
            }

            // Level picker
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L["input.levelLabel"])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.cardSub)
                    Spacer()
                    Text(L[viewModel.level.descriptionKey])
                        .font(.system(size: 11))
                        .foregroundStyle(Color.cardSub)
                }
                BlueSegmentedPicker(
                    options: EnglishLevel.allCases,
                    label: { L[$0.rawValue] },
                    selection: $viewModel.level
                )
            }

            // Length picker
            VStack(alignment: .leading, spacing: 6) {
                Text(L["input.sentenceLengthLabel"])
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cardSub)
                BlueSegmentedPicker(
                    options: SentenceLength.allCases,
                    label: { L[$0.rawValue] },
                    selection: $viewModel.sentenceLength
                )
            }

            // Generate button
            generateButton
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.20), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    private var generateButton: some View {
        Button(action: { generateWithLimitCheck() }) {
            Text(L["button.generate"])
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.btnBlue, .btnBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.btnBlue.opacity(0.45), radius: 12, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1.0)
    }

    // MARK: Error Banner

    private var errorBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.25))
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.15))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.82))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: Output Card

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Label(L["output.englishLabel"], systemImage: "globe")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.btnBlue)
                Text(viewModel.englishResult)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.cardText)
                    .textSelection(.enabled)
            }
            .padding(20)

            Divider().padding(.horizontal, 16)

            if viewModel.isTranslationVisible {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L["output.japaneseLabel"], systemImage: "character.bubble")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.80, green: 0.46, blue: 0.12))
                    Text(viewModel.translationResult)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.cardText)
                        .textSelection(.enabled)
                }
                .padding(20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button(action: {
                    withAnimation(.spring(duration: 0.3)) { viewModel.isTranslationVisible = true }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye").font(.system(size: 13))
                        Text(L["button.showJapanese"]).font(.subheadline).fontWeight(.medium)
                    }
                    .foregroundStyle(Color.btnBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.btnBlue.opacity(0.07))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.18), radius: 18, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .animation(.spring(duration: 0.3), value: viewModel.isTranslationVisible)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: { viewModel.reset() }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle").font(.system(size: 13, weight: .semibold))
                    Text(L["button.done"]).font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.btnBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.80))
                        .shadow(color: Color.btnBlue.opacity(0.15), radius: 8, y: 3)
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                viewModel.reset()
                generateWithLimitCheck()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 13, weight: .semibold))
                    Text(L["button.regenerateSentence"]).font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color.btnBlue.opacity(0.38), radius: 10, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Disclaimer Dialog

struct DisclaimerDialog: View {
    @Binding var isPresented: Bool
    @Environment(LocalizationManager.self) private var L

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Icon + Title
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.btnBlue.opacity(0.15), .btnBlueDark.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 68, height: 68)
                        Image(systemName: "shield.lefthalf.filled.slash")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .top, endPoint: .bottom))
                    }
                    Text(L["disclaimer.title"])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.cardText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.bottom, 18)

                Divider().padding(.horizontal, 24)

                // Body
                Text(L["disclaimer.body"])
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cardText.opacity(0.82))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                }) {
                    Text(L["disclaimer.close"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.btnBlue.opacity(0.35), radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.97))
                    .shadow(color: Color(red: 0.20, green: 0.35, blue: 0.65).opacity(0.28), radius: 32, y: 12)
            )
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
