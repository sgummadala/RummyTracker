import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let gameId: UUID

    @State private var showingAddRound = false
    @State private var editingRound: Round?
    @State private var showingEndAlert = false

    private var game: Game? { store.games.first(where: { $0.id == gameId }) }

    var body: some View {
        Group {
            if let game { mainContent(game: game) }
        }
    }

    @ViewBuilder
    private func mainContent(game: Game) -> some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                scoreTable(game: game)
                Spacer()
            }
        }
        .navigationTitle(navTitle(game))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !game.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { showingEndAlert = true } label: {
                        Image(systemName: "flag.checkered").foregroundStyle(.white)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !game.isComplete { fabRow(game: game) }
        }
        .sheet(isPresented: $showingAddRound) {
            AddRoundView(
                gameId: gameId,
                playerNames: game.playerNames,
                currentTotals: game.totalScores
            )
            .environment(store)
        }
        .sheet(item: $editingRound) { round in
            AddRoundView(
                gameId: gameId,
                playerNames: game.playerNames,
                currentTotals: game.totalsBefore(round: round),
                editingRound: round
            )
            .environment(store)
        }
        .alert("End Game?", isPresented: $showingEndAlert) {
            Button("End Game", role: .destructive) { store.completeGame(gameId) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Scores will be finalized. Lowest total wins.")
        }
    }

    private func navTitle(_ game: Game) -> String {
        game.playerNames.count <= 3
            ? game.playerNames.joined(separator: " vs ")
            : "\(game.playerNames[0]) +\(game.playerNames.count - 1)"
    }

    // MARK: - Score Table

    @ViewBuilder
    private func scoreTable(game: Game) -> some View {
        let totals = game.totalScores
        let players = game.playerNames
        let needsScroll = players.count > Theme.maxPlayersWithoutScroll

        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    // Round rows
                    if game.rounds.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(game.rounds.enumerated()), id: \.element.id) { index, round in
                            if needsScroll {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    roundRowContent(game: game, round: round, index: index)
                                }
                            } else {
                                roundRowContent(game: game, round: round, index: index)
                            }
                            if index < game.rounds.count - 1 {
                                Divider().background(Color.white.opacity(0.2))
                            }
                        }
                    }

                    // Totals row
                    if needsScroll {
                        ScrollView(.horizontal, showsIndicators: false) {
                            totalsRowContent(game: game, totals: totals)
                        }
                    } else {
                        totalsRowContent(game: game, totals: totals)
                    }

                    // Winner banner
                    if game.isComplete, let winner = game.winner {
                        winnerBanner(winner: winner, rounds: game.rounds.count)
                    }
                } header: {
                    if needsScroll {
                        ScrollView(.horizontal, showsIndicators: false) {
                            headerRowContent(players: players, leader: game.currentLeader, isComplete: game.isComplete)
                        }
                    } else {
                        headerRowContent(players: players, leader: game.currentLeader, isComplete: game.isComplete)
                    }
                }
            }
        }
    }

    // MARK: - Table row content (shared between scroll and no-scroll)

    private func headerRowContent(players: [String], leader: String?, isComplete: Bool) -> some View {
        HStack(spacing: 0) {
            tableCell(text: "Rd.", width: Theme.rdColWidth, bg: Theme.tableNavy, bold: true)
            ForEach(players, id: \.self) { name in
                VStack(spacing: 2) {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if name == leader {
                        Image(systemName: isComplete ? "trophy.fill" : "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(isComplete ? Theme.gold : .yellow)
                    }
                }
                .frame(width: Theme.playerColWidth)
                .frame(height: 52)
                .background(Theme.tableGreen)
            }
        }
    }

    private func roundRowContent(game: Game, round: Round, index: Int) -> some View {
        Button {
            guard !game.isComplete else { return }
            editingRound = round
        } label: {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white)
                    if !game.isComplete {
                        Image(systemName: "pencil").font(.system(size: 8)).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(width: Theme.rdColWidth, height: 52)
                .background(Theme.tableNavy)

                ForEach(game.playerNames, id: \.self) { name in
                    let pts = round.scores[name] ?? 0
                    scoreCell(pts: pts, game: game, name: name, roundIndex: index)
                }
            }
        }
        .buttonStyle(.plain)
        .background(index.isMultiple(of: 2) ? Theme.tableGreen : Theme.tableGreenLight)
    }

    private func totalsRowContent(game: Game, totals: [String: Int]) -> some View {
        HStack(spacing: 0) {
            tableCell(text: "Tot", width: Theme.rdColWidth, bg: Theme.tableNavy, bold: true)
            ForEach(game.playerNames, id: \.self) { name in
                let total = totals[name] ?? 0
                let isOut = game.isPlayerOut(name)
                let isLeader = name == game.currentLeader
                VStack(spacing: 3) {
                    Text("\(total)")
                        .font(.headline.bold())
                        .foregroundStyle(isOut ? .red : isLeader ? Theme.gold : .white)
                    if isOut {
                        Text("OUT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else {
                        Text("\(game.rules.gameScore - total)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: Theme.playerColWidth, height: 56)
                .background(Theme.tableGreen)
            }
        }
    }

    private func scoreCell(pts: Int, game: Game, name: String, roundIndex: Int) -> some View {
        Text(pts == 0 ? "W" : "\(pts)")
            .font(.subheadline.bold())
            .foregroundStyle(pts == 0 ? .green : pts >= game.rules.fullScore ? .red : .white)
            .frame(width: Theme.playerColWidth, height: 52)
            .background(roundIndex.isMultiple(of: 2) ? Theme.tableGreen : Theme.tableGreenLight)
    }

    private func tableCell(text: String, width: CGFloat, bg: Color, bold: Bool = false) -> some View {
        Text(text)
            .font(bold ? .subheadline.bold() : .subheadline)
            .foregroundStyle(.white)
            .frame(width: width, height: 52)
            .background(bg)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed").font(.largeTitle).foregroundStyle(.white.opacity(0.5))
            Text("No rounds yet").font(.subheadline).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func winnerBanner(winner: String, rounds: Int) -> some View {
        HStack(spacing: 14) {
            Text("🏆").font(.largeTitle)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(winner) wins!").font(.title3.bold()).foregroundStyle(.white)
                Text("\(rounds) rounds played").font(.caption).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.35))
    }

    // MARK: - FABs

    private func fabRow(game: Game) -> some View {
        HStack {
            // Edit last round (left FAB — coral/red)
            Button {
                if let last = game.rounds.last { editingRound = last }
            } label: {
                ZStack {
                    Circle().fill(Color(red: 0.90, green: 0.35, blue: 0.35))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    Image(systemName: "clipboard.fill")
                        .font(.title3).foregroundStyle(.white)
                }
            }
            .disabled(game.rounds.isEmpty)
            .opacity(game.rounds.isEmpty ? 0.4 : 1)

            Spacer()

            // Add round (right FAB — dark)
            Button {
                showingAddRound = true
            } label: {
                ZStack {
                    Circle().fill(Theme.buttonDark)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    Image(systemName: "plus")
                        .font(.title2.bold()).foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}
