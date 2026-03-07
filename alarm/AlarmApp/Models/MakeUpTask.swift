import Foundation
import SwiftData

@Model
final class MakeUpTask {
    var id: UUID
    var runID: UUID
    var dueAt: Date
    var isCompleted: Bool

    init(runID: UUID, dueAt: Date) {
        self.id = UUID()
        self.runID = runID
        self.dueAt = dueAt
        self.isCompleted = false
    }
}
