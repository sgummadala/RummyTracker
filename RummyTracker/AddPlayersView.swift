import SwiftUI

struct AddPlayersView: View {
    @Binding var players: [PlayerEntry]
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void

    @State private var inputName = ""
    @FocusState private var fieldFocused: Bool

    private var canContinue: Bool {
        players.filter(\.isActive).filter { !$0.name.isEmpty }.count >= 2
    }

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()

            VStack(spacing: 20) {
                // Name input row
                HStack(spacing: 12) {
                    TextField("Enter player name", text: $inputName)
                        .focused($fieldFocused)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .submitLabel(.done)
                        .onSubmit { addPlayer() }

                    Button(action: addPlayer) {
                        ZStack {
                            Circle()
                                .fill(Theme.buttonDark)
                                .frame(width: 50, height: 50)
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(inputName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)

                // Player list
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            playerRow(index: index, player: player)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                        Text("Rules")
                            .font(.headline)
                    }
                    .foregroundStyle(canContinue ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? Theme.buttonDark : Theme.buttonDark.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canContinue)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Add Players")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { fieldFocused = true }
    }

    private func addPlayer() {
        let name = inputName.trimmingCharacters(in: .whitespaces).uppercased()
        guard !name.isEmpty else { return }
        players.append(PlayerEntry(name: name))
        inputName = ""
        fieldFocused = true
    }

    private func playerRow(index: Int, player: PlayerEntry) -> some View {
        HStack(spacing: 16) {
            Text("\(index + 1). \(player.name)")
                .font(.title3.bold())
                .foregroundStyle(player.isActive ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { players[index].isActive },
                set: { players[index].isActive = $0 }
            ))
            .labelsHidden()
            .tint(.green)

            Button {
                players.remove(at: index)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                                           startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.5
                        )
                )
        )
    }
}
