import Foundation
import SwiftData

@Model
final class AlarmRun {
    var id: UUID
    var alarmID: UUID?
    var startedAt: Date
    var endedAt: Date?
    var stopReason: AlarmStopReason?
    var emergencyReason: EmergencyReason?
    var usedFallback: Bool
    var penaltyPoints: Int
    var currentStageIndex: Int
    var isTest: Bool
    var snoozeCount: Int
    var snoozeTotalSeconds: Int
    var lastSnoozeAt: Date?
    var lastScheduledFireAt: Date?

    init(alarmID: UUID?, startedAt: Date = .now, isTest: Bool = false) {
        self.id = UUID()
        self.alarmID = alarmID
        self.startedAt = startedAt
        self.usedFallback = false
        self.penaltyPoints = 0
        self.currentStageIndex = 0
        self.isTest = isTest
        self.snoozeCount = 0
        self.snoozeTotalSeconds = 0
    }
}
