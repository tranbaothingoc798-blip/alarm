import SwiftUI

struct TypingMissionView: View {
    @State private var phrase = TypingMissionView.randomPhrase()
    @State private var typed = ""
    let onSuccess: () -> Void
    let onFailure: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Typing Challenge")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Type exactly:")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            Text(phrase)
                .font(.title2)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding()

            TextField("Enter phrase", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .padding()
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button("Submit") {
                if typed == phrase { onSuccess() }
                else {
                    onFailure()
                    typed = ""
                    phrase = Self.randomPhrase()
                }
            }
            .accentButton()

            Button("I can't") { onFailure() }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
    }

    static func randomPhrase() -> String {
        ["i am awake now", "focus and breathe", "stand up and move", "mission complete soon"].randomElement()!
    }
}
