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

    func testRecordFailureAndFallbackEligible() {
        let engine = MissionEngine()
        let plan = MissionPlan(preset: .standard, stages: [
            MissionStage(missionType: .math, maxDurationSec: 60, difficulty: 1)
        ])
        engine.start(plan: plan)
        XCTAssertFalse(engine.fallbackEligible)
        engine.recordFailure()
        XCTAssertFalse(engine.fallbackEligible)
        engine.recordFailure()
        XCTAssertTrue(engine.fallbackEligible)
    }

    func testUseFallbackAdvancesStage() {
        let engine = MissionEngine()
        let plan = MissionPlan(preset: .standard, stages: [
            MissionStage(missionType: .math, maxDurationSec: 60, difficulty: 1),
            MissionStage(missionType: .typing, maxDurationSec: 30, difficulty: 1)
        ])
        engine.start(plan: plan)
        engine.recordFailure()
        engine.recordFailure()
        engine.useFallback()
        XCTAssertEqual(engine.stageIndex, 1)
        XCTAssertFalse(engine.fallbackEligible)
    }

    func testMultiStepChain() {
        let engine = MissionEngine()
        let plan = MissionPlan(preset: .standard, stages: [
            MissionStage(missionType: .math, maxDurationSec: 10, difficulty: 1),
            MissionStage(missionType: .typing, maxDurationSec: 10, difficulty: 1),
            MissionStage(missionType: .shake, maxDurationSec: 5, difficulty: 1)
        ])
        engine.start(plan: plan)
        XCTAssertEqual(engine.currentStage?.missionType, .math)
        _ = engine.completeCurrentStage()
        XCTAssertEqual(engine.currentStage?.missionType, .typing)
        _ = engine.completeCurrentStage()
        XCTAssertEqual(engine.currentStage?.missionType, .shake)
        XCTAssertTrue(engine.completeCurrentStage())
    }
}
