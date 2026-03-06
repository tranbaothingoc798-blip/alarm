import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @StateObject private var vm = AlarmListViewModel()
    @State private var showingEditor = false
    @State private var showingSetup = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    nextAlarmCard

                    if !appVM.isSetupReady {
                        setupBanner
                    }

                    VStack(spacing: 10) {
                        ForEach(vm.alarms, id: \.id) { alarm in
                            alarmRow(alarm)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(appVM.notificationsDenied)
                }
            }
            .onAppear { vm.load(context: context) }
            .sheet(isPresented: $showingEditor, onDismiss: { vm.load(context: context) }) {
                AlarmEditorView()
            }
            .sheet(isPresented: $showingSetup) { SetupWizardView() }
            .sheet(isPresented: $showingSettings) { NavigationStack { SettingsView() } }
            .overlay {
                if appVM.notificationsDenied {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    VStack(spacing: 10) {
                        Text("Notifications are off")
                            .font(.headline)
                        Text("Enable notifications to arm alarms.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") { appVM.openSystemSettings() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: 320)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var nextAlarmCard: some View {
        Button {
            if !appVM.isSetupReady { showingSetup = true }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("Next Alarm")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(vm.nextAlarmText())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Text(appVM.isSetupReady ? "Ready" : "Needs setup")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(appVM.isSetupReady ? Color.green.opacity(0.18) : Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var setupBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Finish setup to ensure alarms ring")
                    .font(.headline)
                Text("Takes about 30 seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Fix setup") { showingSetup = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func alarmRow(_ alarm: Alarm) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
                    .font(.title3.bold())
                Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in Task { await vm.toggle(alarm, context: context, canArm: !appVM.notificationsDenied) } }
            ))
            .labelsHidden()
            .disabled(appVM.notificationsDenied)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
