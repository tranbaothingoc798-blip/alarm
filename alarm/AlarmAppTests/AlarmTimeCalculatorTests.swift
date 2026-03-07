import XCTest
@testable import AlarmApp

final class AlarmTimeCalculatorTests: XCTestCase {
    var cal: Calendar!
    let iso = ISO8601DateFormatter()

    override func setUp() {
        super.setUp()
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testNextOccurrenceDaily() {
        let now = iso.date(from: "2026-01-01T06:00:00Z")!
        let next = AlarmTimeCalculator.nextOccurrence(hour: 7, minute: 0, repeatWeekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, iso.date(from: "2026-01-01T07:00:00Z"))
    }

    func testNextOccurrenceDailyPastTime() {
        let now = iso.date(from: "2026-01-01T08:00:00Z")!
        let next = AlarmTimeCalculator.nextOccurrence(hour: 7, minute: 0, repeatWeekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, iso.date(from: "2026-01-02T07:00:00Z"))
    }

    func testNextOccurrenceRepeatingWeekdays() {
        // Thu Jan 1 2026 06:00 UTC
        let now = iso.date(from: "2026-01-01T06:00:00Z")!
        // Weekdays 2-6 = Mon-Fri
        let next = AlarmTimeCalculator.nextOccurrence(hour: 7, minute: 30, repeatWeekdays: [2, 3, 4, 5, 6], after: now, calendar: cal)
        // Next Thu at 07:30
        XCTAssertEqual(next, iso.date(from: "2026-01-01T07:30:00Z"))
    }

    func testNextOccurrenceRepeatingTodayPassed() {
        // Thu Jan 1 2026 10:00 UTC - Thu is weekday 5
        let now = iso.date(from: "2026-01-01T10:00:00Z")!
        let next = AlarmTimeCalculator.nextOccurrence(hour: 7, minute: 0, repeatWeekdays: [5], after: now, calendar: cal)
        // Next Thu Jan 8
        XCTAssertEqual(next, iso.date(from: "2026-01-08T07:00:00Z"))
    }

    func testNextOccurrenceSingleWeekday() {
        // Mon Jan 5 2026 06:00 - Sunday only (weekday 1)
        let now = iso.date(from: "2026-01-05T06:00:00Z")!
        let next = AlarmTimeCalculator.nextOccurrence(hour: 8, minute: 0, repeatWeekdays: [1], after: now, calendar: cal)
        XCTAssertEqual(next, iso.date(from: "2026-01-11T08:00:00Z"))
    }

    func testNextOccurrenceWeekends() {
        // Fri Jan 2 2026 10:00 - Sat=7, Sun=1
        let now = iso.date(from: "2026-01-02T10:00:00Z")!
        let next = AlarmTimeCalculator.nextOccurrence(hour: 9, minute: 0, repeatWeekdays: [1, 7], after: now, calendar: cal)
        XCTAssertEqual(next, iso.date(from: "2026-01-03T09:00:00Z"))
    }

    func testUpcomingOccurrences() {
        let now = iso.date(from: "2026-01-01T06:00:00Z")!
        let occurrences = AlarmTimeCalculator.upcomingOccurrences(hour: 7, minute: 0, repeatWeekdays: [], count: 3, from: now, calendar: cal)
        XCTAssertEqual(occurrences.count, 3)
        XCTAssertEqual(occurrences[0], iso.date(from: "2026-01-01T07:00:00Z"))
        XCTAssertEqual(occurrences[1], iso.date(from: "2026-01-02T07:00:00Z"))
        XCTAssertEqual(occurrences[2], iso.date(from: "2026-01-03T07:00:00Z"))
    }

    func testNextFireDateForAlarm() {
        let alarm = Alarm(hour: 8, minute: 15, repeatWeekdays: [], label: "Test", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard)
        let now = iso.date(from: "2026-01-01T07:00:00Z")!
        let next = AlarmTimeCalculator.nextFireDate(for: alarm, from: now, calendar: cal)
        XCTAssertEqual(next, iso.date(from: "2026-01-01T08:15:00Z"))
    }
}
