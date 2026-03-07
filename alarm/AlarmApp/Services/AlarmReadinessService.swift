import Foundation
import SwiftData
import UserNotifications

@MainActor
final class AlarmReadinessService {
    private let scheduler: NotificationScheduler
    private let notificationStatusProvider: () async -> UNAuthorizationStatus
    private let prefixCountsProvider: () async -> [String: Int]
    private let totalPendingProvider: () async -> Int

    init(
        scheduler: NotificationScheduler = .shared,
        notificationStatusProvider: @escaping () async -> UNAuthorizationStatus = {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        },
        prefixCountsProvider: (() async -> [String: Int])? = nil,
        totalPendingProvider: (() async -> Int)? = nil
    ) {
        self.scheduler = scheduler
        self.notificationStatusProvider = notificationStatusProvider
        self.prefixCountsProvider = prefixCountsProvider ?? { await scheduler.pendingCountsByPrefix() }
        self.totalPendingProvider = totalPendingProvider ?? { await scheduler.pendingCount() }
    }

    func generateReport(context: ModelContext) async -> AlarmReadinessReport {
        let settings = AppSettings.fetchOrCreate(in: context)
        let status = await notificationStatusProvider()
        let pending = await totalPendingProvider()
        let counts = await prefixCountsProvider()
        let alarmPending = counts[scheduler.alarmPrefix] ?? 0
        let testPending = counts[scheduler.testPrefix] ?? 0
        let snoozePending = counts[scheduler.snoozePrefix] ?? 0
        let makeupPending = counts[scheduler.makeupPrefix] ?? 0

        let alarms = AlarmRepository.fetchAll(context: context)
        let enabled = alarms.filter { $0.isEnabled }
        let validNext = enabled.filter { $0.nextOccurrence() != nil }

        var issues: [AlarmReadinessIssue] = []

        if status != .authorized {
            issues.append(
                AlarmReadinessIssue(
                    title: "Notifications are off",
                    detail: "Alarm notifications must be enabled to ring reliably.",
                    severity: .critical,
                    action: status == .denied ? .openSystemSettings : .enableNotifications,
                    reason: .notificationsDenied
                )
            )
        }

        if enabled.isEmpty {
            issues.append(
                AlarmReadinessIssue(
                    title: "No enabled alarms",
                    detail: "Enable at least one alarm for tonight.",
                    severity: .critical,
                    action: .none,
                    reason: .noEnabledAlarms
                )
            )
        } else if validNext.isEmpty {
            issues.append(
                AlarmReadinessIssue(
                    title: "Invalid schedule",
                    detail: "Enabled alarms have no valid next occurrence.",
                    severity: .critical,
                    action: .none,
                    reason: .invalidNextOccurrence
                )
            )
        }

        if alarmPending == 0 {
            issues.append(
                AlarmReadinessIssue(
                    title: "No alarm notifications scheduled",
                    detail: "Rebuild the alarm schedule before sleep.",
                    severity: .critical,
                    action: .rebuildSchedule,
                    reason: .scheduleEmpty
                )
            )
        }

        let isStale = settings.lastSchedulerRebuildAt == nil || (settings.lastSchedulerRebuildAt?.timeIntervalSinceNow ?? -.infinity) < -(7 * 24 * 60 * 60)
        if isStale {
            issues.append(
                AlarmReadinessIssue(
                    title: "Scheduler stale",
                    detail: "Rebuild schedules to ensure tonight's notifications are fresh.",
                    severity: alarmPending == 0 ? .critical : .warning,
                    action: .rebuildSchedule,
                    reason: .schedulerStale
                )
            )
        }

        if !settings.didCompleteSoundTest {
            issues.append(
                AlarmReadinessIssue(
                    title: "Sound not tested",
                    detail: "Run sound test once to verify output volume.",
                    severity: .warning,
                    action: .playTestSound,
                    reason: .soundNotTested
                )
            )
        }

        if !settings.didCompleteTestAlarm {
            issues.append(
                AlarmReadinessIssue(
                    title: "Test alarm not run",
                    detail: "Run a 2-minute proof alarm at least once.",
                    severity: .warning,
                    action: .runTestAlarm,
                    reason: .testNotRun
                )
            )
        }

        let isReady = !issues.contains(where: { $0.severity == .critical })
        let nextAlarm = AlarmRepository.nextUpcomingOccurrence(context: context)
        let report = AlarmReadinessReport(
            isReady: isReady,
            summary: isReady ? "Ready Tonight" : "Needs attention",
            issues: issues,
            pendingCount: pending,
            lastRebuildAt: settings.lastSchedulerRebuildAt,
            notificationStatus: status,
            nextAlarmAt: nextAlarm?.date
        )

        EventLogger.shared.logJSON(
            .readinessComputed,
            reason: isReady ? nil : .unknown,
            payload: [
                "summary": report.summary,
                "isReady": report.isReady,
                "pendingCount": report.pendingCount,
                "alarmPending": alarmPending,
                "testPending": testPending,
                "snoozePending": snoozePending,
                "makeupPending": makeupPending,
                "issueCount": report.issues.count,
                "issues": report.issues.map { $0.reason.rawValue }
            ],
            context: context
        )
        return report
    }
}
