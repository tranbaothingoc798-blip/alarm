import SwiftUI

struct EmergencyStopSheet: View {
    let onConfirm: (EmergencyReason) -> Void
    @State private var selected: EmergencyReason = .exhausted

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Emergency Stop")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Select a reason, then hold to confirm")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Picker("Reason", selection: $selected) {
                    ForEach(EmergencyReason.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.wheel)
                .colorMultiply(AppTheme.textPrimary)

                Text("Hold 2 seconds to stop")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Button("Hold to Stop") {}
                    .accentButton()
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 2)
                            .onEnded { _ in
                                onConfirm(selected)
                            }
                    )
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .appBackground()
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
