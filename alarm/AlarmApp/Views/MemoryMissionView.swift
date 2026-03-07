import SwiftUI

struct MemoryMissionView: View {
    let sequenceLength: Int
    let onSuccess: () -> Void
    let onFailure: () -> Void

    private static let colors: [Color] = [
        AppTheme.accent,
        AppTheme.textPrimary,
        AppTheme.textSecondary,
        AppTheme.surface,
        AppTheme.accent.opacity(0.6)
    ]

    @State private var sequence: [Int] = []
    @State private var phase: Phase = .memorize
    @State private var userInput: [Int] = []
    @State private var showCountdown = true
    @State private var countdown = 3

    enum Phase { case memorize, recall }

    var body: some View {
        VStack(spacing: 24) {
            Text(phase == .memorize ? "Memorize the order" : "Tap in the same order")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)

            if showCountdown {
                Text("\(countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            } else if phase == .memorize {
                sequenceView
            } else {
                recallView
            }

            if phase == .recall {
                Button("I can't") { onFailure() }
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
        .onAppear { startMission() }
    }

    private var sequenceView: some View {
        HStack(spacing: 16) {
            ForEach(Array(sequence.enumerated()), id: \.offset) { _, idx in
                circle(color: Self.colors[sequence[idx]])
                    .frame(width: 48, height: 48)
            }
        }
    }

    private var recallView: some View {
        HStack(spacing: 16) {
            ForEach(0..<Self.colors.count, id: \.self) { idx in
                Button {
                    userInput.append(idx)
                    if userInput.count == sequence.count {
                        if userInput == sequence { onSuccess() }
                        else { onFailure() }
                    }
                } label: {
                    circle(color: Self.colors[idx])
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func circle(color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay {
                Circle()
                    .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
            }
    }

    private func startMission() {
        sequence = (0..<min(max(2, sequenceLength), Self.colors.count)).map { _ in Int.random(in: 0..<Self.colors.count) }
        phase = .memorize
        showCountdown = true
        countdown = 3
        userInput = []

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                showCountdown = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    phase = .recall
                }
            }
        }
    }
}
