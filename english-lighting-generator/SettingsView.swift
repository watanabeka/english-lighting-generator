//
//  SettingsView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var L

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                appVersionSection
                reviewSection
                languageSection
            }
        }
    }

    private var appVersionSection: some View {
        Section(L["settings.appVersion"]) {
            LabeledContent(L["settings.appVersion"], value: appVersion)
        }
    }

    private var reviewSection: some View {
        Section(L["settings.review"]) {
            Button(L["settings.reviewApp"]) {
                // Opens App Store review dialog
            }
        }
    }

    private var languageSection: some View {
        Section(L["settings.displayLanguage"]) {
            ForEach(SupportedLanguage.all) { (language: SupportedLanguage) in
                Button(action: {
                    L.setLanguage(language)
                }) {
                    HStack {
                        Text(language.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if L.currentLanguage.id == language.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(LocalizationManager.shared)
}
