import XCTest
import SwiftData
@testable import AlarmApp

@MainActor
final class AlarmReadinessServiceTests: XCTestCase {
    func testNotReadyWhenAlarmPendingZeroEvenIfTestPendingExists() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Alarm.self, AppSettings.self, configurations: config)
        let context = ModelContext(container)

        let settings = AppSettings.fetchOrCreate(in: context)
        settings.lastSchedulerRebuildAt = .now
        let alarm = Alarm(hour: 7, minute: 0, repeatWeekdays: [], label: "A", soundName: "alarm", rampStyle: .slow, missionPlanPreset: .standard)
        alarm.isEnabled = true
        context.insert(alarm)
        try context.save()

        let service = AlarmReadinessService(
            scheduler: .shared,
            notificationStatusProvider: { .authorized },
            prefixCountsProvider: { ["alarm_": 0, "test_": 5, "snooze_": 0, "makeup_": 0] },
            totalPendingProvider: { 5 }
        )

        let report = await service.generateReport(context: context)
        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.issues.contains { $0.reason == .scheduleEmpty })
    }
}
