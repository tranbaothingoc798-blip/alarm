import XCTest
@testable import AlarmApp

final class AlarmTimeCalculatorTests: XCTestCase {
    func testNextOccurrenceDaily() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = ISO8601DateFormatter().date(from: "2026-01-01T06:00:00Z")!

        let next = AlarmTimeCalculator.nextOccurrence(hour: 7, minute: 0, repeatWeekdays: [], after: now, calendar: cal)
        XCTAssertEqual(next, ISO8601DateFormatter().date(from: "2026-01-01T07:00:00Z"))
    }
}
