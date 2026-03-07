import SwiftUI
import SwiftData

@main
struct AlarmAppMain: App {
    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appVM)
                .modelContainer(for: [Alarm.self, AlarmRun.self, AlarmEventLog.self, MakeUpTask.self, AppSettings.self])
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
        }
    }
}
