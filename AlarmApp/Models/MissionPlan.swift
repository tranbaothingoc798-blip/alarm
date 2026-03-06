import Foundation

struct MissionStage: Codable, Hashable, Identifiable {
    var id = UUID()
    var missionType: MissionType
    var maxDurationSec: Int
    var difficulty: Int
    var chainedTypes: [MissionType] = []
}

struct MissionPlan: Codable, Hashable {
    var preset: MissionPlanPreset
    var stages: [MissionStage]

    static func plan(for preset: MissionPlanPreset) -> MissionPlan {
        switch preset {
        case .standard:
            return MissionPlan(
                preset: .standard,
                stages: [
                    MissionStage(missionType: Bool.random() ? .typing : .math, maxDurationSec: 25, difficulty: 1),
                    MissionStage(missionType: .shake, maxDurationSec: 40, difficulty: 2),
                    MissionStage(missionType: .barcode, maxDurationSec: 90, difficulty: 1)
                ]
            )
        case .ruthless:
            return MissionPlan(
                preset: .ruthless,
                stages: [
                    MissionStage(missionType: .typing, maxDurationSec: 30, difficulty: 2, chainedTypes: [.typing, .math]),
                    MissionStage(missionType: .shake, maxDurationSec: 55, difficulty: 3),
                    MissionStage(missionType: .barcode, maxDurationSec: 90, difficulty: 2)
                ]
            )
        }
    }
}
