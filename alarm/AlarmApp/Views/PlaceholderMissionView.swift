import SwiftUI

struct PlaceholderMissionView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Coming soon")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
    }
}
