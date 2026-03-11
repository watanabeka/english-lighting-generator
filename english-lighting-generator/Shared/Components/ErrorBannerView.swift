//
//  ErrorBannerView.swift
//  english-lighting-generator
//
//  Shared inline error banner used by both the Generator and Quiz features.
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.25))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.15))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.82))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }
}
