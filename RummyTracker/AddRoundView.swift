import SwiftUI

struct AddRoundView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let gameId: UUID
    let playerNames: [String]
    let currentTotals: [String: Int]

    @State private var inputs: [String: String] = [:]
    @FocusState private var focusedPlayer: String?

    private var parsedScores: [String: Int] {
        Dictionary(uniqueKeysWithValues: playerNames.map { name in
            (name, Int(inputs[name, default: ""].trimmingCharacters(in: .whitespaces)) ?? -1)
        })
    }

    private var allValid: Bool {
        parsedScores.values.allSatisfy { $0 >= 0 }
    }

    private var winnerCount: Int {
        parsedScores.values.filter { $0 == 0 }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Enter points lost by each player. Enter **0** for the round winner.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Round Scores") {
                    ForEach(Array(playerNames.enumerated()), id: \.element) { _, name in
                        playerRow(name: name)
                    }
                }

                if winnerCount != 1 && allValid {
                    Section {
                        Label(
                            winnerCount == 0 ? "No round winner set (someone should have 0)" : "Multiple players have 0 — only one can win a round",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Add Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let scores = Dictionary(uniqueKeysWithValues: playerNames.map { name in
                            (name, Int(inputs[name, default: "0"].trimmingCharacters(in: .whitespaces)) ?? 0)
                        })
                        store.addRound(to: gameId, scores: scores)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!allValid)
                }
            }
            .onAppear {
                focusedPlayer = playerNames.first
            }
        }
    }

    @ViewBuilder
    private func playerRow(name: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                let total = currentTotals[name] ?? 0
                Text("Total so far: \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            TextField("0", text: Binding(
                get: { inputs[name, default: ""] },
                set: { inputs[name] = $0 }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 70)
            .focused($focusedPlayer, equals: name)
        }
    }
}
