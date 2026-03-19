import Foundation

@MainActor
final class MissionEngine: ObservableObject {
    @Published var stageIndex = 0
    @Published var stageTimeRemaining = 0
    @Published var failCount = 0
    @Published var fallbackEligible = false

    private(set) var plan: MissionPlan = .plan(for: .standard)
    private var timer: Timer?

    func start(plan: MissionPlan) {
        self.plan = plan
        stageIndex = 0
        failCount = 0
        startStageTimer()
    }

    var currentStage: MissionStage? {
        guard plan.stages.indices.contains(stageIndex) else { return nil }
        return plan.stages[stageIndex]
    }

    func completeCurrentStage() -> Bool {
        timer?.invalidate()
        if stageIndex + 1 >= plan.stages.count {
            return true
        }
        stageIndex += 1
        failCount = 0
        fallbackEligible = false
        startStageTimer()
        return false
    }

    func recordFailure() {
        failCount += 1
        if failCount >= 2 { fallbackEligible = true }
    }

    func useFallback() {
        fallbackEligible = false
        failCount = 0
        _ = completeCurrentStage()
    }

    private func startStageTimer() {
        stageTimeRemaining = currentStage?.maxDurationSec ?? 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.stageTimeRemaining -= 1
            if self.stageTimeRemaining <= 0 {
                self.fallbackEligible = true
                t.invalidate()
            }
        }
    }
}
