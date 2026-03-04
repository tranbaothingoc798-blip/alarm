import SwiftUI

struct ShakeMissionView: View {
    let secondsRequired: Int
    let onSuccess: () -> Void
    let onFailure: () -> Void

    @StateObject private var motion = MotionManager()
    @State private var progress: Double = 0

    var body: some View {
        VStack {
            Text("Shake hard for \(secondsRequired)s")
            ProgressView(value: progress, total: Double(secondsRequired))
            if progress >= Double(secondsRequired) {
                Button("Continue") { onSuccess() }
            } else {
                Button("I can't") { onFailure() }
            }
        }
        .onAppear {
            motion.startShakeTracking { p in
                progress = p
            }
        }
        .onDisappear { motion.stop() }
    }
}
