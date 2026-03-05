import Foundation
import UserNotifications
import SwiftData

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    private let budgeter = NotificationBudgeter()
    private(set) var lastRebuild: Date?
    private(set) var cachedPendingCount: Int = 0

    let alarmPrefix = "alarm_"
    let testPrefix = "test_"
    let makeupPrefix = "makeup_"
    let snoozePrefix = "snooze_"

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func rebuildAllSchedules(context: ModelContext) async {
        let alarms = (try? context.fetch(FetchDescriptor<Alarm>())) ?? []
        await rebuildSchedule(alarms: alarms, context: context)
    }

    func rebuildSchedule(alarms: [Alarm], context: ModelContext) async {
        await removeManagedPendingRequests()

        let budgeted = budgeter.budgetedOccurrences(from: alarms)
        let targetRequestCount = budgeted.count * budgeter.escalations.count
        if targetRequestCount > budgeter.maxPending {
            EventLogger.shared.logJSON(
                .schedulerWarning,
                reason: .budgetTruncated,
                payload: [
                    "warning": "budget_truncated",
                    "targetRequestCount": targetRequestCount,
                    "maxPending": budgeter.maxPending
                ],
                context: context
            )
        }

        for (alarm, date) in budgeted {
            for sec in budgeter.escalations {
                let triggerDate = date.addingTimeInterval(TimeInterval(sec))
                let content = UNMutableNotificationContent()
                content.title = alarm.label.isEmpty ? "Alarm" : alarm.label
                content.body = sec == 0 ? "Mission required to dismiss" : "Escalation \(sec)s"
                content.sound = .default

                let identifier = "\(alarmPrefix)\(alarm.id.uuidString)_\(Int(triggerDate.timeIntervalSince1970))_e\(sec)"
                content.userInfo = ["alarmID": alarm.id.uuidString, "escalation": sec, "requestId": identifier]

                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
                try? await center.add(request)

                EventLogger.shared.logJSON(
                    .alarmScheduled,
                    alarmID: alarm.id,
                    payload: [
                        "scheduledFor": isoString(date),
                        "triggerDate": isoString(triggerDate),
                        "escalationSec": sec,
                        "requestId": identifier,
                        "alarmId": alarm.id.uuidString,
                        "type": "alarm"
                    ],
                    context: context
                )
            }
        }

        lastRebuild = .now
        cachedPendingCount = await pendingCount()
    }

    func scheduleTestAlarm(fireAt: Date, proofType: TestProofType, context: ModelContext? = nil) async {
        await cancelTestAlarm()
        var remaining = max(0, budgeter.maxPending - (await pendingCount()))
        for sec in budgeter.escalations where remaining > 0 {
            let triggerDate = fireAt.addingTimeInterval(TimeInterval(sec))
            let content = UNMutableNotificationContent()
            content.title = "Test Alarm"
            content.body = sec == 0 ? "Test ringing starts now" : "Test escalation \(sec)s"
            content.sound = .default
            let identifier = "\(testPrefix)alarm_\(Int(triggerDate.timeIntervalSince1970))_e\(sec)"
            content.userInfo = [
                "isTestAlarm": true,
                "proofType": proofType.rawValue,
                "escalation": sec,
                "requestId": identifier
            ]
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(request)
            remaining -= 1

            if let context {
                EventLogger.shared.logJSON(
                    .alarmTestScheduled,
                    payload: [
                        "triggerDate": isoString(triggerDate),
                        "escalationSec": sec,
                        "requestId": identifier,
                        "type": "test",
                        "proofType": proofType.rawValue
                    ],
                    context: context
                )
            }
        }
        cachedPendingCount = await pendingCount()
    }

    func scheduleSnooze(alarm: Alarm, runID: UUID, fireAt: Date, context: ModelContext) async {
        var remaining = max(0, budgeter.maxPending - (await pendingCount()))
        guard remaining > 0 else {
            EventLogger.shared.logJSON(
                .alarmScheduled,
                runID: runID,
                alarmID: alarm.id,
                reason: .budgetTruncated,
                payload: ["warning": "snooze_not_scheduled_budget_exceeded"],
                context: context
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm Snooze" : "\(alarm.label) (Snooze)"
        content.body = "Snooze complete. Mission required."
        content.sound = .default
        let identifier = "\(snoozePrefix)\(runID.uuidString)_\(Int(fireAt.timeIntervalSince1970))"
        content.userInfo = ["alarmID": alarm.id.uuidString, "runID": runID.uuidString, "isSnooze": true, "requestId": identifier, "escalation": 0]
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireAt)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        try? await center.add(request)
        remaining -= 1

        EventLogger.shared.logJSON(
            .alarmScheduled,
            runID: runID,
            alarmID: alarm.id,
            payload: [
                "scheduledFor": isoString(fireAt),
                "triggerDate": isoString(fireAt),
                "escalationSec": 0,
                "requestId": identifier,
                "alarmId": alarm.id.uuidString,
                "type": "snooze"
            ],
            context: context
        )

        if remaining > 0 {
            let escalationDate = fireAt.addingTimeInterval(15)
            let eId = "\(snoozePrefix)\(runID.uuidString)_\(Int(escalationDate.timeIntervalSince1970))_e15"
            let eContent = UNMutableNotificationContent()
            eContent.title = alarm.label.isEmpty ? "Alarm Snooze" : "\(alarm.label) (Snooze)"
            eContent.body = "Snooze escalation"
            eContent.sound = .default
            eContent.userInfo = ["alarmID": alarm.id.uuidString, "runID": runID.uuidString, "isSnooze": true, "requestId": eId, "escalation": 15]
            let eComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: escalationDate)
            let eReq = UNNotificationRequest(identifier: eId, content: eContent, trigger: UNCalendarNotificationTrigger(dateMatching: eComps, repeats: false))
            try? await center.add(eReq)

            EventLogger.shared.logJSON(
                .alarmScheduled,
                runID: runID,
                alarmID: alarm.id,
                payload: [
                    "scheduledFor": isoString(fireAt),
                    "triggerDate": isoString(escalationDate),
                    "escalationSec": 15,
                    "requestId": eId,
                    "alarmId": alarm.id.uuidString,
                    "type": "snooze"
                ],
                context: context
            )
        }

        cachedPendingCount = await pendingCount()
    }

    func cancelTestAlarm() async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(testPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        cachedPendingCount = await pendingCount()
    }

    func cancelPendingAlarms(for alarmID: UUID) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(alarmPrefix) && $0.contains("\(alarmPrefix)\(alarmID.uuidString)_") }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        cachedPendingCount = await pendingCount()
    }

    func cancelPendingSnoozes(for runID: UUID) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(snoozePrefix) && $0.contains("\(snoozePrefix)\(runID.uuidString)_") }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        cachedPendingCount = await pendingCount()
    }

    func pendingCountsByPrefix() async -> [String: Int] {
        let requests = await center.pendingNotificationRequests()
        return [
            alarmPrefix: requests.filter { $0.identifier.hasPrefix(alarmPrefix) }.count,
            testPrefix: requests.filter { $0.identifier.hasPrefix(testPrefix) }.count,
            snoozePrefix: requests.filter { $0.identifier.hasPrefix(snoozePrefix) }.count,
            makeupPrefix: requests.filter { $0.identifier.hasPrefix(makeupPrefix) }.count
        ]
    }

    func pendingCount() async -> Int {
        let count = await center.pendingNotificationRequests().count
        cachedPendingCount = count
        return count
    }

    private func removeManagedPendingRequests() async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter {
            $0.hasPrefix(alarmPrefix) || $0.hasPrefix(testPrefix) || $0.hasPrefix(makeupPrefix) || $0.hasPrefix(snoozePrefix)
        }
        guard !ids.isEmpty else {
            cachedPendingCount = await pendingCount()
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        cachedPendingCount = await pendingCount()
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
