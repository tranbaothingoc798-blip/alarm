import Foundation
import SwiftData

@Model
final class Alarm {
    var id: UUID
    var hour: Int
    var minute: Int
    var repeatWeekdays: [Int]
    var label: String
    var soundName: String
    var rampStyle: RampStyle
    var missionPlanPreset: MissionPlanPreset
    var isEnabled: Bool
    var createdAt: Date
    var snoozeMinutes: Int
    var maxSnoozes: Int
    var alarmGroup: String
    var requiresMissionToStop: Bool

    init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        repeatWeekdays: [Int],
        label: String,
        soundName: String,
        rampStyle: RampStyle,
        missionPlanPreset: MissionPlanPreset,
        isEnabled: Bool = true,
        createdAt: Date = .now,
        snoozeMinutes: Int = 10,
        maxSnoozes: Int = 2,
        alarmGroup: String = "Default",
        requiresMissionToStop: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.repeatWeekdays = repeatWeekdays
        self.label = label
        self.soundName = soundName
        self.rampStyle = rampStyle
        self.missionPlanPreset = missionPlanPreset
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.snoozeMinutes = snoozeMinutes
        self.maxSnoozes = maxSnoozes
        self.alarmGroup = alarmGroup
        self.requiresMissionToStop = requiresMissionToStop
    }

    func nextOccurrence(after now: Date = .now, calendar: Calendar = .current) -> Date? {
        AlarmTimeCalculator.nextOccurrence(hour: hour, minute: minute, repeatWeekdays: repeatWeekdays, after: now, calendar: calendar)
    }
}
