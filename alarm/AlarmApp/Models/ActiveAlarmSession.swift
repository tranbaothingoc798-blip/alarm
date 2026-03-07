import Foundation

/// Live state for an active ringing alarm session. Drives the full-screen active alarm UI and challenge flow.
struct ActiveAlarmSession: Identifiable {
    let id: UUID
    let alarm: Alarm?
    let isTest: Bool
    let testProofType: TestProofType?
    let startTime: Date

    /// Remaining seconds of temporary silence (grace). 0 when not in grace.
    var graceSecondsRemaining: Int

    var isGraceActive: Bool { graceSecondsRemaining > 0 }

    init(
        id: UUID = UUID(),
        alarm: Alarm?,
        isTest: Bool,
        testProofType: TestProofType? = nil,
        startTime: Date = .now,
        graceSecondsRemaining: Int = 0
    ) {
        self.id = id
        self.alarm = alarm
        self.isTest = isTest
        self.testProofType = testProofType
        self.startTime = startTime
        self.graceSecondsRemaining = graceSecondsRemaining
    }

    static func forAlarm(_ alarm: Alarm) -> ActiveAlarmSession {
        ActiveAlarmSession(alarm: alarm, isTest: false)
    }

    static func forTest(proofType: TestProofType) -> ActiveAlarmSession {
        ActiveAlarmSession(alarm: nil, isTest: true, testProofType: proofType)
    }
}
