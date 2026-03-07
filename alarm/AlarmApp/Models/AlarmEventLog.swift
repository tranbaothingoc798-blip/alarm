import Foundation
import SwiftData

@Model
final class AlarmEventLog {
    var id: UUID
    var runID: UUID?
    var alarmID: UUID?
    var timestamp: Date
    var type: AlarmEventType
    var payload: String
    var reasonCode: String?

    init(runID: UUID? = nil, alarmID: UUID? = nil, type: AlarmEventType, payload: String = "{}", reasonCode: String? = nil) {
        self.id = UUID()
        self.runID = runID
        self.alarmID = alarmID
        self.timestamp = .now
        self.type = type
        self.payload = payload
        self.reasonCode = reasonCode
    }
}
