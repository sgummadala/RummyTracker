import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let gameId: UUID

    @State private var showingAddRound = false
    @State private var showingEndGameAlert = false

    private var game: Game? {
        store.games.first(where: { $0.id == gameId })
    }

    var body: some View {
        Group {
            if let game {
                mainContent(game: game)
            }
        }
    }

    @ViewBuilder
    private func mainContent(game: Game) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if game.isComplete {
                    winnerBanner(game: game)
                        .padding(.horizontal)
                }
                statsRow(game: game)
                    .padding(.horizontal)
                scoreTable(game: game)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(game.playerNames.joined(separator: " vs "))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !game.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingEndGameAlert = true
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !game.isComplete {
                Button {
                    showingAddRound = true
                } label: {
                    Label("Add Round", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showingAddRound) {
            AddRoundView(
                gameId: gameId,
                playerNames: game.playerNames,
                currentTotals: game.totalScores
            )
            .environment(store)
        }
        .alert("End Game?", isPresented: $showingEndGameAlert) {
            Button("End Game", role: .destructive) {
                store.completeGame(gameId)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Scores will be finalized. The player with the lowest total wins.")
        }
    }

    private func winnerBanner(game: Game) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Over")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let winner = game.winner {
                    Text("\(winner) wins!")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            Spacer()
        }
        .padding()
        .background(.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.green.opacity(0.3), lineWidth: 1))
    }

    private func statsRow(game: Game) -> some View {
        HStack(spacing: 12) {
            StatCard(label: "Rounds", value: "\(game.rounds.count)")
            StatCard(label: "Target", value: "\(game.targetScore) pts")
            if let leader = game.currentLeader {
                StatCard(
                    label: game.isComplete ? "Winner" : "Leading",
                    value: leader,
                    accent: true
                )
            }
        }
    }

    @ViewBuilder
    private func scoreTable(game: Game) -> some View {
        let totals = game.totalScores
        let leader = game.currentLeader

        VStack(spacing: 0) {
            headerRow(players: game.playerNames, leader: leader, isComplete: game.isComplete)
            Divider()

            if game.rounds.isEmpty {
                Text("No rounds yet — tap Add Round to begin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                roundRows(game: game)
            }

            Divider()
            totalRow(players: game.playerNames, totals: totals, leader: leader, target: game.targetScore)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
    }

    private func headerRow(players: [String], leader: String?, isComplete: Bool) -> some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 40, alignment: .center)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            ForEach(players, id: \.self) { name in
                VStack(spacing: 2) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    if name == leader, leader != nil {
                        Image(systemName: isComplete ? "trophy.fill" : "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(isComplete ? .yellow : .orange)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color(.systemGroupedBackground))
    }

    private func roundRows(game: Game) -> some View {
        ForEach(Array(game.rounds.enumerated()), id: \.element.id) { index, round in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("\(index + 1)")
                        .frame(width: 40, alignment: .center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(game.playerNames, id: \.self) { name in
                        let score = round.scores[name] ?? 0
                        let cumulative = game.cumulativeScore(for: name, throughRound: index)
                        VStack(spacing: 1) {
                            Text(score == 0 ? "Won" : "+\(score)")
                                .font(.subheadline)
                                .fontWeight(score == 0 ? .bold : .regular)
                                .foregroundStyle(score == 0 ? .green : .primary)
                            Text("\(cumulative)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 8)
                .background(index.isMultiple(of: 2) ? Color(.systemBackground) : Color(.secondarySystemBackground))
                if index < game.rounds.count - 1 {
                    Divider().padding(.leading, 40)
                }
            }
        }
    }

    private func totalRow(players: [String], totals: [String: Int], leader: String?, target: Int) -> some View {
        HStack(spacing: 0) {
            Text("Σ")
                .frame(width: 40, alignment: .center)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            ForEach(players, id: \.self) { name in
                let total = totals[name] ?? 0
                let isLeading = name == leader
                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isLeading ? .green : total >= target ? .red : .primary)
                    if total >= target {
                        Text("Out")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    } else {
                        Text("\(target - total) left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color(.systemGroupedBackground))
    }
}

struct StatCard: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(accent ? .green : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
