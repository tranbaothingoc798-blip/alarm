import SwiftUI

struct MissionStageHostView: View {
    @ObservedObject var engine: MissionEngine
    let onSuccess: () -> Void
    let onFailure: () -> Void

    var body: some View {
        Group {
            switch engine.currentStage?.missionType {
            case .typing:
                TypingMissionView(onSuccess: onSuccess, onFailure: onFailure)
            case .math:
                MathMissionView(difficulty: engine.currentStage?.difficulty ?? 1, onSuccess: onSuccess, onFailure: onFailure)
            case .shake:
                ShakeMissionView(secondsRequired: max(5, (engine.currentStage?.difficulty ?? 1) * 5), onSuccess: onSuccess, onFailure: onFailure)
            case .steps:
                PlaceholderMissionView(title: "Steps mission (coming soon)")
            case .barcode:
                PlaceholderMissionView(title: "Barcode/QR mission (coming soon)")
            case .memory:
                MemoryMissionView(sequenceLength: max(2, (engine.currentStage?.difficulty ?? 1) + 2), onSuccess: onSuccess, onFailure: onFailure)
            case .none:
                Text("No stage")
            }
        }
    }
}
