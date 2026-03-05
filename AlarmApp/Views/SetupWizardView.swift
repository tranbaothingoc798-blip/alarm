import SwiftUI
import SwiftData

struct SetupWizardView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var pendingCount: Int = 0
    @State private var showTestAlarm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    statusCard
                    notificationsCard
                    soundCard
                    testAlarmCard

                    if appVM.notificationStatus == .authorized {
                        schedulerCard
                    }

                    footerAction
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await appVM.refreshNotificationStatus()
                pendingCount = await NotificationScheduler.shared.pendingCount()
            }
            .sheet(isPresented: $showTestAlarm, onDismiss: {
                Task {
                    await appVM.refreshNotificationStatus()
                    pendingCount = await NotificationScheduler.shared.pendingCount()
                }
            }) {
                TestAlarmView()
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appVM.isSetupReady ? "✅ READY" : "⚠️ NEEDS ATTENTION")
                .font(.headline)
            Text("Quick checklist to avoid silent alarms tonight.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var notificationsCard: some View {
        checklistCard(
            title: "Notifications",
            status: statusText,
            actionTitle: notificationCTA,
            action: {
                if appVM.notificationStatus == .notDetermined {
                    Task { await appVM.requestNotifications(context: context) }
                } else if appVM.notificationsDenied {
                    appVM.openSystemSettings()
                }
            }
        )
    }

    private var soundCard: some View {
        checklistCard(
            title: "Sound Test",
            status: appVM.settings?.didCompleteSoundTest == true ? "Completed" : "Not completed",
            actionTitle: "Play Test Sound",
            action: { appVM.playSoundTest(context: context) }
        )
    }

    private var testAlarmCard: some View {
        checklistCard(
            title: "Alarm Check",
            status: appVM.settings?.didCompleteTestAlarm == true ? "Completed" : "Not completed",
            actionTitle: "Run 1-minute proof",
            action: { showTestAlarm = true }
        )
    }

    private var schedulerCard: some View {
        checklistCard(
            title: "Scheduler",
            status: "Pending: \(pendingCount) • Last: \(appVM.settings?.lastSchedulerRebuildAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")",
            actionTitle: "Rebuild Schedule",
            action: {
                Task {
                    await NotificationScheduler.shared.rebuildAllSchedules(context: context)
                    appVM.updateLastSchedulerRebuild(.now, context: context)
                    pendingCount = await NotificationScheduler.shared.pendingCount()
                }
            }
        )
    }

    @ViewBuilder
    private var footerAction: some View {
        if appVM.isSetupReady {
            Button("Done") {
                appVM.showSetupWizard = false
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if appVM.notificationStatus == .authorized {
            Button("Skip for now") {
                appVM.showSetupWizard = false
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private func checklistCard(title: String, status: String, actionTitle: String?, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusText: String {
        switch appVM.notificationStatus {
        case .authorized: return "Enabled"
        case .denied: return "Denied"
        case .notDetermined: return "Not enabled"
        default: return "Limited"
        }
    }

    private var notificationCTA: String? {
        switch appVM.notificationStatus {
        case .notDetermined: return "Enable Notifications"
        case .denied: return "Open Settings"
        default: return nil
        }
    }
}
