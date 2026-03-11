//
//  ReviewPromptDialog.swift
//  english-lighting-generator
//
//  Modal shown after the user's 3rd quiz generation to prompt an App Store review.
//

import SwiftUI

struct ReviewPromptDialog: View {
    @Binding var isPresented: Bool
    @Environment(LocalizationManager.self) private var L
    @Environment(\.openURL) private var openURL

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.99, green: 0.85, blue: 0.30).opacity(0.20),
                                         Color(red: 0.99, green: 0.75, blue: 0.18).opacity(0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 68, height: 68)
                        Image(systemName: "star.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color(red: 0.99, green: 0.75, blue: 0.18))
                    }
                    Text(L["review.title"])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.cardText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.bottom, 18)

                Divider().padding(.horizontal, 24)

                Text(L["review.body"])
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cardText.opacity(0.82))
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                Button(action: {
                    openReview()
                    UserDefaults.standard.set(true, forKey: "hasRespondedToReview")
                    withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                }) {
                    Text(L["review.writeReview"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.btnBlue, .btnBlueDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.btnBlue.opacity(0.35), radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasRespondedToReview")
                    withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                }) {
                    Text(L["review.notNow"])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.cardSub)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.97))
                    .shadow(color: Color(red: 0.20, green: 0.35, blue: 0.65).opacity(0.28), radius: 32, y: 12)
            )
            .padding(.horizontal, 28)
        }
    }

    private func openReview() {
        #if os(iOS)
        guard let url = URL(string: AppConstants.appStoreReviewURL) else { return }
        #else
        guard let url = URL(string: AppConstants.macAppStoreReviewURL) else { return }
        #endif
        openURL(url)
    }
}
