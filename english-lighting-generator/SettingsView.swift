//
//  SettingsView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var L
    @Binding var showDisclaimer: Bool

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Disclaimer card
                settingsCard {
                    Button(action: { showDisclaimer = true }) {
                        settingsRow(icon: "shield.lefthalf.filled.slash", iconColor: Color.btnBlue, title: L["settings.disclaimer"]) {
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.cardSub)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // App info card
                settingsCard {
                    settingsRow(icon: "info.circle.fill", iconColor: Color.btnBlue, title: L["settings.appVersion"]) {
                        Text(appVersion).font(.subheadline).foregroundStyle(Color.cardSub)
                    }
                }

                // Review card
                settingsCard {
                    Button(action: {}) {
                        settingsRow(icon: "star.fill", iconColor: Color(red: 0.99, green: 0.75, blue: 0.18), title: L["settings.reviewApp"]) {
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.cardSub)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Language card
                VStack(alignment: .leading, spacing: 8) {
                    Text(L["settings.displayLanguage"])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cardSub)
                        .padding(.horizontal, 4)

                    settingsCard {
                        VStack(spacing: 0) {
                            ForEach(Array(SupportedLanguage.all.enumerated()), id: \.element.id) { index, language in
                                Button(action: { L.setLanguage(language) }) {
                                    settingsRow(icon: languageIcon(for: language.id), iconColor: Color.btnBlue.opacity(0.80), title: language.displayName) {
                                        if L.currentLanguage.id == language.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(Color.btnBlue)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                if index < SupportedLanguage.all.count - 1 {
                                    Divider().padding(.horizontal, 14)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Card Container

    private func settingsCard<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.82))
                    .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.16), radius: 16, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )
    }

    // MARK: Settings Row

    private func settingsRow<T: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(iconColor)
            }
            Text(title).font(.body).foregroundStyle(Color.cardText)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

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
        SettingsView(showDisclaimer: .constant(false)).environment(LocalizationManager.shared)
    }
}
