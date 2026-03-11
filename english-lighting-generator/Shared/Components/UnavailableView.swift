//
//  UnavailableView.swift
//  english-lighting-generator
//
//  Shown when Apple Intelligence or a required OS version is unavailable.
//

import SwiftUI

struct UnavailableView: View {
    @Environment(LocalizationManager.self) private var L
    let reasonKey: String

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 90, height: 90)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.20))
            }
            VStack(spacing: 10) {
                Text(L["unavailable.title"])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.cardText)
                Text(L[reasonKey])
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.cardSub)
                    .font(.subheadline)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
