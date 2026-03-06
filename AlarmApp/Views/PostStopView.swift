import SwiftUI
import SwiftData

struct PostStopView: View {
    let reason: EmergencyReason
    let dueAt: Date?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Alarm stopped.")
                    .font(.title.bold())
                Text("You used Emergency Stop: \(reason.rawValue)")
                Text("Make-up mission due \(dueAtText)")
                    .foregroundStyle(.secondary)

                Button("Go Home") { dismiss() }
                    .buttonStyle(.borderedProminent)
                NavigationLink("View Make-up") {
                    StatsView()
                }
            }
            .padding()
        }
    }

    private var dueAtText: String {
        if let dueAt { return "at \(dueAt.formatted(date: .omitted, time: .shortened))" }
        return "in 30 minutes"
    }
}
