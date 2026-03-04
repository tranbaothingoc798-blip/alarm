import Foundation
import SwiftData

@MainActor
final class EventLogger {
    static let shared = EventLogger()
    private let iso = ISO8601DateFormatter()

    func log(_ type: AlarmEventType, runID: UUID? = nil, alarmID: UUID? = nil, payload: String = "{}", context: ModelContext) {
        let normalized = payload.isEmpty ? "{}" : payload
        context.insert(AlarmEventLog(runID: runID, alarmID: alarmID, type: type, payload: normalized))
        try? context.save()
    }

    func logJSON(
        _ type: AlarmEventType,
        runID: UUID? = nil,
        alarmID: UUID? = nil,
        reason: AlarmFailureReason? = nil,
        payload: [String: Any],
        context: ModelContext
    ) {
        context.insert(
            AlarmEventLog(
                runID: runID,
                alarmID: alarmID,
                type: type,
                payload: JSONPayload.encode(payload),
                reasonCode: reason?.rawValue
            )
        )
        try? context.save()
    }

    func exportDiagnosticsBundle(
        runs: [AlarmRun],
        logs: [AlarmEventLog],
        permission: String,
        pendingCount: Int,
        lastRebuildAt: Date?,
        readinessSummary: String? = nil,
        readinessIssues: [String] = [],
        pendingByPrefix: [String: Int] = [:]
    ) -> Data? {
        let runPayload = runs.map {
            [
                "id": $0.id.uuidString,
                "alarmID": $0.alarmID?.uuidString ?? "",
                "startedAt": iso.string(from: $0.startedAt),
                "endedAt": $0.endedAt.map { iso.string(from: $0) } ?? "",
                "stopReason": $0.stopReason?.rawValue ?? "",
                "penaltyPoints": $0.penaltyPoints,
                "isTest": $0.isTest,
                "snoozeCount": $0.snoozeCount,
                "snoozeTotalSeconds": $0.snoozeTotalSeconds,
                "lastSnoozeAt": $0.lastSnoozeAt.map { iso.string(from: $0) } ?? "",
                "lastScheduledFireAt": $0.lastScheduledFireAt.map { iso.string(from: $0) } ?? ""
            ] as [String : Any]
        }
        let logPayload = logs.map {
            [
                "id": $0.id.uuidString,
                "runID": $0.runID?.uuidString ?? "",
                "alarmID": $0.alarmID?.uuidString ?? "",
                "type": $0.type.rawValue,
                "timestamp": iso.string(from: $0.timestamp),
                "payload": $0.payload,
                "reasonCode": $0.reasonCode ?? ""
            ] as [String : Any]
        }
        let bundle: [String: Any] = [
            "generatedAt": iso.string(from: .now),
            "permission": permission,
            "pendingCount": pendingCount,
            "lastRebuildAt": lastRebuildAt.map { iso.string(from: $0) } ?? "",
            "readinessSummary": readinessSummary ?? "",
            "readinessIssues": readinessIssues,
            "pendingByPrefix": pendingByPrefix,
            "runs": runPayload,
            "logs": logPayload
        ]
        return try? JSONSerialization.data(withJSONObject: bundle, options: [.prettyPrinted, .sortedKeys])
    }
}
