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

    func testOnlyEnabledAlarmsScheduled() {
        let enabled = Alarm(hour: 7, minute: 0, repeatWeekdays: [], label: "On", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard, isEnabled: true)
        let disabled = Alarm(hour: 8, minute: 0, repeatWeekdays: [], label: "Off", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard, isEnabled: false)
        let budgeter = NotificationBudgeter()
        let occurrences = budgeter.budgetedOccurrences(from: [enabled, disabled])
        XCTAssertEqual(occurrences.count, 1)
        XCTAssertEqual(occurrences.first?.alarm.label, "On")
    }
}
