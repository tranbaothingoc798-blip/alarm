import SwiftUI

struct MathMissionView: View {
    let difficulty: Int
    let onSuccess: () -> Void
    let onFailure: () -> Void

    @State private var a = Int.random(in: 1...9)
    @State private var b = Int.random(in: 1...9)
    @State private var answer = ""

    var expected: Int { a + b * max(1, difficulty) }

    var body: some View {
        VStack(spacing: 24) {
            Text("Math Challenge")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Solve: \(a) + \(b)×\(max(1, difficulty))")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(.title2)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding()
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button("Check") {
                if Int(answer) == expected { onSuccess() }
                else {
                    onFailure()
                    a = Int.random(in: 1...20)
                    b = Int.random(in: 1...20)
                    answer = ""
                }
            }
            .accentButton()

            Button("I can't") { onFailure() }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
    }
}
