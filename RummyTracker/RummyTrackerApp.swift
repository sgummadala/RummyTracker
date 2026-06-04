import SwiftUI

@main
struct RummyTrackerApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
