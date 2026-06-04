import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let gameId: UUID

    @State private var showingAddRound = false
    @State private var editingRound: Round?
    @State private var showingEndAlert = false

    private var game: Game? { store.games.first(where: { $0.id == gameId }) }

    private func colWidth(playerCount: Int) -> CGFloat {
        switch playerCount {
        case 2: return 110
        case 3: return 90
        case 4: return 78
        case 5: return 68
        case 6: return 62
        default: return 56
        }
    }

    var body: some View {
        Group {
            if let game { mainContent(game: game) }
        }
    }

    @ViewBuilder
    private func mainContent(game: Game) -> some View {
        let cw = colWidth(playerCount: game.playerNames.count)

        ScrollView {
            VStack(spacing: 16) {
                if game.isComplete { winnerCard(game: game) }
                statsRow(game: game)
                scoreTable(game: game, colWidth: cw)
                    .padding(.bottom, game.isComplete ? 0 : 88)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navTitle(game))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !game.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { showingEndAlert = true } label: {
                        Label("End Game", systemImage: "flag.checkered")
                            .font(.subheadline)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !game.isComplete { addRoundFAB }
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

    // MARK: - Header Cards

    private func winnerCard(game: Game) -> some View {
        HStack(spacing: 16) {
            Text("🏆").font(.system(size: 48))
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Over")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
                if let winner = game.winner {
                    Text("\(winner) wins!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                Text("\(game.rounds.count) rounds played")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [.green.opacity(0.85), .teal.opacity(0.9)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
    }

    private func statsRow(game: Game) -> some View {
        HStack(spacing: 10) {
            statPill("Rounds", value: "\(game.rounds.count)", color: .indigo)
            statPill("Out at", value: "\(RummyRules.outThreshold)", color: .red)
            if let leader = game.currentLeader {
                statPill(game.isComplete ? "Winner" : "Leading", value: leader, color: .green)
            }
        }
    }

    private func statPill(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Score Table

    @ViewBuilder
    private func scoreTable(game: Game, colWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            // All rows share one horizontal ScrollView so they scroll in sync
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    tableHeader(game: game, colWidth: colWidth)
                    Divider()

                    if game.rounds.isEmpty {
                        emptyRoundsHint
                    } else {
                        ForEach(Array(game.rounds.enumerated()), id: \.element.id) { index, round in
                            roundRow(game: game, round: round, index: index, colWidth: colWidth)
                            if index < game.rounds.count - 1 {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }

                    Divider()
                    totalsRow(game: game, colWidth: colWidth)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
    }

    private func tableHeader(game: Game, colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 48, alignment: .center)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(game.playerNames, id: \.self) { name in
                let leader = game.currentLeader
                VStack(spacing: 3) {
                    Text(name)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if name == leader {
                        Image(systemName: game.isComplete ? "trophy.fill" : "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(game.isComplete ? .yellow : .orange)
                    }
                }
                .frame(width: colWidth)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(.secondarySystemBackground))
    }

    private var emptyRoundsHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle.dashed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No rounds yet")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Text("Tap Add Round below to begin")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func roundRow(game: Game, round: Round, index: Int, colWidth: CGFloat) -> some View {
        Button {
            guard !game.isComplete else { return }
            editingRound = round
        } label: {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    if !game.isComplete {
                        Image(systemName: "pencil")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 48)

                ForEach(game.playerNames, id: \.self) { name in
                    let pts = round.scores[name] ?? 0
                    let cumul = game.cumulativeScore(for: name, throughRound: index)
                    scoreCell(pts: pts, cumulative: cumul, colWidth: colWidth)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 6)
            .background(index.isMultiple(of: 2)
                        ? Color(.systemBackground)
                        : Color(.secondarySystemBackground).opacity(0.4))
        }
        .buttonStyle(.plain)
    }

    private func scoreCell(pts: Int, cumulative: Int, colWidth: CGFloat) -> some View {
        VStack(spacing: 3) {
            Group {
                if pts == 0 {
                    Text("Won")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                } else if pts == RummyRules.drop {
                    Text("Drop")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else if pts == RummyRules.midDrop {
                    Text("Mid")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text("+\(pts)")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            Text("\(cumulative)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: colWidth)
    }

    private func totalsRow(game: Game, colWidth: CGFloat) -> some View {
        let totals = game.totalScores
        let leader = game.currentLeader
        return HStack(spacing: 0) {
            Text("Σ")
                .frame(width: 48, alignment: .center)
                .font(.headline.bold())
                .foregroundStyle(.secondary)
            ForEach(game.playerNames, id: \.self) { name in
                let total = totals[name] ?? 0
                let isOut = total >= RummyRules.outThreshold
                let isLeading = name == leader
                VStack(spacing: 4) {
                    Text("\(total)")
                        .font(.title3.bold())
                        .foregroundStyle(isOut ? .red : isLeading ? .green : .primary)
                    if isOut {
                        Text("OUT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(.red)
                            .clipShape(Capsule())
                    } else {
                        let left = RummyRules.target - total
                        Text("\(left) left")
                            .font(.caption2)
                            .foregroundStyle(left <= 50 ? .orange : .secondary)
                    }
                }
                .frame(width: colWidth)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - FAB

    private var addRoundFAB: some View {
        Button { showingAddRound = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add Round")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient(colors: [.indigo, .purple],
                                        startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .indigo.opacity(0.45), radius: 10, y: 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}
