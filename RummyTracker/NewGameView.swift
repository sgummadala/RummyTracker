import SwiftUI

// Coordinator that manages the Add Players → Set Rules flow
struct NewGameFlow: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var navigateToGameId: UUID?

    @State private var players: [PlayerEntry] = []
    @State private var rules = GameRules()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AddPlayersView(players: $players) {
                path.append("rules")
            }
            .navigationDestination(for: String.self) { _ in
                GameRulesView(rules: $rules, players: players) {
                    let names = players
                        .filter(\.isActive)
                        .map(\.name)
                        .filter { !$0.isEmpty }
                    guard names.count >= 2 else { return }
                    store.startGame(playerNames: names, rules: rules)
                    navigateToGameId = store.activeGame?.id
                    dismiss()
                }
            }
        }
    }
}

struct PlayerEntry: Identifiable {
    let id = UUID()
    var name: String
    var isActive: Bool = true
}
