import SwiftUI
import Observation

// MARK: - Theme Definition

struct ThemeDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let gradientColors: [Color]
    let tableNavy: Color
    let tableGreen: Color
    let tableGreenLight: Color
    let buttonDark: Color
    let gold: Color

    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: Preset themes

    static let classic = ThemeDefinition(
        id: "classic", name: "Classic", emoji: "🎴",
        gradientColors: [
            Color(red: 0.43, green: 0.45, blue: 0.88),
            Color(red: 0.58, green: 0.35, blue: 0.72),
            Color(red: 0.88, green: 0.42, blue: 0.45)
        ],
        tableNavy:      Color(red: 0.06, green: 0.06, blue: 0.20),
        tableGreen:     Color(red: 0.14, green: 0.50, blue: 0.22),
        tableGreenLight:Color(red: 0.17, green: 0.57, blue: 0.27),
        buttonDark:     Color.black.opacity(0.48),
        gold:           Color(red: 1.00, green: 0.84, blue: 0.00)
    )

    static let royalDark = ThemeDefinition(
        id: "royal_dark", name: "Royal Dark", emoji: "♠️",
        gradientColors: [
            Color(red: 0.10, green: 0.10, blue: 0.18),
            Color(red: 0.09, green: 0.13, blue: 0.24),
            Color(red: 0.06, green: 0.20, blue: 0.38)
        ],
        tableNavy:      Color(red: 0.04, green: 0.04, blue: 0.10),
        tableGreen:     Color(red: 0.42, green: 0.30, blue: 0.04),
        tableGreenLight:Color(red: 0.50, green: 0.37, blue: 0.06),
        buttonDark:     Color.white.opacity(0.10),
        gold:           Color(red: 1.00, green: 0.84, blue: 0.00)
    )

    static let emeraldTable = ThemeDefinition(
        id: "emerald", name: "Emerald", emoji: "🃏",
        gradientColors: [
            Color(red: 0.05, green: 0.18, blue: 0.10),
            Color(red: 0.08, green: 0.26, blue: 0.16),
            Color(red: 0.10, green: 0.22, blue: 0.18)
        ],
        tableNavy:      Color(red: 0.02, green: 0.08, blue: 0.04),
        tableGreen:     Color(red: 0.11, green: 0.38, blue: 0.22),
        tableGreenLight:Color(red: 0.14, green: 0.45, blue: 0.27),
        buttonDark:     Color.black.opacity(0.45),
        gold:           Color(red: 0.96, green: 0.82, blue: 0.41)
    )

    static let midnightOcean = ThemeDefinition(
        id: "midnight_ocean", name: "Midnight Ocean", emoji: "🌊",
        gradientColors: [
            Color(red: 0.04, green: 0.05, blue: 0.16),
            Color(red: 0.06, green: 0.09, blue: 0.31),
            Color(red: 0.05, green: 0.15, blue: 0.46)
        ],
        tableNavy:      Color(red: 0.02, green: 0.02, blue: 0.08),
        tableGreen:     Color(red: 0.04, green: 0.23, blue: 0.40),
        tableGreenLight:Color(red: 0.05, green: 0.29, blue: 0.50),
        buttonDark:     Color.white.opacity(0.10),
        gold:           Color(red: 0.00, green: 0.83, blue: 1.00)
    )

    static let crimsonNight = ThemeDefinition(
        id: "crimson", name: "Crimson Night", emoji: "🔴",
        gradientColors: [
            Color(red: 0.12, green: 0.03, blue: 0.03),
            Color(red: 0.20, green: 0.06, blue: 0.06),
            Color(red: 0.12, green: 0.03, blue: 0.03)
        ],
        tableNavy:      Color(red: 0.05, green: 0.01, blue: 0.01),
        tableGreen:     Color(red: 0.38, green: 0.07, blue: 0.07),
        tableGreenLight:Color(red: 0.46, green: 0.10, blue: 0.10),
        buttonDark:     Color.white.opacity(0.10),
        gold:           Color(red: 1.00, green: 0.42, blue: 0.21)
    )

    static let all: [ThemeDefinition] = [.classic, .royalDark, .emeraldTable, .midnightOcean, .crimsonNight]
}

// MARK: - Theme Manager

@Observable
@MainActor
class ThemeManager {
    var theme: ThemeDefinition = .classic

    private let key = "selected_theme"

    init() {
        let saved = UserDefaults.standard.string(forKey: key) ?? "classic"
        theme = ThemeDefinition.all.first { $0.id == saved } ?? .classic
    }

    func select(_ t: ThemeDefinition) {
        theme = t
        UserDefaults.standard.set(t.id, forKey: key)
    }
}

// MARK: - Layout constants (not theme-specific)
enum Layout {
    static let rdColWidth: CGFloat = 46
}
