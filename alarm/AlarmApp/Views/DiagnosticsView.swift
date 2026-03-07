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
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Readiness") {
                        Text(readiness?.summary ?? "Loading")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textPrimary)
                        if let readiness {
                            ForEach(readiness.issues.prefix(3)) { issue in
                                Text("• \(issue.title)")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    sectionCard(title: "State") {
                        diagnosticRow("Permission", permission)
                        diagnosticRow("Pending", "\(pending)")
                        diagnosticRow("Proof mode", settingsList.first?.preferredProofTypeRaw ?? TestProofType.full.rawValue)
                        diagnosticRow("Pending alarm", "\(pendingByPrefix[NotificationScheduler.shared.alarmPrefix] ?? 0)")
                        diagnosticRow("Last rebuild", settingsList.first?.lastSchedulerRebuildAt?.formatted() ?? "Never")
                    }

                    sectionCard(title: "Recent Runs") {
                        ForEach(Array(runs.prefix(20)), id: \.id) { run in
                            Text("\(run.startedAt.formatted()) → \(run.stopReason?.rawValue ?? "open")")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    VStack(spacing: 10) {
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
                        .secondaryButton()

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
                        .secondaryButton()

                        Button("Clear Logs") {
                            logs.forEach { context.delete($0) }
                            try? context.save()
                        }
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Diagnostics")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
}
