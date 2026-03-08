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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Screen title
                VStack(alignment: .leading, spacing: 6) {
                    Text(L["tab.settings"])
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("アプリの設定")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.58))
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // App version card
                settingsCard {
                    settingsRow(
                        icon: "info.circle.fill",
                        iconColor: Color.appBlue,
                        title: L["settings.appVersion"],
                        trailing: {
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundStyle(Color.appCardSub)
                        }
                    )
                }
                .padding(.horizontal, 16)

                // Review card
                settingsCard {
                    Button(action: {}) {
                        settingsRow(
                            icon: "star.fill",
                            iconColor: Color(red: 0.99, green: 0.75, blue: 0.18),
                            title: L["settings.reviewApp"],
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.appCardSub)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // Language card
                VStack(alignment: .leading, spacing: 10) {
                    Text(L["settings.displayLanguage"])
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white.opacity(0.60))
                        .padding(.horizontal, 20)

                    settingsCard {
                        VStack(spacing: 0) {
                            ForEach(Array(SupportedLanguage.all.enumerated()), id: \.element.id) { index, language in
                                Button(action: { L.setLanguage(language) }) {
                                    settingsRow(
                                        icon: languageIcon(for: language.id),
                                        iconColor: Color.appBlue.opacity(0.80),
                                        title: language.displayName,
                                        trailing: {
                                            if L.currentLanguage.id == language.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(Color.appBlue)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)

                                if index < SupportedLanguage.all.count - 1 {
                                    Rectangle()
                                        .fill(Color.appCardSub.opacity(0.12))
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Card Container

    private func settingsCard<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
    }

    // MARK: Settings Row

    private func settingsRow<T: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder trailing: () -> T
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(Color.appCardText)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Language Icon

    private func languageIcon(for id: String) -> String {
        switch id {
        case "ja":     return "j.circle.fill"
        case "pt-BR":  return "p.circle.fill"
        case "es-419": return "e.circle.fill"
        case "id":     return "i.circle.fill"
        case "vi":     return "v.circle.fill"
        case "ar":     return "a.circle.fill"
        case "fr":     return "f.circle.fill"
        default:       return "globe"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        SettingsView()
            .environment(LocalizationManager.shared)
    }
}
