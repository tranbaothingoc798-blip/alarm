import Foundation
import SwiftData

@MainActor
final class AlarmEditorViewModel: ObservableObject {
    @Published var date = Date()
    @Published var repeatWeekdays: Set<Int> = []
    @Published var label = "Alarm"
    @Published var soundName = "alarm"
    @Published var rampStyle: RampStyle = .slow
    @Published var preset: MissionPlanPreset = .standard

    func save(existing: Alarm? = nil, context: ModelContext) {
        let hm = Calendar.current.dateComponents([.hour, .minute], from: date)
        let target = existing ?? Alarm(hour: hm.hour ?? 7, minute: hm.minute ?? 0, repeatWeekdays: [], label: label, soundName: soundName, rampStyle: rampStyle, missionPlanPreset: preset)
        target.hour = hm.hour ?? 7
        target.minute = hm.minute ?? 0
        target.repeatWeekdays = Array(repeatWeekdays)
        target.label = label
        target.soundName = soundName
        target.rampStyle = rampStyle
        target.missionPlanPreset = preset
        if existing == nil { context.insert(target) }
        try? context.save()
    }
}
