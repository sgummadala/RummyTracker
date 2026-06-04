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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rummy Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewGame = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameView().environment(store)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "suit.club.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(LinearGradient(colors: [.indigo, .purple],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            VStack(spacing: 8) {
                Text("No Games Yet")
                    .font(.title2.bold())
                Text("Start a new game to track scores")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button { showingNewGame = true } label: {
                Label("New Game", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [.indigo, .purple],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                    .shadow(color: .indigo.opacity(0.4), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var gamesList: some View {
        List {
            ForEach(store.games) { game in
                NavigationLink(value: game.id) {
                    GameCardView(game: game)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: store.deleteGame)
        }
        .listStyle(.plain)
        .navigationDestination(for: UUID.self) { gameId in
            GameView(gameId: gameId).environment(store)
        }
    }
}

struct GameCardView: View {
    let game: Game

    private var timeString: String {
        RelativeDateTimeFormatter().localizedString(for: game.createdAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.playerNames.joined(separator: " · "))
                        .font(.headline)
                        .lineLimit(1)
                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge
            }

            if !game.rounds.isEmpty {
                let totals = game.totalScores
                HStack(spacing: 0) {
                    ForEach(game.playerNames, id: \.self) { name in
                        let total = totals[name] ?? 0
                        let isOut = total >= RummyRules.outThreshold
                        let isLeader = name == game.currentLeader
                        VStack(spacing: 3) {
                            Text(String(name.prefix(4)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text("\(total)")
                                .font(.subheadline.bold())
                                .foregroundStyle(isOut ? .red : isLeader ? .green : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Label("\(game.rounds.count) round\(game.rounds.count == 1 ? "" : "s")", systemImage: "list.number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if game.isComplete, let winner = game.winner {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                        Text(winner).fontWeight(.semibold)
                    }
                    .font(.caption)
                } else {
                    Text("Target: \(RummyRules.target) pts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if game.isComplete {
            Text("Done")
                .font(.caption.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.green.opacity(0.12))
                .clipShape(Capsule())
        } else {
            HStack(spacing: 5) {
                Circle().fill(.orange).frame(width: 6, height: 6)
                Text("Live").font(.caption.bold()).foregroundStyle(.orange)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.orange.opacity(0.12))
            .clipShape(Capsule())
        }
    }
}
