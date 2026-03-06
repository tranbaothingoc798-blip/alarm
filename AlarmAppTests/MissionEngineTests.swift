import XCTest
@testable import AlarmApp

@MainActor
final class MissionEngineTests: XCTestCase {
    func testLadderProgression() {
        let engine = MissionEngine()
        let plan = MissionPlan(preset: .standard, stages: [
            MissionStage(missionType: .typing, maxDurationSec: 20, difficulty: 1),
            MissionStage(missionType: .shake, maxDurationSec: 30, difficulty: 2)
        ])

        engine.start(plan: plan)
        XCTAssertEqual(engine.stageIndex, 0)
        XCTAssertFalse(engine.completeCurrentStage())
        XCTAssertEqual(engine.stageIndex, 1)
        XCTAssertTrue(engine.completeCurrentStage())
    }
}
