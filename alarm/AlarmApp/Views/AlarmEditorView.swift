import SwiftUI
import SwiftData

struct AlarmEditorView: View {
    var existing: Alarm?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var vm = AlarmEditorViewModel()

    @State private var repeatMode: RepeatMode = .weekdays
    @State private var intensity: Intensity = .standard

    init(existing: Alarm? = nil) {
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    timeCard
                    labelCard
                    repeatCard
                    missionCard
                    soundCard
                    advancedCard

                    Button {
                        vm.preset = mappedPreset
                        vm.save(existing: existing, context: context)
                        let alarms = AlarmRepository.fetchAll(context: context)
                        Task { await NotificationScheduler.shared.rebuildSchedule(alarms: alarms, context: context) }
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                            Text("Set Wake Missions")
                        }
                    }
                    .accentButton()
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(existing == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .onAppear {
                if let existing { vm.load(from: existing); syncRepeatModeFromWeekdays() }
                else { vm.repeatWeekdays = [2, 3, 4, 5, 6] }
            }
        }
    }

    private var timeCard: some View {
        VStack(spacing: 16) {
            DatePicker("", selection: $vm.date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorMultiply(AppTheme.textPrimary)
                .scaleEffect(1.2)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                amPmPill(isPM: false)
                amPmPill(isPM: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func amPmPill(isPM: Bool) -> some View {
        let selected = vm.isPM == isPM
        return Button {
            vm.setAMPM(isPM)
        } label: {
            Text(isPM ? "PM" : "AM")
                .font(.headline)
                .foregroundStyle(selected ? AppTheme.background : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? AppTheme.accent : AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
            }
        }
    }

    private var labelCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LABEL")
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("Alarm", text: $vm.label)
                .foregroundStyle(AppTheme.textPrimary)
                .padding()
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .cardStyle()
    }

    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REPEAT")
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                modePill(.weekdays, "Weekdays")
                modePill(.weekends, "Weekends")
                modePill(.custom, "Custom")
            }
            if repeatMode == .custom {
                dayGrid
            }
        }
        .cardStyle()
    }

    private var dayGrid: some View {
        let days: [(label: String, value: Int)] = [("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7)]
        return HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                let selected = vm.repeatWeekdays.contains(day.value)
                Button(day.label) {
                    if selected { vm.repeatWeekdays.remove(day.value) }
                    else { vm.repeatWeekdays.insert(day.value) }
                }
                .font(.subheadline.bold())
                .foregroundStyle(selected ? AppTheme.background : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? AppTheme.accent : AppTheme.surfaceElevated)
                .clipShape(Circle())
                .overlay {
                    if selected {
                        Circle()
                            .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mission Intensity")
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                intensityPill(.beginner, "Beginner")
                intensityPill(.standard, "Standard")
                intensityPill(.ruthless, "Ruthless")
            }
        }
        .cardStyle()
    }

    private func modePill(_ mode: RepeatMode, _ title: String) -> some View {
        Button {
            repeatMode = mode
            switch mode {
            case .weekdays: vm.repeatWeekdays = [2, 3, 4, 5, 6]
            case .weekends: vm.repeatWeekdays = [1, 7]
            case .custom: break
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(repeatMode == mode ? AppTheme.background : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(repeatMode == mode ? AppTheme.accent : AppTheme.surfaceElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func intensityPill(_ value: Intensity, _ label: String) -> some View {
        Button {
            intensity = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(intensity == value ? AppTheme.background : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(intensity == value ? AppTheme.accent : AppTheme.surfaceElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var soundCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sound")
                .font(AppTheme.labelFont)
                .foregroundStyle(AppTheme.textSecondary)
            Picker("", selection: $vm.soundName) {
                Text("Alarm").tag("alarm")
                Text("Beep").tag("beep")
                Text("Siren").tag("siren")
            }
            .pickerStyle(.segmented)
            .colorMultiply(AppTheme.accent)

            Button("Test") {
                AudioManager.shared.startLoop(soundName: vm.soundName)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    AudioManager.shared.stop()
                }
            }
            .secondaryButton()
            .frame(maxWidth: 120)
        }
        .cardStyle()
    }

    private var advancedCard: some View {
        DisclosureGroup {
            Picker("Ramp", selection: $vm.rampStyle) {
                ForEach(RampStyle.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .colorMultiply(AppTheme.accent)
            .padding(.top, 8)
        } label: {
            Text("Advanced")
                .foregroundStyle(AppTheme.textPrimary)
        }
        .tint(AppTheme.accent)
        .cardStyle()
    }

    private func syncRepeatModeFromWeekdays() {
        let set = vm.repeatWeekdays
        if set == Set([2, 3, 4, 5, 6]) { repeatMode = .weekdays }
        else if set == Set([1, 7]) { repeatMode = .weekends }
        else { repeatMode = .custom }
        switch vm.preset {
        case .standard: intensity = .standard
        case .ruthless: intensity = .ruthless
        }
    }

    private var mappedPreset: MissionPlanPreset {
        switch intensity {
        case .beginner, .standard: return .standard
        case .ruthless: return .ruthless
        }
    }
}

private enum RepeatMode {
    case weekdays, weekends, custom
}

private enum Intensity {
    case beginner, standard, ruthless
}
