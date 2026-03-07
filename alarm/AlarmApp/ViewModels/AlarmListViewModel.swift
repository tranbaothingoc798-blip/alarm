import Foundation
import SwiftData

@MainActor
final class AlarmListViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []

    func load(context: ModelContext) {
        alarms = AlarmRepository.fetchAll(context: context)
    }

    func toggle(_ alarm: Alarm, context: ModelContext, canArm: Bool) async {
        if !canArm && !alarm.isEnabled {
            return
        }
        let wasEnabled = alarm.isEnabled
        alarm.isEnabled.toggle()
        try? context.save()
        if wasEnabled {
            await NotificationScheduler.shared.cancelPendingAlarms(for: alarm.id)
        }
        let all = AlarmRepository.fetchAll(context: context)
        await NotificationScheduler.shared.rebuildSchedule(alarms: all, context: context)
    }

    func delete(_ alarm: Alarm, context: ModelContext) async {
        context.delete(alarm)
        try? context.save()
        await NotificationScheduler.shared.cancelPendingAlarms(for: alarm.id)
        let all = AlarmRepository.fetchAll(context: context)
        await NotificationScheduler.shared.rebuildSchedule(alarms: all, context: context)
        alarms = AlarmRepository.fetchAll(context: context)
    }

    func nextAlarmText(now: Date = .now) -> String {
        let next = alarms.filter { $0.isEnabled }.compactMap { $0.nextOccurrence(after: now) }.sorted().first
        guard let next else { return "No enabled alarms" }
        return "Next alarm: \(next.formatted(date: .abbreviated, time: .shortened))"
    }
}
