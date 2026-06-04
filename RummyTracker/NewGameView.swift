import SwiftUI

struct NewGameView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var playerNames: [String] = ["", ""]
    @FocusState private var focusedIndex: Int?

    private var validNames: [String] {
        playerNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private var canStart: Bool { validNames.count >= 2 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                Form {
                    Section {
                        ForEach(playerNames.indices, id: \.self) { index in
                            playerRow(index: index)
                        }
                        if playerNames.count < RummyRules.maxPlayers {
                            Button {
                                playerNames.append("")
                                focusedIndex = playerNames.count - 1
                            } label: {
                                Label("Add Player", systemImage: "plus.circle.fill")
                                    .foregroundStyle(.indigo)
                            }
                        }
                    } header: {
                        Text("Players — \(validNames.count) of \(RummyRules.maxPlayers)")
                    } footer: {
                        Text("Minimum 2, maximum \(RummyRules.maxPlayers) players.")
                    }

                    Section("Rules") {
                        ruleRow(icon: "target", label: "Target", value: "\(RummyRules.target) points")
                        ruleRow(icon: "xmark.circle", label: "Out at", value: "\(RummyRules.outThreshold) points")
                        ruleRow(icon: "arrow.down.circle", label: "Drop", value: "\(RummyRules.drop) points")
                        ruleRow(icon: "arrow.down.circle.fill", label: "Mid Drop", value: "\(RummyRules.midDrop) points")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game") {
                        store.startGame(playerNames: validNames)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canStart)
                }
            }
            .onAppear { focusedIndex = 0 }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "suit.club.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 2) {
                Text("New Game")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Indian Rummy · 250 points")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [.indigo, .purple],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    @ViewBuilder
    private func playerRow(index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 30, height: 30)
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(.indigo)
            }
            TextField("Player \(index + 1)", text: $playerNames[index])
                .focused($focusedIndex, equals: index)
                .submitLabel(index < playerNames.count - 1 ? .next : .done)
                .onSubmit {
                    if index < playerNames.count - 1 { focusedIndex = index + 1 }
                }
            if playerNames.count > 2 {
                Button {
                    playerNames.remove(at: index)
                } label: {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ruleRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}
