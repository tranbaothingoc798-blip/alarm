import Foundation
import SwiftData

@MainActor
final class AlarmListViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<Alarm>(sortBy: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)])
        alarms = (try? context.fetch(descriptor)) ?? []
    }

    func toggle(_ alarm: Alarm, context: ModelContext, canArm: Bool) async {
        if !canArm && !alarm.isEnabled {
            return
        }
        alarm.isEnabled.toggle()
        try? context.save()
        let all = (try? context.fetch(FetchDescriptor<Alarm>())) ?? alarms
        await NotificationScheduler.shared.rebuildSchedule(alarms: all, context: context)
    }

    func nextAlarmText(now: Date = .now) -> String {
        let next = alarms.filter { $0.isEnabled }.compactMap { $0.nextOccurrence(after: now) }.sorted().first
        guard let next else { return "No enabled alarms" }
        return "Next alarm: \(next.formatted(date: .abbreviated, time: .shortened))"
    }
}
