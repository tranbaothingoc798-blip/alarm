import Foundation
import SwiftData

@MainActor
final class AlarmEditorViewModel: ObservableObject {
    @Published var date = Date()

    var hour12: Int {
        let h = Calendar.current.component(.hour, from: date)
        return h == 0 ? 12 : (h > 12 ? h - 12 : h)
    }
    var minute: Int { Calendar.current.component(.minute, from: date) }
    var isPM: Bool { Calendar.current.component(.hour, from: date) >= 12 }

    func setAMPM(_ pm: Bool) {
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let h = comps.hour ?? 0
        if pm && h < 12 { comps.hour = h + 12 }
        else if !pm && h >= 12 { comps.hour = h - 12 }
        date = Calendar.current.date(from: comps) ?? date
    }

    func setHour(_ hour12: Int, minute: Int, isPM: Bool) {
        var h = hour12
        if isPM && hour12 != 12 { h += 12 }
        else if !isPM && hour12 == 12 { h = 0 }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = h
        comps.minute = minute
        date = Calendar.current.date(from: comps) ?? date
    }
    @Published var repeatWeekdays: Set<Int> = []
    @Published var label = "Alarm"
    @Published var soundName = "alarm"
    @Published var rampStyle: RampStyle = .slow
    @Published var preset: MissionPlanPreset = .standard

    func load(from alarm: Alarm) {
        var comps = DateComponents()
        comps.hour = alarm.hour
        comps.minute = alarm.minute
        date = Calendar.current.date(from: comps) ?? Date()
        repeatWeekdays = Set(alarm.repeatWeekdays)
        label = alarm.label
        soundName = alarm.soundName
        rampStyle = alarm.rampStyle
        preset = alarm.missionPlanPreset
    }

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
