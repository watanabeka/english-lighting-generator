//
//  SubscriptionDialog.swift
//  english-lighting-generator
//
//  Created on 2026/03/10.
//

import SwiftUI

// MARK: - Subscription Dialog (shown when daily limit reached)

struct SubscriptionDialog: View {
    @Binding var isPresented: Bool
    @Environment(LocalizationManager.self) private var L
    private var store = StoreManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Icon + Title
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.30).opacity(0.25),
                                         Color(red: 1.0, green: 0.65, blue: 0.10).opacity(0.12)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 68, height: 68)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.18),
                                         Color(red: 0.90, green: 0.55, blue: 0.08)],
                                startPoint: .top, endPoint: .bottom))
                    }
                    Text(L["subscription.title"])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.cardText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.bottom, 18)

                Divider().padding(.horizontal, 24)

                // Body
                Text(L["subscription.body"])
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cardText.opacity(0.82))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                // Price
                if let product = store.product {
                    Text(product.displayPrice + " / " + L["subscription.period"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.cardText)
                        .padding(.bottom, 16)
                }

                // Subscribe button
                Button(action: {
                    Task { await store.purchase() }
                }) {
                    Text(L["subscription.subscribe"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.75, blue: 0.18),
                                             Color(red: 0.90, green: 0.55, blue: 0.08)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.10).opacity(0.40), radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
                }) {
                    Text(L["subscription.close"])
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
}

// MARK: - Review Prompt Dialog (shown on 3rd quiz generation)

struct ReviewPromptDialog: View {
    @Binding var isPresented: Bool
    @Environment(LocalizationManager.self) private var L

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

                // Review button
                Button(action: {
                    requestReview()
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

                // Decline button
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

    private func requestReview() {
        #if os(macOS)
        if let writeReviewURL = URL(string: "macappstore://apps.apple.com/app/id?action=write-review") {
            NSWorkspace.shared.open(writeReviewURL)
        }
        #endif
    }
}
