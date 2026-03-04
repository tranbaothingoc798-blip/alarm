import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if appVM.showOnboarding {
                OnboardingView()
            } else if appVM.showSetupWizard {
                SetupWizardView()
            } else {
                HomeView()
            }
        }
        .task {
            await appVM.bootstrap(context: context)
        }
        .fullScreenCover(item: $appVM.activeTrigger) { trigger in
            RingingView(alarmID: trigger.id, isTest: trigger.isTest)
        }
    }
}
