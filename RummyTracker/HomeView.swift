import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showingNewGame = false

    var body: some View {
        NavigationStack {
            Group {
                if store.games.isEmpty {
                    emptyState
                } else {
                    gamesList
                }
            }
            .navigationTitle("Rummy Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewGame = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameView()
                    .environment(store)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Games Yet",
            systemImage: "suit.club.fill",
            description: Text("Tap + to start tracking your first game")
        )
    }

    private var gamesList: some View {
        List {
            ForEach(store.games) { game in
                NavigationLink(value: game.id) {
                    GameRowView(game: game)
                }
            }
            .onDelete(perform: store.deleteGame)
        }
        .navigationDestination(for: UUID.self) { gameId in
            GameView(gameId: gameId)
                .environment(store)
        }
    }
}

struct GameRowView: View {
    let game: Game

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: game.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(game.playerNames.joined(separator: " · "))
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                statusBadge
            }
            HStack {
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                subtitleText
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if game.isComplete {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .labelStyle(.iconOnly)
        } else {
            Label("Live", systemImage: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
                .labelStyle(.iconOnly)
        }
    }

    @ViewBuilder
    private var subtitleText: some View {
        if game.isComplete, let winner = game.winner {
            HStack(spacing: 3) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text(winner)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .font(.caption)
        } else if !game.rounds.isEmpty {
            Text("\(game.rounds.count) round\(game.rounds.count == 1 ? "" : "s") · Target \(game.targetScore)")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Target: \(game.targetScore) pts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
