import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("RISE")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Ruthless but Humane Alarm")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("No snooze. Mission dismissal. Emergency stop always available.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Button("Enable Notifications") {
                        Task {
                            await appVM.requestNotifications(context: context)
                            appVM.showOnboarding = false
                            appVM.showSetupWizard = true
                        }
                    }
                    .accentButton()

                    Button("Continue") {
                        appVM.showOnboarding = false
                        appVM.showSetupWizard = true
                    }
                    .secondaryButton()
                }
                .padding()
                .padding(.bottom, 48)
            }
        }
    }
}
