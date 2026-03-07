import SwiftUI

struct ShakeMissionView: View {
    let secondsRequired: Int
    let onSuccess: () -> Void
    let onFailure: () -> Void

    @StateObject private var motion = MotionManager()
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 140, height: 140)
                    .glowModifier(radius: 24, opacity: 0.5)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.background)
            }
            .padding(.top, 16)

            Text("\(Int(progress))s / \(secondsRequired)s")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Shake your phone to continue")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            if progress >= Double(secondsRequired) {
                Button("Continue") { onSuccess() }
                    .accentButton()
            } else {
                Button("I can't") { onFailure() }
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            #if targetEnvironment(simulator)
            Button("Test +5 (Simulator)") {
                progress = min(Double(secondsRequired), progress + 5)
            }
            .secondaryButton()
            .frame(maxWidth: 200)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            motion.startShakeTracking { p in
                progress = p
            }
        }
        .onDisappear { motion.stop() }
    }
}
