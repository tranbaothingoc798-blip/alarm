import SwiftUI
import SwiftData
import UserNotifications

struct DiagnosticsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AlarmRun.startedAt, order: .reverse) private var runs: [AlarmRun]
    @Query(sort: \AlarmEventLog.timestamp, order: .reverse) private var logs: [AlarmEventLog]
    @Query private var settingsList: [AppSettings]
    @Query private var alarms: [Alarm]

    @State private var permission: String = "Unknown"
    @State private var pending: Int = 0
    @State private var exportData: Data?
    @State private var showShare = false
    @State private var readiness: AlarmReadinessReport?
    @State private var pendingByPrefix: [String: Int] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section("Readiness") {
                    Text(readiness?.summary ?? "Loading")
                    if let readiness {
                        ForEach(readiness.issues.prefix(3)) { issue in
                            Text("• \(issue.title)")
                                .font(.caption)
                        }
                    }
                }

                Section("State") {
                    Text("Permission: \(permission)")
                    Text("Pending: \(pending)")
                    Text("Pending alarm: \(pendingByPrefix[NotificationScheduler.shared.alarmPrefix] ?? 0)")
                    Text("Pending test: \(pendingByPrefix[NotificationScheduler.shared.testPrefix] ?? 0)")
                    Text("Pending snooze: \(pendingByPrefix[NotificationScheduler.shared.snoozePrefix] ?? 0)")
                    Text("Pending makeup: \(pendingByPrefix[NotificationScheduler.shared.makeupPrefix] ?? 0)")
                    Text("Last rebuild: \(settingsList.first?.lastSchedulerRebuildAt?.formatted() ?? "Never")")
                }

                Section("Recent Runs") {
                    ForEach(Array(runs.prefix(20)), id: \.id) { run in
                        Text("\(run.startedAt.formatted()) → \(run.stopReason?.rawValue ?? "open")")
                    }
                }

                Section("Recent Logs") {
                    ForEach(Array(logs.prefix(50)), id: \.id) { log in
                        Text("\(log.timestamp.formatted(date: .omitted, time: .standard)) • \(log.type.rawValue) \(log.reasonCode ?? "")")
                    }
                }

                Button("Export Diagnostics") {
                    exportData = EventLogger.shared.exportDiagnosticsBundle(
                        runs: Array(runs.prefix(20)),
                        logs: Array(logs.prefix(50)),
                        permission: permission,
                        pendingCount: pending,
                        lastRebuildAt: settingsList.first?.lastSchedulerRebuildAt,
                        readinessSummary: readiness?.summary,
                        readinessIssues: readiness?.issues.map(\.title) ?? [],
                        pendingByPrefix: pendingByPrefix
                    )
                    showShare = exportData != nil
                }

                Button("Rebuild Schedules") {
                    Task {
                        await NotificationScheduler.shared.rebuildSchedule(alarms: alarms, context: context)
                        settingsList.first?.lastSchedulerRebuildAt = .now
                        try? context.save()
                        pending = await NotificationScheduler.shared.pendingCount()
                        pendingByPrefix = await NotificationScheduler.shared.pendingCountsByPrefix()
                        readiness = await AlarmReadinessService().generateReport(context: context)
                    }
                }

                Button("Clear Logs") {
                    logs.forEach { context.delete($0) }
                    try? context.save()
                }
            }
            .navigationTitle("Diagnostics")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .task {
                let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                permission = String(describing: status)
                pending = await NotificationScheduler.shared.pendingCount()
                pendingByPrefix = await NotificationScheduler.shared.pendingCountsByPrefix()
                readiness = await AlarmReadinessService().generateReport(context: context)
            }
            .sheet(isPresented: $showShare) {
                if let exportData {
                    ShareSheet(items: [exportData])
                }
            }
        }
    }
}
