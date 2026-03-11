//
//  GeneratorView.swift
//  english-lighting-generator
//
//  Main view for the English sentence generation feature.
//

import SwiftData
import SwiftUI

@available(macOS 26.0, *)
struct GeneratorView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GeneratorViewModel()
    @State private var showSubscriptionDialog = false
    @Binding var prefillWord: String

    private var store: StoreManager { StoreManager.shared }

    // MARK: - Limit Check

    private func generateWithLimitCheck() {
        if !store.isPremium && todayTotalUsage(modelContext: modelContext) >= dailyFreeLimit {
            showSubscriptionDialog = true
            return
        }
        viewModel.generate(modelContext: modelContext)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isGenerating {
                GlowLoadingBar(subtitle: L["button.generating"] + "...")
                    .transition(.opacity)

            } else if !viewModel.englishResult.isEmpty {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 20) {
                            if !viewModel.errorMessage.isEmpty {
                                ErrorBannerView(message: viewModel.errorMessage)
                                    .padding(.horizontal, 16)
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
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 14) {
                            if !viewModel.errorMessage.isEmpty {
                                ErrorBannerView(message: viewModel.errorMessage)
                                    .padding(.horizontal, 16)
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

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L["output.challenge"])
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cardSub)

            VStack(alignment: .leading, spacing: 6) {
                Text(L["input.wordLabel"])
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cardSub)
                TextField(L["input.wordPlaceholder"], text: $viewModel.word)
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

            generateButton
            DailyLimitLabel()
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
                        .fill(LinearGradient(
                            colors: [.btnBlue, .btnBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .shadow(color: Color.btnBlue.opacity(0.45), radius: 12, x: 0, y: 5)
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(viewModel.word.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1.0)
    }

    // MARK: - Output Card

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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: { viewModel.reset() }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle").font(.system(size: 13, weight: .semibold))
                    Text(L["button.done"]).font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.btnBlue)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.80))
                        .shadow(color: Color.btnBlue.opacity(0.15), radius: 8, y: 3)
                )
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.reset(); generateWithLimitCheck() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 13, weight: .semibold))
                    Text(L["button.regenerateSentence"]).font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
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
