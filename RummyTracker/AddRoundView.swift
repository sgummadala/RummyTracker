import SwiftUI

enum ScoreType: Equatable {
    case won, drop, midDrop, custom

    var label: String {
        switch self {
        case .won: return "Won"
        case .drop: return "Drop"
        case .midDrop: return "Mid"
        case .custom: return "Count"
        }
    }

    var subtitle: String {
        switch self {
        case .won: return "0 pts"
        case .drop: return "\(RummyRules.drop) pts"
        case .midDrop: return "\(RummyRules.midDrop) pts"
        case .custom: return "enter"
        }
    }

    var fixedPoints: Int? {
        switch self {
        case .won: return 0
        case .drop: return RummyRules.drop
        case .midDrop: return RummyRules.midDrop
        case .custom: return nil
        }
    }

    var accentColor: Color {
        switch self {
        case .won: return .green
        case .drop: return .orange
        case .midDrop: return .orange
        case .custom: return .red
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

    private var activePlayers: [String] {
        playerNames.filter { (currentTotals[$0] ?? 0) < RummyRules.outThreshold }
    }

    private var outPlayers: [String] {
        playerNames.filter { (currentTotals[$0] ?? 0) >= RummyRules.outThreshold }
    }

    private func resolvedScore(for name: String) -> Int? {
        guard let type = selections[name] else { return nil }
        if let pts = type.fixedPoints { return pts }
        return Int(customInputs[name, default: ""].trimmingCharacters(in: .whitespaces))
    }

    private var allValid: Bool {
        activePlayers.allSatisfy { resolvedScore(for: $0) != nil }
    }

    private var winnerCount: Int {
        activePlayers.filter { resolvedScore(for: $0) == 0 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if !outPlayers.isEmpty {
                        outSection
                    }
                    ForEach(activePlayers, id: \.self) { name in
                        playerCard(for: name)
                    }
                    if allValid && winnerCount != 1 {
                        warningBanner
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(editingRound == nil ? "Add Round" : "Edit Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingRound == nil ? "Save" : "Update") { saveRound() }
                        .fontWeight(.bold)
                        .disabled(!allValid)
                }
            }
            .onAppear { prepopulate() }
        }
    }

    // MARK: - Sub-views

    private var outSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Already Out")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            ForEach(outPlayers, id: \.self) { name in
                HStack {
                    Text(name).font(.subheadline)
                    Spacer()
                    Text("OUT")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.red)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    @ViewBuilder
    private func playerCard(for name: String) -> some View {
        let total = currentTotals[name] ?? 0
        let selected = selections[name]
        let pts = resolvedScore(for: name)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(.headline)
                    Text("Total: \(total) pts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let pts, let type = selected {
                    Text(pts == 0 ? "Won ✓" : "+\(pts)")
                        .font(.title3.bold())
                        .foregroundStyle(type.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: 8) {
                ForEach([ScoreType.won, .drop, .midDrop, .custom], id: \.label) { type in
                    scoreTypeButton(type: type, name: name, selected: selected)
                }
            }

            if selected == .custom {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.indigo)
                    TextField("Enter points", text: Binding(
                        get: { customInputs[name, default: ""] },
                        set: { customInputs[name] = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .focused($focusedCustom, equals: name)
                    .font(.headline)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }

    @ViewBuilder
    private func scoreTypeButton(type: ScoreType, name: String, selected: ScoreType?) -> some View {
        let isSelected = selected == type
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selections[name] = type
                if type != .custom { customInputs[name] = "" }
                else { focusedCustom = name }
            }
        } label: {
            VStack(spacing: 3) {
                Text(type.label)
                    .font(.caption.bold())
                Text(type.subtitle)
                    .font(.system(size: 10))
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? type.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(winnerCount == 0
                 ? "No winner set — one player should score Won"
                 : "Multiple Won — only one player can win a round")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logic

    private func prepopulate() {
        guard let round = editingRound else { return }
        for (name, pts) in round.scores {
            switch pts {
            case 0: selections[name] = .won
            case RummyRules.drop: selections[name] = .drop
            case RummyRules.midDrop: selections[name] = .midDrop
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
