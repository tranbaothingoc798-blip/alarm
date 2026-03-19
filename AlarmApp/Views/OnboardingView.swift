import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 16) {
            Text("Ruthless but Humane Alarm")
                .font(.largeTitle.bold())
            Text("No snooze. Mission dismissal. Emergency stop always available.")
                .multilineTextAlignment(.center)

            Button("Enable Notifications") {
                Task {
                    await appVM.requestNotifications(context: context)
                    appVM.showOnboarding = false
                    appVM.showSetupWizard = true
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Continue") {
                appVM.showOnboarding = false
                appVM.showSetupWizard = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
