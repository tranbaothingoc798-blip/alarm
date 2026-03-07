import XCTest
import SwiftData
@testable import AlarmApp

@MainActor
final class AlarmRepositoryTests: XCTestCase {
    var modelContext: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Alarm.self, AlarmRun.self, AlarmEventLog.self, MakeUpTask.self, AppSettings.self,
            configurations: config
        )
        modelContext = ModelContext(container)
    }

    func testFetchAllEmpty() {
        let alarms = AlarmRepository.fetchAll(context: modelContext)
        XCTAssertTrue(alarms.isEmpty)
    }

    func testFetchAllAndEnabled() {
        let a1 = Alarm(hour: 7, minute: 0, repeatWeekdays: [], label: "A", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard, isEnabled: true)
        let a2 = Alarm(hour: 8, minute: 30, repeatWeekdays: [2, 3, 4, 5, 6], label: "B", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard, isEnabled: false)
        modelContext.insert(a1)
        modelContext.insert(a2)
        try? modelContext.save()

        let all = AlarmRepository.fetchAll(context: modelContext)
        XCTAssertEqual(all.count, 2)

        let enabled = AlarmRepository.fetchEnabled(context: modelContext)
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.label, "A")
    }

    func testNextUpcomingOccurrence() {
        let alarm = Alarm(hour: 9, minute: 0, repeatWeekdays: [], label: "Wake", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard, isEnabled: true)
        modelContext.insert(alarm)
        try? modelContext.save()

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = ISO8601DateFormatter().date(from: "2026-01-01T06:00:00Z")!

        let result = AlarmRepository.nextUpcomingOccurrence(context: modelContext, now: now, calendar: cal)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.alarm.label, "Wake")
        XCTAssertEqual(result?.date, ISO8601DateFormatter().date(from: "2026-01-01T09:00:00Z"))
    }
}
