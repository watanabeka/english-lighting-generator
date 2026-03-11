//
//  DesignSystem.swift
//  english-lighting-generator
//
//  Central token definitions for the app's colour palette.
//  All colour values are referenced via these named tokens — never hardcode RGB in views.
//

import SwiftUI

extension Color {
    // Sky-blue light palette
    static let skyTop      = Color(red: 0.50, green: 0.67, blue: 0.86)
    static let skyMid      = Color(red: 0.70, green: 0.83, blue: 0.93)
    static let skyBottom   = Color(red: 0.87, green: 0.93, blue: 0.98)

    // Card & text
    static let cardText    = Color(red: 0.18, green: 0.24, blue: 0.42)
    static let cardSub     = Color(red: 0.48, green: 0.56, blue: 0.72)

    // Button / accent
    static let btnBlue     = Color(red: 0.22, green: 0.40, blue: 0.72)
    static let btnBlueDark = Color(red: 0.15, green: 0.30, blue: 0.60)
}
