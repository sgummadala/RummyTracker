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
                    .padding(.bottom, 12)

                // Recent player chips
                if !suggestions.isEmpty {
                    recentPlayersRow
                        .padding(.bottom, 8)
                }

                // Player count header
                if !players.isEmpty {
                    HStack {
                        Text("\(players.count) added")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        Text("\(activeCount) in game")
                            .font(.caption.bold())
                            .foregroundStyle(t.gold)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }

                // Player list — List expands to fill remaining space
                List {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, _ in
                        playerRow(index: index)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                    .onDelete { players.remove(atOffsets: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Continue button
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

    private var recentPlayersRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Players")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.65))
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { name in
                        Button {
                            players.append(PlayerEntry(name: name))
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus.circle.fill").font(.caption2)
                                Text(name).font(.subheadline.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func playerRow(index: Int) -> some View {
        let player = players[index]
        let bgFill: Color = player.isActive ? Color.red.opacity(0.22) : Color.white.opacity(0.06)
        let borderColor: Color = player.isActive ? Color.pink.opacity(0.7) : Color.white.opacity(0.15)
        return HStack(spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(player.isActive ? t.gold.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.subheadline.bold())
                    .foregroundStyle(player.isActive ? t.gold : .white.opacity(0.4))
            }

            // Name
            Text(player.name)
                .font(.title3.bold())
                .foregroundStyle(player.isActive ? .white : .white.opacity(0.35))
                .strikethrough(!player.isActive, color: .white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .leading)

            // In/Out toggle
            VStack(spacing: 2) {
                Toggle("", isOn: Binding(
                    get: { players[index].isActive },
                    set: { players[index].isActive = $0 }
                ))
                .labelsHidden()
                .tint(t.gold)
                Text(player.isActive ? "In" : "Out")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(player.isActive ? t.gold : .white.opacity(0.4))
            }

            // Delete button
            Button {
                withAnimation { _ = players.remove(at: index) }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.75))
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
