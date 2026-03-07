import SwiftUI

struct FallbackChoiceView: View {
    let onSelect: (MissionType) -> Void

    private let options: [MissionType] = [.math, .typing, .shake, .memory]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Choose a one-time fallback mission")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    ForEach(options, id: \.id) { type in
                        Button {
                            onSelect(type)
                        } label: {
                            HStack {
                                Text(missionLabel(type))
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("One-time fallback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
        }
    }

    private func missionLabel(_ type: MissionType) -> String {
        switch type {
        case .typing: return "Typing Challenge"
        case .math: return "Math Challenge"
        case .shake: return "Shake to Wake"
        case .memory: return "Pattern Memory"
        default: return type.rawValue.capitalized
        }
    }
}
