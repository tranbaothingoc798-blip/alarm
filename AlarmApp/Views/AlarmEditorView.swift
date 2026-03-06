import SwiftUI
import SwiftData

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var vm = AlarmEditorViewModel()

    @State private var repeatMode: RepeatMode = .weekdays
    @State private var intensity: Intensity = .standard

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    timeCard
                    repeatCard
                    missionCard
                    labelCard
                    soundCard
                    advancedCard
                }
                .padding()
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.preset = mappedPreset
                        vm.save(context: context)
                        let alarms = (try? context.fetch(FetchDescriptor<Alarm>())) ?? []
                        Task { await NotificationScheduler.shared.rebuildSchedule(alarms: alarms, context: context) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                vm.repeatWeekdays = [2, 3, 4, 5, 6]
            }
        }
    }

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time")
                .font(.headline)
            DatePicker("", selection: $vm.date, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .cardStyle()
    }

    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Repeat")
                .font(.headline)

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

    private func modePill(_ mode: RepeatMode, _ title: String) -> some View {
        Button(title) {
            repeatMode = mode
            switch mode {
            case .weekdays: vm.repeatWeekdays = [2, 3, 4, 5, 6]
            case .weekends: vm.repeatWeekdays = [1, 7]
            case .custom: break
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(repeatMode == mode ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    private var dayGrid: some View {
        let days: [(label: String, value: Int)] = [("S",1),("M",2),("T",3),("W",4),("T",5),("F",6),("S",7)]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                let selected = vm.repeatWeekdays.contains(day.value)
                Button(day.label) {
                    if selected { vm.repeatWeekdays.remove(day.value) }
                    else { vm.repeatWeekdays.insert(day.value) }
                }
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mission Intensity")
                .font(.headline)
            HStack(spacing: 8) {
                intensityPill(.beginner, "Beginner")
                intensityPill(.standard, "Standard")
                intensityPill(.ruthless, "Ruthless")
            }
        }
        .cardStyle()
    }

    private func intensityPill(_ value: Intensity, _ label: String) -> some View {
        Button(label) {
            intensity = value
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(intensity == value ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    private var labelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Label")
                .font(.headline)
            TextField("Alarm", text: $vm.label)
                .textFieldStyle(.roundedBorder)
        }
        .cardStyle()
    }

    private var soundCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sound")
                .font(.headline)

            Picker("", selection: $vm.soundName) {
                Text("Alarm").tag("alarm")
                Text("Beep").tag("beep")
                Text("Siren").tag("siren")
            }
            .pickerStyle(.segmented)

            Button("Test") {
                AudioManager.shared.startLoop(soundName: vm.soundName)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    AudioManager.shared.stop()
                }
            }
            .buttonStyle(.bordered)
        }
        .cardStyle()
    }

    private var advancedCard: some View {
        DisclosureGroup("Advanced") {
            Picker("Ramp", selection: $vm.rampStyle) {
                ForEach(RampStyle.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)
        }
        .cardStyle()
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

private extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
