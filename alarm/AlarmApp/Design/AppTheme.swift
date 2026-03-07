import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - AppTheme
enum AppTheme {
    // Near-black background
    static let background = Color(hex: "0D0D0D")
    
    // Primary text - warm cream
    static let textPrimary = Color(hex: "F5F0E6")
    
    // Secondary text - muted warm grey
    static let textSecondary = Color(hex: "9A9590")
    
    // Accent - electric chartreuse
    static let accent = Color(hex: "C8FF00")
    
    // Refined dark surfaces (cards, inputs)
    static let surface = Color(hex: "1A1A1A")
    static let surfaceElevated = Color(hex: "242424")
    
    // Typography
    static let displayFont = Font.system(size: 48, weight: .bold, design: .rounded)
    static let timeFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.headline
    static let bodyFont = Font.subheadline
    static let captionFont = Font.footnote
    static let labelFont = Font.caption.weight(.semibold)
}

// MARK: - View Modifiers
extension View {
    func appBackground() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }
    
    func cardStyle(glow: Bool = false) -> some View {
        modifier(CardStyleModifier(glow: glow))
    }
    
    func accentButton() -> some View {
        buttonStyle(AccentButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func glowModifier(radius: CGFloat = 12, opacity: Double = 0.4) -> some View {
        shadow(color: AppTheme.accent.opacity(opacity), radius: radius)
    }
}

// MARK: - Pill Button Helper
func pillBackground(selected: Bool) -> some View {
    Group {
        if selected {
            AppTheme.accent.opacity(0.25)
        } else {
            AppTheme.textSecondary.opacity(0.2)
        }
    }
}

// MARK: - Day Circle Helper
func dayCircleBackground(selected: Bool) -> some View {
    Group {
        if selected {
            AppTheme.accent
        } else {
            AppTheme.surfaceElevated
        }
    }
}

// MARK: - CardStyleModifier
struct CardStyleModifier: ViewModifier {
    var glow: Bool = false
    var cornerRadius: CGFloat = 18
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if glow {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                }
            }
    }
}

// MARK: - AccentButtonStyle
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.4), radius: 12)
    }
}

// MARK: - SecondaryButtonStyle
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
            }
    }
}

// MARK: - AppToggleStyle
struct AppToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? AppTheme.accent : AppTheme.surfaceElevated)
                    .frame(width: 51, height: 31)
                    .overlay {
                        Circle()
                            .fill(AppTheme.background)
                            .frame(width: 27, height: 27)
                            .offset(x: configuration.isOn ? 10 : -10)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
