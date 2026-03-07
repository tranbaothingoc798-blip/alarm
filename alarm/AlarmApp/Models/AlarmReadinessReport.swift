import Foundation
import UserNotifications

enum AlarmReadinessSeverity: String, Codable {
    case warning
    case critical
}

enum AlarmReadinessAction: String, Codable {
    case enableNotifications
    case openSystemSettings
    case rebuildSchedule
    case runTestAlarm
    case playTestSound
    case none
}

struct AlarmReadinessIssue: Identifiable, Codable {
    var id = UUID()
    var title: String
    var detail: String
    var severity: AlarmReadinessSeverity
    var action: AlarmReadinessAction
    var reason: AlarmFailureReason
}

struct AlarmReadinessReport: Codable {
    var isReady: Bool
    var summary: String
    var issues: [AlarmReadinessIssue]
    var pendingCount: Int
    var lastRebuildAt: Date?
    var notificationStatus: UNAuthorizationStatus
    /// Next scheduled alarm time if ready; nil when no valid next occurrence.
    var nextAlarmAt: Date?
}
