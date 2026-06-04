import SwiftUI

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var tm
    @Environment(\.dismiss) private var dismiss

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            tm.theme.gradient.ignoresSafeArea()

            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(ThemeDefinition.all) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: tm.theme.id == theme.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    tm.select(theme)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Choose Theme")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

struct ThemeCard: View {
    let theme: ThemeDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    // Full gradient preview
                    theme.gradient
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Mini score table
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(theme.tableNavy)
                                .frame(width: 22)
                            Rectangle()
                                .fill(theme.tableGreen)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 14)
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(theme.tableNavy)
                                .frame(width: 22)
                            Rectangle()
                                .fill(theme.tableGreenLight)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 12)
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(theme.tableNavy)
                                .frame(width: 22)
                            Rectangle()
                                .fill(theme.tableGreen)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(width: 80, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.3), lineWidth: 0.5))

                    // Selected ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.gold, lineWidth: 3)
                    }

                    // Checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(theme.gold)
                                    .background(Circle().fill(Color.black.opacity(0.4)).padding(2))
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 110)

                VStack(spacing: 3) {
                    Text(theme.emoji + " " + theme.name)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    // Accent color dot
                    Circle()
                        .fill(theme.gold)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
