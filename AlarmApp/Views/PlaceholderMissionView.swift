import SwiftUI

struct PlaceholderMissionView: View {
    let title: String
    var body: some View {
        VStack {
            Text(title)
            Text("Disabled in MVP")
                .foregroundStyle(.secondary)
        }
    }
}
