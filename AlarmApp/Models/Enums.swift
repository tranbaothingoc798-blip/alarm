import Foundation

enum RampStyle: String, Codable, CaseIterable, Identifiable {
    case off, slow, fast
    var id: String { rawValue }
}

enum MissionType: String, Codable, CaseIterable, Identifiable {
    case typing, math, shake, steps, barcode
    var id: String { rawValue }
}

enum MissionPlanPreset: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard"
    case ruthless = "Ruthless"
    var id: String { rawValue }
}

enum AlarmStopReason: String, Codable {
    case success, emergencyStop, appKilled
}

enum EmergencyReason: String, Codable, CaseIterable, Identifiable {
    case medical = "Medical"
    case meeting = "Meeting/Public"
    case travel = "Travel/Not home"
    case exhausted = "Too exhausted"
    case other = "Other"

    var id: String { rawValue }
}

enum AlarmFailureReason: String, Codable {
    case unknown
    case notificationsDenied
    case noEnabledAlarms
    case scheduleEmpty
    case schedulerStale
    case testNotRun
    case soundNotTested
    case invalidNextOccurrence
    case userConfirmedNoSound
    case userConfirmedHeardSound
    case budgetTruncated
    case maxSnoozesReached
}

enum SnoozeFrictionLevel: String, Codable {
    case tap
    case slider
    case holdToConfirm
}

enum AlarmEventType: String, Codable {
    case alarmScheduled = "alarm_scheduled"
    case alarmFired = "alarm_fired"
    case alarmOpened = "alarm_opened"
    case ringingStarted = "ringing_started"
    case missionStageStarted = "mission_stage_started"
    case missionFailed = "mission_failed"
    case missionCompleted = "mission_completed"
    case fallbackOffered = "fallback_offered"
    case fallbackUsed = "fallback_used"
    case emergencyOpened = "emergency_opened"
    case emergencyStopped = "emergency_stopped"
    case alarmSuccess = "alarm_success"
    case alarmEnded = "alarm_ended"
    case alarmSnoozed = "alarm_snoozed"
    case alarmTestScheduled = "alarm_test_scheduled"
    case readinessComputed = "readiness_computed"
    case schedulerWarning = "scheduler_warning"
}
