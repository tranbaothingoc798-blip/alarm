import SwiftUI

struct EmergencyStopSheet: View {
    let onConfirm: (EmergencyReason) -> Void
    @State private var selected: EmergencyReason = .exhausted
    @State private var held = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Emergency Stop")
                .font(.title.bold())
            Picker("Reason", selection: $selected) {
                ForEach(EmergencyReason.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.wheel)

            Text("Hold 2 seconds to stop")
            Button("Hold to Stop") {}
                .buttonStyle(.borderedProminent)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 2)
                        .onEnded { _ in
                            held = true
                            onConfirm(selected)
                        }
                )
        }
        .padding()
    }
}
