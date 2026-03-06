import SwiftUI
import UserNotifications
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var alarms: [Alarm]

    @State private var permissionText = "Unknown"
    @State private var pendingCount = 0
    @State private var rebuiltAt: Date?
    @State private var tapCount = 0
    @State private var firstTapDate: Date?
    @State private var showDiagnostics = false
    @State private var showSetup = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                alarmHealthCard

                VStack(spacing: 0) {
                    Button {
                        showSetup = true
                    } label: {
                        settingsRow(title: "Run Setup Wizard", icon: "checkmark.shield")
                    }

                    NavigationLink {
                        StatsView()
                    } label: {
                        settingsRow(title: "Stats", icon: "chart.bar")
                    }

                    Button {
                        Task {
                            await NotificationScheduler.shared.rebuildSchedule(alarms: alarms, context: context)
                            appVM.updateLastSchedulerRebuild(.now, context: context)
                            await refreshHealth()
                        }
                    } label: {
                        settingsRow(title: "Restore Schedule", icon: "arrow.triangle.2.circlepath")
                    }
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.headline)
                    .onTapGesture { registerTap() }
            }
        }
        .task { await refreshHealth() }
        .sheet(isPresented: $showDiagnostics) { DiagnosticsView() }
        .sheet(isPresented: $showSetup) { SetupWizardView() }
    }

    private var alarmHealthCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alarm Health")
                .font(.headline)
            Text("Permission: \(permissionText)")
                .font(.subheadline)
            Text("Pending: \(pendingCount)")
                .font(.subheadline)
            Text("Rebuilt: \(rebuiltAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingsRow(title: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func registerTap() {
        let now = Date()
        if let first = firstTapDate, now.timeIntervalSince(first) > 1.5 {
            firstTapDate = now
            tapCount = 1
            return
        }
        if firstTapDate == nil { firstTapDate = now }
        tapCount += 1
        if tapCount >= 5 {
            showDiagnostics = true
            tapCount = 0
            firstTapDate = nil
        }
    }

    private func refreshHealth() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionText = settings.authorizationStatus == .authorized ? "Authorized" : "Denied/Not determined"
        pendingCount = await NotificationScheduler.shared.pendingCount()
        rebuiltAt = appVM.settings?.lastSchedulerRebuildAt ?? NotificationScheduler.shared.lastRebuild
    }
}
