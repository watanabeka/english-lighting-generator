//
//  ContentView.swift
//  english-lighting-generator
//
//  Root view: hosts the custom tab bar and switches between the four feature tabs.
//  Also manages the first-launch disclaimer presentation.
//

import SwiftUI

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
                switch selectedTab {
                case 0:
                    if #available(macOS 26.0, *) {
                        AvailabilityGateView(prefillWord: $prefillWord)
                    } else {
                        UnavailableView(reasonKey: "unavailable.osRequired")
                    }
                case 1:
                    QuizView()
                case 2:
                    AnalyticsView(onSelectWord: { word in
                        prefillWord = word
                        selectedTab = 0
                    })
                default:
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
            guard !hasSeenDisclaimer else { return }
            hasSeenDisclaimer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showDisclaimer = true
            }
        }
    }
}

// MARK: - Availability Gate

@available(macOS 26.0, *)
private struct AvailabilityGateView: View {
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

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
