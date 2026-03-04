import XCTest
@testable import AlarmApp

@MainActor
final class SnoozeFrictionTests: XCTestCase {
    func testFrictionMapping() {
        let vm = RingingViewModel()
        let alarm = Alarm(hour: 7, minute: 0, repeatWeekdays: [], label: "A", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard)

        vm.run = AlarmRun(alarmID: UUID())
        vm.run?.snoozeCount = 0
        XCTAssertEqual(vm.currentSnoozeFriction(alarm: alarm), .tap)

        vm.run?.snoozeCount = 1
        XCTAssertEqual(vm.currentSnoozeFriction(alarm: alarm), .slider)

        vm.run?.snoozeCount = 2
        XCTAssertEqual(vm.currentSnoozeFriction(alarm: alarm), .holdToConfirm)
    }
}
