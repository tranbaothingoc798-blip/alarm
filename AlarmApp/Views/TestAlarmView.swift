import SwiftUI
import SwiftData

struct TestAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel

    @State private var fireAt = Date().addingTimeInterval(120)
    @State private var now = Date()
    @State private var wasTriggered = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("2-minute proof alarm")
                    .font(.title2.bold())
                Text("Fires at \(fireAt.formatted(date: .omitted, time: .standard))")
                Text("Countdown: \(max(0, Int(fireAt.timeIntervalSince(now))))s")
                    .font(.headline)

                if wasTriggered {
                    Button("I heard it") {
                        appVM.markTestCompleted(context: context)
                        EventLogger.shared.logJSON(
                            .alarmEnded,
                            reason: .userConfirmedHeardSound,
                            payload: ["isTest": true, "heard": true],
                            context: context
                        )
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Cancel test") {
                    Task {
                        await NotificationScheduler.shared.cancelTestAlarm()
                        dismiss()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Test Alarm")
            .onAppear {
                fireAt = Date().addingTimeInterval(120)
                Task { await NotificationScheduler.shared.scheduleTestAlarm(fireAt: fireAt, context: context) }
            }
            .onReceive(timer) { value in
                now = value
                if appVM.activeTrigger?.isTest == true {
                    wasTriggered = true
                    EventLogger.shared.logJSON(
                        .alarmFired,
                        reason: nil,
                        payload: ["isTest": true, "triggeredAt": ISO8601DateFormatter().string(from: .now)],
                        context: context
                    )
                }
            }
        }
    }
}
