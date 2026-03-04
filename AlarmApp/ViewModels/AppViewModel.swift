import Foundation
import UserNotifications
import SwiftData
import SwiftUI
import UIKit

struct AlarmTrigger: Identifiable {
    let id: UUID
    let isTest: Bool
}

@MainActor
final class AppViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var showOnboarding = true
    @Published var showSetupWizard = true
    @Published var activeTrigger: AlarmTrigger?
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var settings: AppSettings?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    var isSetupReady: Bool {
        notificationStatus == .authorized
        && (settings?.didCompleteSoundTest ?? false)
        && (settings?.didCompleteTestAlarm ?? false)
        && (NotificationScheduler.shared.cachedPendingCount > 0)
    }

    var notificationsDenied: Bool {
        notificationStatus == .denied
    }

    func bootstrap(context: ModelContext) async {
        settings = AppSettings.fetchOrCreate(in: context)
        showOnboarding = !(settings?.didRequestNotifications ?? false)
        await refreshNotificationStatus()
        await refreshPendingCount()
        showSetupWizard = !isSetupReady
    }

    func refreshNotificationStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationStatus = status
    }

    func refreshPendingCount() async {
        _ = await NotificationScheduler.shared.pendingCount()
    }

    func requestNotifications(context: ModelContext) async {
        let granted = await NotificationScheduler.shared.requestPermission()
        settings?.didRequestNotifications = true
        try? context.save()
        notificationStatus = granted ? .authorized : .denied
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func playSoundTest(context: ModelContext) {
        AudioManager.shared.startLoop(soundName: "alarm")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            AudioManager.shared.stop()
        }
        settings?.didCompleteSoundTest = true
        try? context.save()
    }

    func markTestCompleted(context: ModelContext) {
        settings?.didCompleteTestAlarm = true
        try? context.save()
        showSetupWizard = !isSetupReady
    }

    func updateLastSchedulerRebuild(_ date: Date, context: ModelContext) {
        settings?.lastSchedulerRebuildAt = date
        try? context.save()
    }

    func handleNotificationResponse(_ userInfo: [AnyHashable: Any]) {
        if let isTest = userInfo["isTestAlarm"] as? Bool, isTest {
            activeTrigger = AlarmTrigger(id: UUID(), isTest: true)
            return
        }
        guard let idString = userInfo["alarmID"] as? String, let id = UUID(uuidString: idString) else { return }
        activeTrigger = AlarmTrigger(id: id, isTest: false)
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            self.handleNotificationResponse(response.notification.request.content.userInfo)
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await MainActor.run {
            self.handleNotificationResponse(notification.request.content.userInfo)
        }
        return [.banner, .sound]
    }
}
