//
//  Theme.swift
//  Markly
//

import SwiftUI

// MARK: - Color Tokens

enum LColors {
    // Billi palette roles from the supplied reference.
    static let background = Color(marklyHex: "#101322")
    static let surfaces = Color(marklyHex: "#191D30")
    static let raisedSurfaces = Color(marklyHex: "#222842")
    static let primaryActions = Color(marklyHex: "#6F91F2")
    static let secondaryAccent = Color(marklyHex: "#F18BB5")
    static let indicators = Color(marklyHex: "#F4D978")
    static let primaryText = Color(marklyHex: "#F7F7FA")
    static let secondaryText = Color(marklyHex: "#AEB3C3")

    // Existing aliases kept so the app can stay on one centralized theme surface.
    static let bg = background
    static let bgSoft = surfaces
    static let textPrimary = primaryText
    static let textSecondary = secondaryText
    static let accent = primaryActions
    static let accentHover = secondaryAccent

    // Status
    static let success = indicators
    static let danger = secondaryAccent
    static let warning = indicators

    // Themed surfaces
    static let glassSurface = surfaces
    static let glassSurface2 = raisedSurfaces
    static let glassBorder = secondaryAccent.opacity(0.34)
    static let glassBorderStrong = indicators.opacity(0.68)

    // Badge colors
    static let badgeOnce = primaryActions
    static let badgeDaily = secondaryAccent
    static let badgeWeekly = indicators
    static let badgeInterval = indicators
}

// MARK: - Spacing & Radius

enum LSpacing {
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999
    static let pageHorizontal: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

// MARK: - Color Extension

extension Color {
    init(marklyHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
