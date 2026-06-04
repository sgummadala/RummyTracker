import SwiftUI

@main
struct RummyTrackerApp: App {
    @State private var store = GameStore()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(themeManager)
        }
    }
}
