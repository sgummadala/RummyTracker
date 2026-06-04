import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showingNewGame = false
    @State private var showingPastGames = false
    @State private var navigateToGameId: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Spacer()
                    buttons
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .navigationDestination(for: UUID.self) { gameId in
                GameView(gameId: gameId).environment(store)
            }
            .navigationDestination(item: $navigateToGameId) { gameId in
                GameView(gameId: gameId).environment(store)
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameFlow(navigateToGameId: $navigateToGameId).environment(store)
            }
            .sheet(isPresented: $showingPastGames) {
                PastGamesView().environment(store)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Rummy Score Sheet")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 0) {
                Text("• Track Scores")
                Text(" • View Scores")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            HomeActionButton(
                icon: "play.fill",
                title: "Start New Game",
                subtitle: "Create a new game",
                isDisabled: false
            ) {
                showingNewGame = true
            }

            if let active = store.activeGame {
                NavigationLink(value: active.id) {
                    HomeActionButtonLabel(
                        icon: "arrow.clockwise",
                        title: "Current Game Scores",
                        subtitle: "Manage Current Game...",
                        isDisabled: false
                    )
                }
            } else {
                HomeActionButton(
                    icon: "arrow.clockwise",
                    title: "Current Game Scores",
                    subtitle: "No active game",
                    isDisabled: true,
                    action: {}
                )
            }

            HomeActionButton(
                icon: "eye.fill",
                title: "Past Games",
                subtitle: "View game history",
                isDisabled: store.games.filter(\.isComplete).isEmpty
            ) {
                showingPastGames = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Home buttons

struct HomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HomeActionButtonLabel(icon: icon, title: title, subtitle: subtitle, isDisabled: isDisabled)
        }
        .disabled(isDisabled)
    }
}

struct HomeActionButtonLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isDisabled ? 0.1 : 0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .white.opacity(0.4) : .white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isDisabled ? .white.opacity(0.4) : .white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(isDisabled ? .white.opacity(0.3) : Theme.gold)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.buttonDark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Past Games Sheet

struct PastGamesView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var pastGames: [Game] { store.games.filter(\.isComplete) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                if pastGames.isEmpty {
                    Text("No completed games yet")
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(pastGames) { game in
                                PastGameCard(game: game)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Past Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct PastGameCard: View {
    let game: Game

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: game.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(game.playerNames.joined(separator: " · "))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                if let winner = game.winner {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill").foregroundStyle(Theme.gold)
                        Text(winner).foregroundStyle(Theme.gold).fontWeight(.semibold)
                    }
                    .font(.caption)
                }
            }
            HStack {
                Text(dateString).font(.caption).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(game.rounds.count) rounds").font(.caption).foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Theme.buttonDark)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
