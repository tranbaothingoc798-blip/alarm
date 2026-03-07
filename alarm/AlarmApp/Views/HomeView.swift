import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @StateObject private var vm = AlarmListViewModel()
    @State private var showingEditor = false
    @State private var alarmToEdit: Alarm?
    @State private var showingSetup = false
    @State private var showingSettings = false
    @State private var showingTestAlarm = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection

                        if !appVM.isSetupReady {
                            setupBanner
                        }

                        VStack(spacing: 12) {
                            ForEach(vm.alarms, id: \.id) { alarm in
                                alarmRow(alarm)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .appBackground()
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(AppTheme.background, for: .navigationBar)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showingTestAlarm = true
                        } label: {
                            Image(systemName: "alarm.waves.left.and.right")
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                .onAppear { vm.load(context: context) }
                .sheet(isPresented: $showingEditor, onDismiss: { vm.load(context: context); alarmToEdit = nil }) {
                    AlarmEditorView(existing: alarmToEdit)
                }
                .sheet(isPresented: $showingSetup) { SetupWizardView() }
                .sheet(isPresented: $showingSettings) { NavigationStack { SettingsView() } }
                .sheet(isPresented: $showingTestAlarm) { NavigationStack { TestAlarmView() } }
                .overlay {
                    if appVM.notificationsDenied {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            Text("Notifications are off")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Enable notifications to arm alarms.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("Open Settings") { appVM.openSystemSettings() }
                                .accentButton()
                        }
                        .padding(24)
                        .frame(maxWidth: 320)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                fabButton
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RISE")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Your wake-up missions")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var setupBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Finish setup to ensure alarms ring")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Takes about 30 seconds")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button("Fix setup") { showingSetup = true }
                .accentButton()
                .frame(maxWidth: 120)
        }
        .cardStyle()
    }

    private func alarmRow(_ alarm: Alarm) -> some View {
        let missionCount = MissionPlan.plan(for: alarm.missionPlanPreset).stages.count
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        let dayValues = [1, 2, 3, 4, 5, 6, 7]

        return HStack(alignment: .top) {
            Button {
                alarmToEdit = alarm
                showingEditor = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%02d:%02d", alarm.hour % 12 == 0 ? 12 : alarm.hour % 12, alarm.minute))
                            .font(AppTheme.timeFont)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(alarm.hour < 12 ? "AM" : "PM")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        ForEach(Array(dayLabels.enumerated()), id: \.offset) { idx, label in
                            Text(label)
                                .font(.caption2.bold())
                                .foregroundStyle(alarm.repeatWeekdays.contains(dayValues[idx]) ? AppTheme.background : AppTheme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(alarm.repeatWeekdays.contains(dayValues[idx]) ? AppTheme.accent : AppTheme.surfaceElevated)
                                .clipShape(Circle())
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(missionCount) missions required")
                            .font(AppTheme.captionFont)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            VStack(alignment: .trailing, spacing: 4) {
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in Task { await vm.toggle(alarm, context: context, canArm: !appVM.notificationsDenied) } }
                ))
                .labelsHidden()
                .toggleStyle(AppToggleStyle())
                .disabled(appVM.notificationsDenied)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(alarm.isEnabled ? AppTheme.surface : AppTheme.surface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            if alarm.isEnabled {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                Task { await vm.delete(alarm, context: context) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var fabButton: some View {
        Button {
            alarmToEdit = nil
            showingEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.background)
                .frame(width: 60, height: 60)
                .background(AppTheme.accent)
                .clipShape(Circle())
                .glowModifier(radius: 16, opacity: 0.5)
        }
        .buttonStyle(.plain)
        .disabled(appVM.notificationsDenied)
        .padding(.bottom, 24)
    }
}
