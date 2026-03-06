import SwiftUI

struct FallbackChoiceView: View {
    let onSelect: (MissionType) -> Void

    var body: some View {
        NavigationStack {
            List([MissionType.math, .typing, .shake], id: \.id) { type in
                Button(type.rawValue.capitalized) { onSelect(type) }
            }
            .navigationTitle("One-time fallback")
        }
    }
}
