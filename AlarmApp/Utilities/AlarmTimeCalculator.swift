import Foundation

struct AlarmTimeCalculator {
    static func nextOccurrence(hour: Int, minute: Int, repeatWeekdays: [Int], after now: Date, calendar: Calendar = .current) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        if repeatWeekdays.isEmpty {
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
        }

        let currentWeekday = calendar.component(.weekday, from: now)
        for offset in 0...7 {
            let day = ((currentWeekday - 1 + offset) % 7) + 1
            guard repeatWeekdays.contains(day) else { continue }
            let dayDate = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            var merged = calendar.dateComponents([.year, .month, .day], from: dayDate)
            merged.hour = hour
            merged.minute = minute
            if let candidate = calendar.date(from: merged), candidate > now {
                return candidate
            }
        }
        return nil
    }
}
