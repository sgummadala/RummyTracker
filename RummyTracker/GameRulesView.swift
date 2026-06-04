import SwiftUI

struct GameRulesView: View {
    @Binding var rules: GameRules
    let players: [PlayerEntry]
    var onStart: () -> Void

    @State private var dropText: String = ""
    @State private var midDropText: String = ""
    @State private var fullScoreText: String = ""
    @State private var gameScoreText: String = ""

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 24) {
                    Text("Game Rules")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    VStack(spacing: 16) {
                        ruleField(label: "Drop", text: $dropText)
                        ruleField(label: "Mid Drop", text: $midDropText)
                        ruleField(label: "Full Score", text: $fullScoreText)
                        ruleField(label: "Game Score", text: $gameScoreText)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    applyRules()
                    onStart()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                        Text("Scores")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.buttonDark)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Set Game Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            dropText = "\(rules.drop)"
            midDropText = "\(rules.midDrop)"
            fullScoreText = "\(rules.fullScore)"
            gameScoreText = "\(rules.gameScore)"
        }
    }

    private func ruleField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.body.bold())
                .foregroundStyle(.white)
                .frame(width: 110, alignment: .leading)

            TextField("", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .tint(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private func applyRules() {
        rules.drop = Int(dropText) ?? rules.drop
        rules.midDrop = Int(midDropText) ?? rules.midDrop
        rules.fullScore = Int(fullScoreText) ?? rules.fullScore
        rules.gameScore = Int(gameScoreText) ?? rules.gameScore
    }
}
