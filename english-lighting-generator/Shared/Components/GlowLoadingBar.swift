//
//  GlowLoadingBar.swift
//  english-lighting-generator
//
//  Animated loading indicator shown while AI generation is in progress.
//

import SwiftUI

struct GlowLoadingBar: View {
    var subtitle: String
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            GeometryReader { geo in
                let width = geo.size.width
                let streakWidth = width * 0.38
                let span = width + streakWidth

                ZStack {
                    Capsule()
                        .fill(Color.btnBlue.opacity(0.18))
                        .frame(width: width, height: 5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.btnBlue.opacity(0.55),
                                    Color.btnBlueDark,
                                    Color.btnBlue.opacity(0.55),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: streakWidth, height: 5)
                        .shadow(color: Color.btnBlue.opacity(0.55), radius: 8)
                        .shadow(color: Color.btnBlueDark.opacity(0.35), radius: 16)
                        .offset(x: phase * span - span / 2)
                }
                .frame(width: width, height: 14, alignment: .center)
                .clipped()
            }
            .frame(height: 14)
            .padding(.horizontal, 44)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cardSub)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.55).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}
