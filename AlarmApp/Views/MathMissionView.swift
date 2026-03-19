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
        VStack {
            Text("Solve: \(a) + \(b)×\(max(1, difficulty))")
            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button("Check") {
                if Int(answer) == expected { onSuccess() }
                else {
                    onFailure()
                    a = Int.random(in: 1...20)
                    b = Int.random(in: 1...20)
                    answer = ""
                }
            }
        }
    }
}
