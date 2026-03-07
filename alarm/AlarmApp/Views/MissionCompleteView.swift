import SwiftUI

struct MissionCompleteView: View {
    let plan: MissionPlan
    let completedAt: Date
    let isTest: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 100, height: 100)
                        .glowModifier(radius: 20, opacity: 0.5)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.background)
                }

                Text("Mission Complete")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("You've conquered the wake-up challenge")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("Completed at \(completedAt.formatted(date: .omitted, time: .shortened))")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                missionsCompletedCard

                HStack(spacing: 4) {
                    Text("Your day has begun with ")
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("intention.")
                        .foregroundStyle(AppTheme.accent)
                }
                .font(AppTheme.bodyFont)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("Back to Alarms")
                    }
                    .accentButton()
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    private var missionsCompletedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Missions Completed")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(plan.stages.count)/\(plan.stages.count)")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(AppTheme.accent)
            }

            ForEach(plan.stages, id: \.id) { stage in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(missionDisplayName(stage.missionType))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func missionDisplayName(_ type: MissionType) -> String {
        switch type {
        case .typing: return "Typing Challenge"
        case .math: return "Math Challenge"
        case .shake: return "Shake to Wake"
        case .steps: return "Steps"
        case .barcode: return "Barcode Scan"
        case .memory: return "Pattern Memory"
        }
    }
}
