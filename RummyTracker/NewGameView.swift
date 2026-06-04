import SwiftUI

struct NewGameView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var playerNames: [String] = ["", ""]
    @State private var targetScore = 101
    @FocusState private var focusedIndex: Int?

    private let targetOptions = [101, 201]

    private var validNames: [String] {
        playerNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private var canStart: Bool {
        validNames.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(playerNames.indices, id: \.self) { index in
                        HStack {
                            TextField("Player \(index + 1)", text: $playerNames[index])
                                .focused($focusedIndex, equals: index)
                                .submitLabel(index < playerNames.count - 1 ? .next : .done)
                                .onSubmit {
                                    if index < playerNames.count - 1 {
                                        focusedIndex = index + 1
                                    }
                                }
                            if playerNames.count > 2 {
                                Button {
                                    playerNames.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if playerNames.count < 6 {
                        Button {
                            playerNames.append("")
                            focusedIndex = playerNames.count - 1
                        } label: {
                            Label("Add Player", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Players")
                } footer: {
                    Text("2 to 6 players")
                }

                Section {
                    Picker("Points limit", selection: $targetScore) {
                        ForEach(targetOptions, id: \.self) { score in
                            Text("\(score) points").tag(score)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Target Score")
                } footer: {
                    Text("Game ends when a player reaches \(targetScore) points. Player with the lowest total wins.")
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        store.startGame(playerNames: validNames, targetScore: targetScore)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canStart)
                }
            }
            .onAppear {
                focusedIndex = 0
            }
        }
    }
}
