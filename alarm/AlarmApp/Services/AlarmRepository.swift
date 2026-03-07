import Foundation
import SwiftData

@MainActor
enum AlarmRepository {
    static func fetchAll(context: ModelContext) -> [Alarm] {
        let descriptor = FetchDescriptor<Alarm>(
            sortBy: [
                SortDescriptor(\Alarm.hour),
                SortDescriptor(\Alarm.minute)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func fetchEnabled(context: ModelContext) -> [Alarm] {
        fetchAll(context: context).filter { $0.isEnabled }
    }

    /// Returns the next upcoming occurrence across all enabled alarms, if any.
    static func nextUpcomingOccurrence(
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (alarm: Alarm, date: Date)? {
        let enabled = fetchEnabled(context: context)
        let candidates = enabled.compactMap { alarm in
            alarm.nextOccurrence(after: now, calendar: calendar).map { (alarm, $0) }
        }
        return candidates.min(by: { $0.1 < $1.1 })
    }
}

