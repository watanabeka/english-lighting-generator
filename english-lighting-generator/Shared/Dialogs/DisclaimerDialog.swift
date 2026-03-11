//
//  DisclaimerDialog.swift
//  english-lighting-generator
//
//  Modal shown on first launch to explain how the app uses Apple Intelligence.
//

import SwiftUI

struct DisclaimerDialog: View {
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
                                colors: [.btnBlue.opacity(0.15), .btnBlueDark.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 68, height: 68)
                        Image(systemName: "shield.lefthalf.filled.slash")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(LinearGradient(
                                colors: [.btnBlue, .btnBlueDark],
                                startPoint: .top, endPoint: .bottom))
                    }
                    Text(L["disclaimer.title"])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.cardText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.bottom, 18)

                Divider().padding(.horizontal, 24)

                Text(L["disclaimer.body"])
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cardText.opacity(0.82))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

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
                                .fill(LinearGradient(
                                    colors: [.btnBlue, .btnBlueDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
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
