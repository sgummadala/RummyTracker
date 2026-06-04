import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    @Environment(ThemeManager.self) private var tm
    let gameId: UUID

    @State private var showingAddRound = false
    @State private var editingRound: Round?
    @State private var showingEndAlert = false

    private var game: Game? { store.games.first(where: { $0.id == gameId }) }
    private var t: ThemeDefinition { tm.theme }

    var body: some View {
        Group {
            if let game { mainContent(game: game) }
        }
    }

    @ViewBuilder
    private func mainContent(game: Game) -> some View {
        ZStack {
            t.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                scoreTable(game: game)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .environment(tm)
        }
        .sheet(item: $editingRound) { round in
            AddRoundView(
                gameId: gameId,
                playerNames: game.playerNames,
                currentTotals: game.totalsBefore(round: round),
                editingRound: round
            )
            .environment(store)
            .environment(tm)
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

        GeometryReader { geo in
            let rdW: CGFloat = 46
            let pW: CGFloat = max(44, (geo.size.width - rdW) / CGFloat(game.playerNames.count))

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        if game.rounds.isEmpty {
                            emptyState
                        } else {
                            ForEach(Array(game.rounds.enumerated()), id: \.element.id) { index, round in
                                roundRowContent(game: game, round: round, index: index, rdW: rdW, pW: pW)
                                if index < game.rounds.count - 1 {
                                    Divider().background(Color.white.opacity(0.2))
                                }
                            }
                        }
                        totalsRowContent(game: game, totals: totals, rdW: rdW, pW: pW)
                        if game.isComplete, let winner = game.winner {
                            winnerBanner(winner: winner, rounds: game.rounds.count)
                        }
                    } header: {
                        headerRowContent(players: game.playerNames, leader: game.currentLeader,
                                         isComplete: game.isComplete, rdW: rdW, pW: pW)
                    }
                }
            }
        }
    }

    // MARK: - Table rows

    private func headerRowContent(players: [String], leader: String?, isComplete: Bool,
                                   rdW: CGFloat, pW: CGFloat) -> some View {
        HStack(spacing: 0) {
            tableCell(text: "Rd.", width: rdW, height: 48, bg: t.tableNavy, bold: true)
            ForEach(players, id: \.self) { name in
                VStack(spacing: 2) {
                    Text(String(name.prefix(5)))
                        .font(.system(size: min(13, pW * 0.22), weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if name == leader {
                        Image(systemName: isComplete ? "trophy.fill" : "crown.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(isComplete ? t.gold : .yellow)
                    }
                }
                .frame(width: pW, height: 48)
                .background(t.tableGreen)
            }
        }
    }

    private func roundRowContent(game: Game, round: Round, index: Int,
                                  rdW: CGFloat, pW: CGFloat) -> some View {
        Button {
            guard !game.isComplete else { return }
            editingRound = round
        } label: {
            HStack(spacing: 0) {
                VStack(spacing: 1) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    if !game.isComplete {
                        Image(systemName: "pencil")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(width: rdW, height: 46)
                .background(t.tableNavy)

                ForEach(game.playerNames, id: \.self) { name in
                    let pts = round.scores[name] ?? 0
                    Text(pts == 0 ? "W" : "\(pts)")
                        .font(.system(size: min(14, pW * 0.24), weight: pts == 0 ? .bold : .regular))
                        .foregroundStyle(pts == 0 ? .green : pts >= game.rules.fullScore ? .red : .white)
                        .frame(width: pW, height: 46)
                        .background(index.isMultiple(of: 2) ? t.tableGreen : t.tableGreenLight)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func totalsRowContent(game: Game, totals: [String: Int],
                                   rdW: CGFloat, pW: CGFloat) -> some View {
        HStack(spacing: 0) {
            tableCell(text: "Tot", width: rdW, height: 56, bg: t.tableNavy, bold: true)
            ForEach(game.playerNames, id: \.self) { name in
                let total = totals[name] ?? 0
                let isOut = game.isPlayerOut(name)
                let isLeader = name == game.currentLeader
                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.system(size: min(15, pW * 0.24), weight: .bold))
                        .foregroundStyle(isOut ? .red : isLeader ? t.gold : .white)
                    if isOut {
                        Text("OUT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else {
                        Text("\(game.rules.gameScore - total)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .frame(width: pW, height: 56)
                .background(t.tableGreen)
            }
        }
    }

    private func tableCell(text: String, width: CGFloat, height: CGFloat,
                            bg: Color, bold: Bool = false) -> some View {
        Text(text)
            .font(bold ? .system(size: 12, weight: .bold) : .system(size: 12))
            .foregroundStyle(.white)
            .frame(width: width, height: height)
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
                    Circle().fill(t.buttonDark)
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
