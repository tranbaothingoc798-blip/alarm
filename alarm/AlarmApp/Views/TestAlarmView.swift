import SwiftUI
import SwiftData

struct TestAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel

    @State private var fireAt = Date().addingTimeInterval(60)
    @State private var now = Date()
    @State private var readiness: AlarmReadinessReport?
    @State private var pendingByPrefix: [String: Int] = [:]
    @State private var showDiagnostics = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    introSection
                    noteCard
                    startButton
                    if showDiagnostics {
                        diagnosticsSection
                    } else {
                        Button("View diagnostics") { showDiagnostics = true }
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Test Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .onReceive(timer) { now = $0 }
            .task { await refreshReadiness() }
        }
    }

    private var introSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 100, height: 100)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.accent)
            }

            Text("Ready to Test?")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Experience your wake-up missions and see how they work")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Note:")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("This is a test. Your actual alarm won't ring. You can exit anytime.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var startButton: some View {
        Button("Start Test Alarm") {
            scheduleProof(.full)
            dismiss()
        }
        .accentButton()
    }

    private var diagnosticsSection: some View {
        VStack(spacing: 16) {
            readinessCard
            proofCard
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text((readiness?.isReady ?? false) ? "Ready" : "Needs Attention")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)
            Text(readinessNextAlarmText)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            if let issues = readiness?.issues.prefix(2), !issues.isEmpty {
                ForEach(Array(issues)) { issue in
                    Text("• \(issue.title)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                if appVM.notificationStatus == .notDetermined {
                    Button("Enable notifications") {
                        Task {
                            await appVM.requestNotifications(context: context)
                            await refreshReadiness()
                        }
                    }
                    .accentButton()
                } else if appVM.notificationsDenied {
                    Button("Open settings") { appVM.openSystemSettings() }
                        .accentButton()
                }
                Button("Rebuild schedule") {
                    Task {
                        await NotificationScheduler.shared.rebuildAllSchedules(context: context)
                        appVM.updateLastSchedulerRebuild(.now, context: context)
                        await refreshReadiness()
                    }
                }
                .secondaryButton()
            }
        }
        .cardStyle()
    }

    private var proofCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proof Test (1 minute)")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Countdown: \(max(0, Int(fireAt.timeIntervalSince(now))))s")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            Button("Quiet Proof (no challenge)") { scheduleProof(.quiet) }
                .secondaryButton()

            Button("Full Proof (with challenge)") { scheduleProof(.full) }
                .accentButton()

            Button("Cancel test") {
                Task {
                    await NotificationScheduler.shared.cancelTestAlarm()
                    dismiss()
                }
            }
            .font(AppTheme.captionFont)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
    }

    private var readinessNextAlarmText: String {
        guard let readiness else { return "Checking system readiness…" }
        if let next = readiness.nextAlarmAt {
            return "Next alarm: \(next.formatted(date: .abbreviated, time: .shortened))"
        }
        return readiness.summary
    }

    private func scheduleProof(_ type: TestProofType) {
        appVM.setPreferredProofType(type, context: context)
        fireAt = Date().addingTimeInterval(60)
        Task {
            await NotificationScheduler.shared.scheduleTestAlarm(fireAt: fireAt, proofType: type, context: context)
        }
    }

    private func refreshReadiness() async {
        await appVM.refreshNotificationStatus()
        pendingByPrefix = await NotificationScheduler.shared.pendingCountsByPrefix()
        readiness = await AlarmReadinessService().generateReport(context: context)
    }
}
