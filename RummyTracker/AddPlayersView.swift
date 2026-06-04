import SwiftUI

struct AddPlayersView: View {
    @Binding var players: [PlayerEntry]
    @Environment(GameStore.self) private var store
    @Environment(ThemeManager.self) private var tm
    var onContinue: () -> Void

    @State private var inputName = ""
    @FocusState private var fieldFocused: Bool

    private var t: ThemeDefinition { tm.theme }

    private var suggestions: [String] {
        store.savedPlayerNames.filter { !players.map(\.name).contains($0) }
    }

    private var activeCount: Int { players.filter(\.isActive).count }
    private var canContinue: Bool { activeCount >= 2 }

    var body: some View {
        ZStack {
            t.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Input row
                inputRow
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                // Player list (fills all remaining space)
                List {
                    // Recent Players section
                    if !suggestions.isEmpty {
                        Section {
                            ForEach(suggestions, id: \.self) { name in
                                Button {
                                    players.append(PlayerEntry(name: name))
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(t.gold)
                                            .font(.title3)
                                        Text(name)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("Add")
                                            .font(.caption.bold())
                                            .foregroundStyle(t.gold)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.white.opacity(0.08))
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text("Recent Players")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.65))
                                .textCase(nil)
                        }
                    }

                    // Added players section
                    if !players.isEmpty {
                        Section {
                            ForEach(players, id: \.id) { player in
                                playerRow(player: player)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            }
                            .onDelete { offsets in
                                players.remove(atOffsets: offsets)
                            }
                        } header: {
                            HStack {
                                Text("\(players.count) added")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.65))
                                Spacer()
                                Text("\(activeCount) in game")
                                    .font(.caption.bold())
                                    .foregroundStyle(t.gold)
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                // Rules button
                continueButton
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("Add Players")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { fieldFocused = true }
    }

    // MARK: - Sub-views

    private var inputRow: some View {
        HStack(spacing: 12) {
            TextField("Enter player name", text: $inputName)
                .focused($fieldFocused)
                .foregroundStyle(.white)
                .tint(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1))
                .submitLabel(.done)
                .onSubmit { addPlayer() }

            Button(action: addPlayer) {
                ZStack {
                    Circle().fill(t.buttonDark).frame(width: 50, height: 50)
                    Image(systemName: "person.badge.plus")
                        .font(.title3).foregroundStyle(.white)
                }
            }
            .disabled(inputName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func playerRow(player: PlayerEntry) -> some View {
        // Safe index lookup — avoids crash when delete animates
        let index = players.firstIndex(where: { $0.id == player.id })

        let isActive = index.map { players[$0].isActive } ?? player.isActive
        let bgFill: Color = isActive ? Color.red.opacity(0.22) : Color.white.opacity(0.06)
        let borderColor: Color = isActive ? Color.pink.opacity(0.7) : Color.white.opacity(0.15)
        let displayIndex = (index ?? 0) + 1

        return HStack(spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(isActive ? t.gold.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                Text("\(displayIndex)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isActive ? t.gold : .white.opacity(0.4))
            }

            // Name
            Text(player.name)
                .font(.title3.bold())
                .foregroundStyle(isActive ? .white : .white.opacity(0.35))
                .strikethrough(!isActive, color: .white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Toggle with In/Out label
            VStack(spacing: 2) {
                Toggle("", isOn: Binding(
                    get: { index.map { players[$0].isActive } ?? false },
                    set: { val in if let i = index { players[i].isActive = val } }
                ))
                .labelsHidden()
                .tint(t.gold)
                Text(isActive ? "In" : "Out")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isActive ? t.gold : .white.opacity(0.4))
            }

            // Delete button
            Button {
                if let i = index { players.remove(at: i) }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.red.opacity(0.75))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(bgFill))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill").font(.title2)
                Text("Rules").font(.headline)
            }
            .foregroundStyle(canContinue ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canContinue ? t.buttonDark : t.buttonDark.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canContinue)
    }

    // MARK: - Actions

    private func addPlayer() {
        let name = inputName.trimmingCharacters(in: .whitespaces).uppercased()
        guard !name.isEmpty else { return }
        players.append(PlayerEntry(name: name))
        inputName = ""
        fieldFocused = true
    }
}
