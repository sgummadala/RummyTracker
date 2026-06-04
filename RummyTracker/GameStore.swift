import Foundation
import Observation

struct Round: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var scores: [String: Int]
}

struct Game: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var playerNames: [String]
    var targetScore: Int
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
        return totalScores.min(by: { $0.value < $1.value })?.key
    }

    var hasPlayerCrossedTarget: Bool {
        totalScores.values.contains(where: { $0 >= targetScore })
    }

    func cumulativeScore(for player: String, throughRound roundIndex: Int) -> Int {
        rounds.prefix(roundIndex + 1).reduce(0) { $0 + ($1.scores[player] ?? 0) }
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

    func startGame(playerNames: [String], targetScore: Int) {
        if let index = games.firstIndex(where: { !$0.isComplete }) {
            games[index].isComplete = true
        }
        games.insert(Game(playerNames: playerNames, targetScore: targetScore), at: 0)
        save()
    }

    func addRound(to gameId: UUID, scores: [String: Int]) {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[index].rounds.append(Round(scores: scores))
        if games[index].hasPlayerCrossedTarget {
            games[index].isComplete = true
        }
        save()
    }

    func deleteRound(in gameId: UUID, at offsets: IndexSet) {
        guard let gameIndex = games.firstIndex(where: { $0.id == gameId }) else { return }
        for i in offsets.reversed() {
            games[gameIndex].rounds.remove(at: i)
        }
        if !games[gameIndex].hasPlayerCrossedTarget {
            games[gameIndex].isComplete = false
        }
        save()
    }

    func completeGame(_ gameId: UUID) {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[index].isComplete = true
        save()
    }

    func deleteGame(at offsets: IndexSet) {
        for i in offsets.reversed() {
            games.remove(at: i)
        }
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
