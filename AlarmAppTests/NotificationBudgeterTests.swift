import XCTest
@testable import AlarmApp

final class NotificationBudgeterTests: XCTestCase {
    func testBudgetNeverExceeds64() {
        let alarms = (0..<20).map { i in
            Alarm(hour: i % 24, minute: 0, repeatWeekdays: [], label: "A\(i)", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard)
        }
        let budgeter = NotificationBudgeter()
        let occurrences = budgeter.budgetedOccurrences(from: alarms)
        XCTAssertLessThanOrEqual(occurrences.count * budgeter.escalations.count, budgeter.maxPending)
        XCTAssertLessThanOrEqual(occurrences.count, budgeter.maxPending / budgeter.escalations.count)
    }
}
