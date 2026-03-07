import SwiftUI
import SwiftData

struct PostStopView: View {
    let reason: EmergencyReason
    let dueAt: Date?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Alarm stopped")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("You used Emergency Stop: \(reason.rawValue)")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Make-up mission due \(dueAtText)")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                VStack(spacing: 12) {
                    Button("Go Home") { dismiss() }
                        .accentButton()

                    NavigationLink {
                        StatsView()
                    } label: {
                        Text("View Make-up")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .appBackground()
        }
    }

    private var dueAtText: String {
        if let dueAt { return "at \(dueAt.formatted(date: .omitted, time: .shortened))" }
        return "in 30 minutes"
    }
}
