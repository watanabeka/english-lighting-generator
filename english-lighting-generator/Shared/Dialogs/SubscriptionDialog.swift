//
//  SubscriptionDialog.swift
//  english-lighting-generator
//
//  Modal shown when the user reaches the daily free-generation limit.
//

import StoreKit
import SwiftUI

struct SubscriptionDialog: View {
    @Binding var isPresented: Bool
    @Environment(LocalizationManager.self) private var L
    private let store = StoreManager.shared

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

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

                Text(L["subscription.body"])
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cardText.opacity(0.82))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                Text(L["subscription.priceNote"])
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.90, green: 0.55, blue: 0.08))
                    .padding(.bottom, 16)

                Button(action: { Task { await store.purchase() } }) {
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
