import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query private var runs: [AlarmRun]
    @Query(sort: \MakeUpTask.dueAt) private var tasks: [MakeUpTask]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    statCard(title: "Streak", value: "\(successStreak()) days")
                    statCard(title: "Success", value: "\(successRate)%", accent: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(AppTheme.labelFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Success count: \(runs.filter { $0.stopReason == .success }.count)")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Emergency count: \(runs.filter { $0.stopReason == .emergencyStop }.count)")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Make-up tasks")
                        .font(AppTheme.labelFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    if tasks.filter({ !$0.isCompleted }).isEmpty {
                        Text("No make-up tasks")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        ForEach(tasks.filter { !$0.isCompleted }, id: \.id) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Due \(task.dueAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(AppTheme.bodyFont)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Run: \(task.runID.uuidString.prefix(8))…")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Button("Complete") {
                                    task.isCompleted = true
                                    try? context.save()
                                }
                                .accentButton()
                                .frame(maxWidth: 120)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Stats")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
    }

    private func statCard(title: String, value: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(accent ? AppTheme.accent : AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var successRate: Int {
        let total = runs.count
        guard total > 0 else { return 0 }
        let success = runs.filter { $0.stopReason == .success }.count
        return Int((Double(success) / Double(total)) * 100)
    }

    private func successStreak() -> Int {
        runs.sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
            .prefix { $0.stopReason == .success }
            .count
    }
}
