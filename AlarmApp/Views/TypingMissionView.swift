import SwiftUI

struct TypingMissionView: View {
    @State private var phrase = TypingMissionView.randomPhrase()
    @State private var typed = ""
    let onSuccess: () -> Void
    let onFailure: () -> Void

    var body: some View {
        VStack {
            Text("Type exactly:")
            Text(phrase).font(.headline)
            TextField("Enter phrase", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            Button("Submit") {
                if typed == phrase { onSuccess() }
                else {
                    onFailure()
                    typed = ""
                    phrase = Self.randomPhrase()
                }
            }
        }
    }

    static func randomPhrase() -> String {
        ["i am awake now", "focus and breathe", "stand up and move", "mission complete soon"].randomElement()!
    }
}
