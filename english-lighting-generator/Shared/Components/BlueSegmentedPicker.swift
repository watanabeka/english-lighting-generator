//
//  BlueSegmentedPicker.swift
//  english-lighting-generator
//

import SwiftUI

struct BlueSegmentedPicker<T: Hashable & Identifiable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options) { option in
                let isSelected = selection == option
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = option }
                }) {
                    Text(label(option))
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .white : Color(red: 0.30, green: 0.46, blue: 0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? AnyShapeStyle(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color.clear)
                                )
                                .shadow(color: isSelected ? Color.btnBlue.opacity(0.30) : .clear, radius: 5, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Color(red: 0.82, green: 0.89, blue: 0.97))
        )
    }
}
