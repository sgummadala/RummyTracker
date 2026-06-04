import SwiftUI

// Shared design tokens used across all screens
enum Theme {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.43, green: 0.45, blue: 0.88),
            Color(red: 0.58, green: 0.35, blue: 0.72),
            Color(red: 0.88, green: 0.42, blue: 0.45)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tableNavy  = Color(red: 0.06, green: 0.06, blue: 0.20)
    static let tableGreen = Color(red: 0.14, green: 0.50, blue: 0.22)
    static let tableGreenLight = Color(red: 0.17, green: 0.57, blue: 0.27)
    static let buttonDark = Color.black.opacity(0.48)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)

    static let rdColWidth: CGFloat = 50
    static let playerColWidth: CGFloat = 75
    static let maxPlayersWithoutScroll = 4
}

struct GradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackground())
    }
}
