import SwiftUI
import SwiftData

struct RingingView: View {
    let alarmID: UUID
    let isTest: Bool
    let testProofType: TestProofType?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var alarms: [Alarm]
    @StateObject private var vm = RingingViewModel()
    @State private var startedMission = false
    @State private var snoozeSlider: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            RadialGradient(
                colors: [AppTheme.accent.opacity(0.08), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(headerLabel)
                    .font(AppTheme.labelFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(formattedTime(Date()))
                    .font(AppTheme.displayFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(formattedDate(Date()))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)

                if shouldShowMission, startedMission, let stage = vm.missionEngine.currentStage {
                    Text("Stage \(vm.missionEngine.stageIndex + 1) of \(vm.missionEngine.plan.stages.count) • \(formatted(seconds: vm.missionEngine.stageTimeRemaining))")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if shouldShowMission, startedMission {
                    MissionStageHostView(engine: vm.missionEngine) {
                        vm.missionCompleted(context: context)
                        if vm.run?.endedAt != nil, vm.run?.stopReason != .success {
                            if isTest { appVM.markTestCompleted(context: context) }
                            dismiss()
                        } else if vm.run?.endedAt != nil, isTest {
                            appVM.markTestCompleted(context: context)
                        }
                    } onFailure: {
                        vm.missionFailed(context: context)
                    }
                    .padding()
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
                } else if shouldShowMission {
                    missionsCard
                    if vm.session != nil {
                        Button("Silence for 10 seconds") { vm.requestGrace() }
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal)
                    }
                    Button("Begin First Mission") {
                        startedMission = true
                    }
                    .accentButton()
                    .padding(.horizontal)
                } else if isTest {
                    centralSpeakerIcon
                    Button("I Heard It") {
                        vm.confirmQuietProofHeard(context: context)
                        appVM.markTestCompleted(context: context)
                        dismiss()
                    }
                    .accentButton()
                    .padding(.horizontal)
                }

                if !isTest, let alarm = currentAlarm, vm.canOfferSnooze(for: alarm) {
                    snoozeControl(alarm: alarm)
                }

                if vm.session?.isGraceActive == true {
                    Text("Silence: \(vm.session?.graceSecondsRemaining ?? 0)s")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                } else if vm.session != nil, startedMission {
                    Button("Silence for 10 seconds") { vm.requestGrace() }
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                Button("Emergency") { vm.showEmergency = true }
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .onAppear {
            if isTest {
                vm.beginTestRun(proofType: testProofType ?? .full, context: context)
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
        .fullScreenCover(isPresented: $vm.showMissionComplete, onDismiss: { dismiss() }) {
            MissionCompleteView(
                plan: vm.missionEngine.plan,
                completedAt: vm.run?.endedAt ?? Date(),
                isTest: vm.run?.isTest ?? false
            ) {
                vm.showMissionComplete = false
            }
        }
    }

    private var centralSpeakerIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 120, height: 120)
                .glowModifier(radius: 24, opacity: 0.5)
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.background)
        }
        .padding(.vertical, 16)
    }

    private var missionsCard: some View {
        let plan = vm.missionEngine.plan
        let completed = vm.missionEngine.stageIndex
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MISSIONS TO COMPLETE")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(completed)/\(plan.stages.count)")
                    .font(AppTheme.labelFont)
                    .foregroundStyle(AppTheme.accent)
            }
            ForEach(plan.stages, id: \.id) { stage in
                let idx = plan.stages.firstIndex(where: { $0.id == stage.id }) ?? 0
                let isDone = idx < completed
                HStack(spacing: 12) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isDone ? AppTheme.accent : AppTheme.textSecondary)
                    Text(missionDisplayName(stage.missionType))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func missionDisplayName(_ type: MissionType) -> String {
        switch type {
        case .typing: return "Typing Challenge"
        case .math: return "Math Challenge"
        case .shake: return "Shake to Wake"
        case .steps: return "Steps"
        case .barcode: return "Barcode Scan"
        case .memory: return "Pattern Memory"
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
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
            .secondaryButton()
            .padding(.horizontal)
        case .slider:
            VStack(spacing: 8) {
                Text("Slide to snooze")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Slider(value: $snoozeSlider, in: 0...1)
                    .tint(AppTheme.accent)
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
                .secondaryButton()
                .padding(.horizontal)
        }
    }

    private var headerLabel: String {
        if isTest { return "Test Alarm".uppercased() }
        guard let alarm = currentAlarm else { return "Alarm" }
        return alarm.label.isEmpty ? "Alarm" : alarm.label.uppercased()
    }

    private var currentAlarm: Alarm? {
        alarms.first(where: { $0.id == alarmID })
    }

    private var shouldShowMission: Bool {
        !isTest || (testProofType ?? .full) == .full
    }

    private func formatted(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let min = clamped / 60
        let sec = clamped % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
