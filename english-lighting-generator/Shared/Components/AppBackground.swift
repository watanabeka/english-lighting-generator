//
//  AppBackground.swift
//  english-lighting-generator
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.skyTop, .skyMid, .skyBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.65), Color.white.opacity(0.10), .clear],
                center: UnitPoint(x: 0.70, y: 0.36),
                startRadius: 20,
                endRadius: 260
            )
            RadialGradient(
                colors: [Color.white.opacity(0.30), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 200
            )
            RadialGradient(
                colors: [Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.25), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}
