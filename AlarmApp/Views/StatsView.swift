import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var runs: [AlarmRun]
    @Query(sort: \MakeUpTask.dueAt) private var tasks: [MakeUpTask]

    var body: some View {
        List {
            Text("Success count: \(runs.filter { $0.stopReason == .success }.count)")
            Text("Emergency count: \(runs.filter { $0.stopReason == .emergencyStop }.count)")
            Text("Streak: \(successStreak())")
            Text("Next make-up: \(tasks.first?.dueAt.formatted(date: .omitted, time: .shortened) ?? "None")")
        }
        .navigationTitle("Stats")
    }

    private func successStreak() -> Int {
        runs.sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
            .prefix { $0.stopReason == .success }
            .count
    }
}
