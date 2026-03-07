import Foundation

/// Pure utility for computing next alarm fire dates.
/// - Empty `repeatWeekdays`: daily (every day at hour:minute).
/// - Non-empty: only on specified weekdays (1=Sunday, 7=Saturday).
struct AlarmTimeCalculator {
    /// Returns the next occurrence of an alarm at the given time after `now`.
    static func nextOccurrence(hour: Int, minute: Int, repeatWeekdays: [Int], after now: Date, calendar: Calendar = .current) -> Date? {
        let components = DateComponents(hour: hour, minute: minute)

        if repeatWeekdays.isEmpty {
            // Daily: next occurrence of this time (today if future, else tomorrow)
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
        }

        // Repeating on specific weekdays
        let currentWeekday = calendar.component(.weekday, from: now)
        for offset in 0..<8 {
            let day = ((currentWeekday - 1 + offset) % 7) + 1
            guard repeatWeekdays.contains(day) else { continue }
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            var merged = calendar.dateComponents([.year, .month, .day], from: dayDate)
            merged.hour = hour
            merged.minute = minute
            merged.second = 0
            guard let candidate = calendar.date(from: merged), candidate > now else { continue }
            return candidate
        }
        return nil
    }

    /// Convenience: next fire date for an alarm.
    static func nextFireDate(for alarm: Alarm, from now: Date = .now, calendar: Calendar = .current) -> Date? {
        nextOccurrence(hour: alarm.hour, minute: alarm.minute, repeatWeekdays: alarm.repeatWeekdays, after: now, calendar: calendar)
    }

    /// Returns up to `count` upcoming occurrences for an alarm.
    static func upcomingOccurrences(for alarm: Alarm, count: Int, from now: Date, calendar: Calendar = .current) -> [Date] {
        upcomingOccurrences(hour: alarm.hour, minute: alarm.minute, repeatWeekdays: alarm.repeatWeekdays, count: count, from: now, calendar: calendar)
    }

    /// Returns up to `count` upcoming occurrences.
    static func upcomingOccurrences(hour: Int, minute: Int, repeatWeekdays: [Int], count: Int, from now: Date, calendar: Calendar = .current) -> [Date] {
        var results: [Date] = []
        var cursor = now
        for _ in 0..<max(1, count) {
            guard let next = nextOccurrence(hour: hour, minute: minute, repeatWeekdays: repeatWeekdays, after: cursor, calendar: calendar) else { break }
            results.append(next)
            cursor = next.addingTimeInterval(60)
        }
        return results
    }
}
