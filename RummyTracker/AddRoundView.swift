import SwiftUI

enum ScoreType: Equatable {
    case won, drop, midDrop, fullScore, custom

    var label: String {
        switch self {
        case .won:       return "Won"
        case .drop:      return "Drop"
        case .midDrop:   return "Mid"
        case .fullScore: return "Full"
        case .custom:    return "Count"
        }
    }

    func fixedPoints(rules: GameRules) -> Int? {
        switch self {
        case .won:       return 0
        case .drop:      return rules.drop
        case .midDrop:   return rules.midDrop
        case .fullScore: return rules.fullScore
        case .custom:    return nil
        }
    }
}

struct AddRoundView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let gameId: UUID
    let playerNames: [String]
    let currentTotals: [String: Int]
    var editingRound: Round? = nil

    @State private var selections: [String: ScoreType] = [:]
    @State private var customInputs: [String: String] = [:]
    @FocusState private var focusedCustom: String?

    private var gameRules: GameRules {
        store.games.first(where: { $0.id == gameId })?.rules ?? GameRules()
    }

    private var activePlayers: [String] {
        playerNames.filter { (currentTotals[$0] ?? 0) < gameRules.outThreshold }
    }

    private var outPlayers: [String] {
        playerNames.filter { (currentTotals[$0] ?? 0) >= gameRules.outThreshold }
    }

    private func resolvedScore(for name: String) -> Int? {
        guard let type = selections[name] else { return nil }
        if let pts = type.fixedPoints(rules: gameRules) { return pts }
        return Int(customInputs[name, default: ""].trimmingCharacters(in: .whitespaces))
    }

    private var allValid: Bool {
        activePlayers.allSatisfy { resolvedScore(for: $0) != nil }
    }

    private var winnerCount: Int {
        activePlayers.filter { resolvedScore(for: $0) == 0 }.count
    }

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()

            NavigationStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 14) {
                        if !outPlayers.isEmpty { outSection }
                        ForEach(activePlayers, id: \.self) { name in
                            playerCard(for: name)
                        }
                        if allValid && winnerCount != 1 { warningBanner }
                        Color.clear.frame(height: 32)
                    }
                    .padding(.horizontal)
                    .padding(.top, 14)
                }
                .navigationTitle(editingRound == nil ? "Add Round" : "Edit Round")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.white)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(editingRound == nil ? "Save" : "Update") { saveRound() }
                            .foregroundStyle(allValid ? Theme.gold : .white.opacity(0.4))
                            .fontWeight(.bold)
                            .disabled(!allValid)
                    }
                }
                .onAppear { prepopulate() }
            }
        }
    }

    // MARK: - Sub-views

    private var outSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Already Out")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
            ForEach(outPlayers, id: \.self) { name in
                HStack {
                    Text(name).font(.subheadline).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("OUT")
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.red.opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func playerCard(for name: String) -> some View {
        let total = currentTotals[name] ?? 0
        let selected = selections[name]
        let pts = resolvedScore(for: name)
        let rules = gameRules

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(.headline).foregroundStyle(.white)
                    Text("Total: \(total) pts")
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                if let pts, let type = selected {
                    Text(pts == 0 ? "Won ✓" : "+\(pts)")
                        .font(.title3.bold())
                        .foregroundStyle(type == .won ? .green : Theme.gold)
                }
            }

            HStack(spacing: 8) {
                ForEach([ScoreType.won, .drop, .midDrop, .fullScore, .custom], id: \.label) { type in
                    scoreButton(type: type, name: name, selected: selected, rules: rules)
                }
            }

            if selected == .custom {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.circle.fill").foregroundStyle(.white)
                    TextField("Points", text: Binding(
                        get: { customInputs[name, default: ""] },
                        set: { customInputs[name] = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .focused($focusedCustom, equals: name)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .font(.headline)
                }
                .padding(12)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Theme.buttonDark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.18), value: selected)
    }

    @ViewBuilder
    private func scoreButton(type: ScoreType, name: String, selected: ScoreType?, rules: GameRules) -> some View {
        let isSelected = selected == type
        let pts = type.fixedPoints(rules: rules)
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selections[name] = type
                if type != .custom { customInputs[name] = "" }
                else { focusedCustom = name }
            }
        } label: {
            VStack(spacing: 2) {
                Text(type.label).font(.caption.bold())
                if let pts {
                    Text("\(pts)").font(.system(size: 10)).opacity(0.85)
                } else {
                    Text("manual").font(.system(size: 10)).opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isSelected ? Color.white : Color.white.opacity(0.15))
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.gold)
            Text(winnerCount == 0 ? "No winner set — one player should score Won"
                                  : "Multiple Won — only one player can win a round")
                .font(.caption).foregroundStyle(.white.opacity(0.85))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logic

    private func prepopulate() {
        let rules = gameRules
        guard let round = editingRound else { return }
        for (name, pts) in round.scores {
            switch pts {
            case 0:             selections[name] = .won
            case rules.drop:    selections[name] = .drop
            case rules.midDrop: selections[name] = .midDrop
            case rules.fullScore: selections[name] = .fullScore
            default:
                selections[name] = .custom
                customInputs[name] = "\(pts)"
            }
        }
    }

    private func saveRound() {
        var scores: [String: Int] = [:]
        for name in activePlayers { scores[name] = resolvedScore(for: name) ?? 0 }
        for name in outPlayers { scores[name] = 0 }
        if let round = editingRound {
            store.updateRound(in: gameId, roundId: round.id, scores: scores)
        } else {
            store.addRound(to: gameId, scores: scores)
        }
        dismiss()
    }
}
