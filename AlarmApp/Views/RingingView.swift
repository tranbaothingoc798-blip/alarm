import SwiftUI
import SwiftData

struct RingingView: View {
    let alarmID: UUID
    let isTest: Bool

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var alarms: [Alarm]
    @StateObject private var vm = RingingViewModel()
    @State private var startedMission = false
    @State private var snoozeSlider: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .gray.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text(isTest ? "Test Alarm" : "Wake up")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if startedMission, let stage = vm.missionEngine.currentStage {
                    Text("Stage \(vm.missionEngine.stageIndex + 1) of \(vm.missionEngine.plan.stages.count) • \(formatted(seconds: vm.missionEngine.stageTimeRemaining))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                if startedMission {
                    MissionStageHostView(engine: vm.missionEngine) {
                        vm.missionCompleted(context: context)
                        if vm.run?.endedAt != nil {
                            if isTest { appVM.markTestCompleted(context: context) }
                            dismiss()
                        }
                    } onFailure: {
                        vm.missionFailed(context: context)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
                } else {
                    Button("Start Mission") {
                        startedMission = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !isTest, let alarm = currentAlarm, vm.canOfferSnooze(for: alarm) {
                    snoozeControl(alarm: alarm)
                }

                Spacer()

                Button("Emergency") { vm.showEmergency = true }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            if isTest {
                vm.beginTestRun(context: context)
            } else if let alarm = currentAlarm {
                vm.begin(alarm: alarm, context: context)
            }
        }
        .sheet(isPresented: $vm.showFallback) {
            FallbackChoiceView { type in vm.useFallback(type: type, context: context) }
        }
        .sheet(isPresented: $vm.showEmergency) {
            EmergencyStopSheet { vm.emergencyStop(reason: $0, context: context) }
        }
        .fullScreenCover(isPresented: $vm.showPostStop, onDismiss: { dismiss() }) {
            PostStopView(reason: vm.postStopReason, dueAt: vm.postStopDueAt)
        }
    }

    @ViewBuilder
    private func snoozeControl(alarm: Alarm) -> some View {
        let friction = vm.currentSnoozeFriction(alarm: alarm)
        switch friction {
        case .tap:
            Button("Snooze \(alarm.snoozeMinutes)m") {
                Task {
                    await vm.snooze(alarm: alarm, context: context)
                    dismiss()
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        case .slider:
            VStack(spacing: 6) {
                Text("Slide to snooze")
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.footnote)
                Slider(value: $snoozeSlider, in: 0...1)
                    .tint(.white)
                    .frame(maxWidth: 260)
                    .onChange(of: snoozeSlider) { _, new in
                        if new > 0.95 {
                            Task {
                                await vm.snooze(alarm: alarm, context: context)
                                dismiss()
                            }
                        }
                    }
            }
        case .holdToConfirm:
            Button("Hold to Snooze") {}
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1.2)
                        .onEnded { _ in
                            Task {
                                await vm.snooze(alarm: alarm, context: context)
                                dismiss()
                            }
                        }
                )
                .buttonStyle(.bordered)
                .tint(.white)
        }
    }

    private var currentAlarm: Alarm? {
        alarms.first(where: { $0.id == alarmID })
    }

    private func formatted(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let min = clamped / 60
        let sec = clamped % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
