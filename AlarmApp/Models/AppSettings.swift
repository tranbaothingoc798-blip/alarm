import Foundation
import SwiftData

@Model
final class AppSettings {
    var didRequestNotifications: Bool
    var didCompleteSoundTest: Bool
    var didCompleteTestAlarm: Bool
    var preferredProofTypeRaw: String
    var lastSchedulerRebuildAt: Date?
    var preferredPreset: String

    init(
        didRequestNotifications: Bool = false,
        didCompleteSoundTest: Bool = false,
        didCompleteTestAlarm: Bool = false,
        preferredProofTypeRaw: String = TestProofType.full.rawValue,
        lastSchedulerRebuildAt: Date? = nil,
        preferredPreset: String = "Beginner"
    ) {
        self.didRequestNotifications = didRequestNotifications
        self.didCompleteSoundTest = didCompleteSoundTest
        self.didCompleteTestAlarm = didCompleteTestAlarm
        self.preferredProofTypeRaw = preferredProofTypeRaw
        self.lastSchedulerRebuildAt = lastSchedulerRebuildAt
        self.preferredPreset = preferredPreset
    }

    var preferredProofType: TestProofType {
        get { TestProofType(rawValue: preferredProofTypeRaw) ?? .full }
        set { preferredProofTypeRaw = newValue.rawValue }
    }

    static func fetchOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
