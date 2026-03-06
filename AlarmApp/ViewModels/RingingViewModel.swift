import Foundation
import SwiftData
import UserNotifications

@MainActor
final class RingingViewModel: ObservableObject {
    @Published var run: AlarmRun?
    @Published var showEmergency = false
    @Published var showFallback = false
    @Published var showPostStop = false
    @Published var postStopReason: EmergencyReason = .other
    @Published var postStopDueAt: Date?

    let missionEngine = MissionEngine()
    private let audio = AudioManager.shared
    private var currentTestProofType: TestProofType = .full

    func begin(alarm: Alarm, context: ModelContext) {
        let run = AlarmRun(alarmID: alarm.id)
        context.insert(run)
        self.run = run
        audio.startLoop(soundName: alarm.soundName)
        missionEngine.start(plan: .plan(for: alarm.missionPlanPreset))

        EventLogger.shared.logJSON(
            .ringingStarted,
            runID: run.id,
            alarmID: alarm.id,
            payload: [
                "isTest": false,
                "alarmLabel": alarm.label,
                "soundName": alarm.soundName,
                "rampStyle": alarm.rampStyle.rawValue,
                "missionPreset": alarm.missionPlanPreset.rawValue
            ],
            context: context
        )
    }

    func beginTestRun(proofType: TestProofType, context: ModelContext) {
        let run = AlarmRun(alarmID: nil, isTest: true)
        context.insert(run)
        self.run = run
        currentTestProofType = proofType
        audio.startLoop(soundName: "alarm")
        if proofType == .full {
            missionEngine.start(plan: .plan(for: .standard))
        }

        EventLogger.shared.logJSON(
            .ringingStarted,
            runID: run.id,
            payload: [
                "isTest": true,
                "proofType": proofType.rawValue,
                "alarmLabel": "Test Alarm",
                "soundName": "alarm",
                "rampStyle": RampStyle.fast.rawValue,
                "missionPreset": MissionPlanPreset.standard.rawValue
            ],
            context: context
        )
    }

    func confirmQuietProofHeard(context: ModelContext) {
        finish(reason: .success, emergency: nil, userConfirmedHeard: true, context: context)
    }

    func currentSnoozeFriction(alarm: Alarm) -> SnoozeFrictionLevel {
        let count = run?.snoozeCount ?? 0
        if count <= 0 { return .tap }
        if count == 1 { return .slider }
        return .holdToConfirm
    }

    func canOfferSnooze(for alarm: Alarm) -> Bool {
        guard let run else { return false }
        if run.isTest { return false }
        return run.snoozeCount < alarm.maxSnoozes
    }

    func snooze(alarm: Alarm, context: ModelContext) async {
        guard let run else { return }
        guard run.snoozeCount < alarm.maxSnoozes else {
            EventLogger.shared.logJSON(
                .alarmSnoozed,
                runID: run.id,
                alarmID: run.alarmID,
                reason: .maxSnoozesReached,
                payload: ["status": "blocked", "reason": "max_snoozes_reached", "maxSnoozes": alarm.maxSnoozes],
                context: context
            )
            return
        }

        let usedFriction = currentSnoozeFriction(alarm: alarm)
        audio.stop()
        run.snoozeCount += 1
        let added = max(1, alarm.snoozeMinutes) * 60
        run.snoozeTotalSeconds += added
        run.lastSnoozeAt = .now
        let fireAt = Date().addingTimeInterval(TimeInterval(added))

        try? context.save()
        await NotificationScheduler.shared.cancelPendingAlarms(for: alarm.id)
        await NotificationScheduler.shared.cancelPendingSnoozes(for: run.id)
        await NotificationScheduler.shared.scheduleSnooze(alarm: alarm, runID: run.id, fireAt: fireAt, context: context)

        EventLogger.shared.logJSON(
            .alarmSnoozed,
            runID: run.id,
            alarmID: run.alarmID,
            payload: [
                "snoozeCount": run.snoozeCount,
                "snoozeMinutes": alarm.snoozeMinutes,
                "nextFireAt": ISO8601DateFormatter().string(from: fireAt),
                "nextFriction": currentSnoozeFriction(alarm: alarm).rawValue,
                "usedFriction": usedFriction.rawValue
            ],
            context: context
        )
    }

    func missionFailed(context: ModelContext) {
        missionEngine.recordFailure()
        EventLogger.shared.log(.missionFailed, runID: run?.id, alarmID: run?.alarmID, context: context)
        if missionEngine.fallbackEligible, !(run?.usedFallback ?? true) {
            showFallback = true
            EventLogger.shared.log(.fallbackOffered, runID: run?.id, alarmID: run?.alarmID, context: context)
        }
    }

    func missionCompleted(context: ModelContext) {
        if missionEngine.completeCurrentStage() {
            finish(reason: .success, emergency: nil, context: context)
            EventLogger.shared.log(.alarmSuccess, runID: run?.id, alarmID: run?.alarmID, context: context)
        }
    }

    func useFallback(type: MissionType, context: ModelContext) {
        run?.usedFallback = true
        run?.penaltyPoints += 2
        missionEngine.useFallback()
        showFallback = false
        EventLogger.shared.logJSON(
            .fallbackUsed,
            runID: run?.id,
            alarmID: run?.alarmID,
            payload: ["missionType": type.rawValue, "penalty": 2],
            context: context
        )
    }

    func emergencyStop(reason: EmergencyReason, context: ModelContext) {
        audio.stop()
        run?.penaltyPoints += 3
        run?.emergencyReason = reason
        finish(reason: .emergencyStop, emergency: reason, context: context)

        if let run {
            let dueAt = Date().addingTimeInterval(1800)
            let task = MakeUpTask(runID: run.id, dueAt: dueAt)
            context.insert(task)
            try? context.save()
            scheduleMakeUpNotification(task: task)
            postStopReason = reason
            postStopDueAt = dueAt
            showPostStop = true
        }
    }

    func stopAudio() { audio.stop() }

    private func finish(reason: AlarmStopReason, emergency: EmergencyReason?, userConfirmedHeard: Bool? = nil, context: ModelContext) {
        audio.stop()
        run?.stopReason = reason
        run?.emergencyReason = emergency
        run?.endedAt = .now
        try? context.save()

        if let alarmID = run?.alarmID {
            Task {
                await NotificationScheduler.shared.cancelPendingAlarms(for: alarmID)
            }
        }
        if let runID = run?.id {
            Task {
                await NotificationScheduler.shared.cancelPendingSnoozes(for: runID)
            }
        }

        EventLogger.shared.logJSON(
            .alarmEnded,
            runID: run?.id,
            alarmID: run?.alarmID,
            payload: [
                "reason": reason.rawValue,
                "isTest": run?.isTest ?? false,
                "snoozeCount": run?.snoozeCount ?? 0,
                "penaltyPoints": run?.penaltyPoints ?? 0,
                "proofType": (run?.isTest ?? false) ? currentTestProofType.rawValue : "",
                "userConfirmedHeard": userConfirmedHeard ?? false
            ],
            context: context
        )
    }

    private func scheduleMakeUpNotification(task: MakeUpTask) {
        let content = UNMutableNotificationContent()
        content.title = "Make-up mission due"
        content.body = "Complete your make-up task"
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "\(NotificationScheduler.shared.makeupPrefix)\(task.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
