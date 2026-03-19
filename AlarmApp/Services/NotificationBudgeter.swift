import Foundation

struct NotificationBudgeter {
    let maxPending = 64
    let escalations = [0, 15, 30, 45, 60]

    func budgetedOccurrences(from alarms: [Alarm], now: Date = .now, daysAhead: Int = 7) -> [(alarm: Alarm, fireDate: Date)] {
        let enabled = alarms.filter { $0.isEnabled }
        var candidates: [(Alarm, Date)] = []
        let ceiling = Calendar.current.date(byAdding: .day, value: daysAhead, to: now) ?? now

        for alarm in enabled {
            var cursor = now
            while let next = alarm.nextOccurrence(after: cursor), next <= ceiling {
                candidates.append((alarm, next))
                cursor = next.addingTimeInterval(60)
            }
        }

        let sorted = candidates.sorted { $0.1 < $1.1 }
        let perOccurrenceCost = escalations.count
        let maxOccurrences = maxPending / perOccurrenceCost
        return Array(sorted.prefix(maxOccurrences)).map { ($0.0, $0.1) }
    }
}
