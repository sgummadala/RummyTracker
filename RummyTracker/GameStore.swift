import Foundation
import Observation

enum RummyRules {
    static let maxPlayers = 7
    static let target = 250
    static let outThreshold = 251
    static let drop = 25
    static let midDrop = 50
}

struct Round: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var scores: [String: Int]
}

struct Game: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var playerNames: [String]
    var rounds: [Round] = []
    var isComplete: Bool = false

    var totalScores: [String: Int] {
        var totals = Dictionary(uniqueKeysWithValues: playerNames.map { ($0, 0) })
        for round in rounds {
            for (name, score) in round.scores {
                totals[name, default: 0] += score
            }
        }
        return totals
    }

    var winner: String? {
        guard isComplete, !rounds.isEmpty else { return nil }
        return totalScores.min(by: { $0.value < $1.value })?.key
    }

    var currentLeader: String? {
        guard !rounds.isEmpty else { return nil }
        let totals = totalScores
        return playerNames
            .filter { (totals[$0] ?? 0) < RummyRules.outThreshold }
            .min(by: { (totals[$0] ?? 0) < (totals[$1] ?? 0) })
    }

    func isPlayerOut(_ name: String) -> Bool {
        (totalScores[name] ?? 0) >= RummyRules.outThreshold
    }

    var hasPlayerCrossedTarget: Bool {
        totalScores.values.contains(where: { $0 >= RummyRules.outThreshold })
    }

    func cumulativeScore(for player: String, throughRound roundIndex: Int) -> Int {
        rounds.prefix(roundIndex + 1).reduce(0) { $0 + ($1.scores[player] ?? 0) }
    }

    func totalsBefore(round: Round) -> [String: Int] {
        guard let i = rounds.firstIndex(where: { $0.id == round.id }) else {
            return Dictionary(uniqueKeysWithValues: playerNames.map { ($0, 0) })
        }
        var totals = Dictionary(uniqueKeysWithValues: playerNames.map { ($0, 0) })
        for r in rounds.prefix(i) {
            for (name, pts) in r.scores { totals[name, default: 0] += pts }
        }
        return totals
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Game, rhs: Game) -> Bool { lhs.id == rhs.id }
}

@Observable
@MainActor
class GameStore {
    var games: [Game] = []
    private let storageKey = "rummy_games_v1"

    init() { load() }

    func startGame(playerNames: [String]) {
        if let index = games.firstIndex(where: { !$0.isComplete }) {
            games[index].isComplete = true
        }
        games.insert(Game(playerNames: playerNames), at: 0)
        save()
    }

    func addRound(to gameId: UUID, scores: [String: Int]) {
        guard let i = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[i].rounds.append(Round(scores: scores))
        if games[i].hasPlayerCrossedTarget { games[i].isComplete = true }
        save()
    }

    func updateRound(in gameId: UUID, roundId: UUID, scores: [String: Int]) {
        guard let gi = games.firstIndex(where: { $0.id == gameId }),
              let ri = games[gi].rounds.firstIndex(where: { $0.id == roundId }) else { return }
        games[gi].rounds[ri].scores = scores
        games[gi].isComplete = games[gi].hasPlayerCrossedTarget
        save()
    }

    func deleteRound(in gameId: UUID, at offsets: IndexSet) {
        guard let gi = games.firstIndex(where: { $0.id == gameId }) else { return }
        for i in offsets.reversed() { games[gi].rounds.remove(at: i) }
        if !games[gi].hasPlayerCrossedTarget { games[gi].isComplete = false }
        save()
    }

    func completeGame(_ gameId: UUID) {
        guard let i = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[i].isComplete = true
        save()
    }

    func deleteGame(at offsets: IndexSet) {
        for i in offsets.reversed() { games.remove(at: i) }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Game].self, from: data) else { return }
        games = decoded
    }
}
