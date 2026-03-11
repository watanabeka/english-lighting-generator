//
//  CustomTabBar.swift
//  english-lighting-generator
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(LocalizationManager.self) private var L

    private var items: [(icon: String, activeIcon: String, label: String)] {
        [
            ("house",             "house.fill",        L["tab.aiSentence"]),
            ("text.word.spacing", "text.word.spacing", L["tab.quiz"]),
            ("chart.bar",         "chart.bar.fill",    L["tab.history"]),
            ("gearshape",         "gearshape.fill",    L["tab.settings"])
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                let isSelected = selectedTab == index
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = index }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? item.activeIcon : item.icon)
                            .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        Text(item.label)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.50))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
        .background(
            LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .leading, endPoint: .trailing)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.30))
                .frame(height: 0.5)
        }
    }
}
