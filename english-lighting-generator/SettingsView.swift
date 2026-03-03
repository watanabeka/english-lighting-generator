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
                // App Version
                Section(L["settings.appVersion"]) {
                    LabeledContent(L["settings.appVersion"], value: appVersion)
                }

                // Review
                Section(L["settings.review"]) {
                    Button(L["settings.reviewApp"]) {
                        // Opens App Store review dialog
                    }
                }

                // Display Language
                Section(L["settings.displayLanguage"]) {
                    ForEach(SupportedLanguage.all) { language in
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            if L.currentLanguage.id == language.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            L.setLanguage(language)
                        }
                    }
                }
            }
            .navigationTitle(L["tab.settings"])
        }
    }
}

#Preview {
    SettingsView()
        .environment(LocalizationManager.shared)
}
