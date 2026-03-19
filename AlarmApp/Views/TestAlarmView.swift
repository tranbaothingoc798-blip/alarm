import SwiftUI
import SwiftData

struct TestAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel

    @State private var fireAt = Date().addingTimeInterval(60)
    @State private var now = Date()
    @State private var readiness: AlarmReadinessReport?
    @State private var pendingByPrefix: [String: Int] = [:]

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    readinessCard
                    proofSection
                }
                .padding()
            }
            .navigationTitle("Alarm Check")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { now = $0 }
            .task {
                await refreshReadiness()
            }
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text((readiness?.isReady ?? false) ? "Ready Tomorrow" : "Needs Attention")
                .font(.headline)
            Text(readiness?.summary ?? "Checking system readiness…")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let issues = readiness?.issues.prefix(2), !issues.isEmpty {
                ForEach(Array(issues)) { issue in
                    Text("• \(issue.title)")
                        .font(.footnote)
                }
            }

            if let readiness {
                Text(
                    "alarm_ pending: \(pendingByPrefix[NotificationScheduler.shared.alarmPrefix] ?? 0) • Last rebuild: \(readiness.lastRebuildAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    "Notifications: \(String(describing: readiness.notificationStatus)) • Sound test: \((appVM.settings?.didCompleteSoundTest ?? false) ? "done" : "missing") • Test alarm: \((appVM.settings?.didCompleteTestAlarm ?? false) ? "done" : "missing")"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if appVM.notificationStatus == .notDetermined {
                    Button("Enable notifications") {
                        Task {
                            await appVM.requestNotifications(context: context)
                            await refreshReadiness()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else if appVM.notificationsDenied {
                    Button("Open settings") {
                        appVM.openSystemSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Rebuild schedule") {
                    Task {
                        await NotificationScheduler.shared.rebuildAllSchedules(context: context)
                        appVM.updateLastSchedulerRebuild(.now, context: context)
                        await refreshReadiness()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proof Test (1 minute)")
                .font(.headline)
            Text("Countdown: \(max(0, Int(fireAt.timeIntervalSince(now))))s")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Quiet Proof (no challenge)") {
                scheduleProof(.quiet)
            }
            .buttonStyle(.bordered)

            Button("Full Proof (with challenge)") {
                scheduleProof(.full)
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel test") {
                Task {
                    await NotificationScheduler.shared.cancelTestAlarm()
                    dismiss()
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func scheduleProof(_ type: TestProofType) {
        appVM.setPreferredProofType(type, context: context)
        fireAt = Date().addingTimeInterval(60)
        Task {
            await NotificationScheduler.shared.scheduleTestAlarm(fireAt: fireAt, proofType: type, context: context)
        }
    }

    private func refreshReadiness() async {
        await appVM.refreshNotificationStatus()
        pendingByPrefix = await NotificationScheduler.shared.pendingCountsByPrefix()
        readiness = await AlarmReadinessService().generateReport(context: context)
    }
}
