import SwiftUI

// MARK: - Design Tokens
struct DesignTokens {
    // MARK: - Colors
    struct Colors {
        // 主色系
        static let primary = Color(hex: "#007AFF")
        static let primaryLight = Color(hex: "#4DA6FF")
        static let primaryDark = Color(hex: "#0056CC")
        
        // 功能色系
        static let success = Color(hex: "#34C759")
        static let warning = Color(hex: "#FF9500")
        static let error = Color(hex: "#FF3B30")
        static let info = Color(hex: "#5AC8FA")
        
        // 中性色系
        static let background = Color(hex: "#F2F2F7")
        static let surface = Color.white
        static let surfaceSecondary = Color(hex: "#F8F9FA")
        static let border = Color(hex: "#E5E5EA")
        
        // 文字色系
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(hex: "#8E8E93")
        
        // 渐变色组
        static let successGradient = [success, Color(hex: "#30B050")]
        static let warningGradient = [warning, Color(hex: "#FF8C00")]
        static let primaryGradient = [primary, Color(hex: "#5A9FFF")]
        static let backgroundGradient = [Color(hex: "#667eea"), Color(hex: "#764ba2")]
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .default, weight: .bold)
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        static let title3 = Font.system(.title3, design: .default, weight: .semibold)
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let callout = Font.system(.callout, design: .default, weight: .medium)
        static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .regular)
        static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.2)
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let bouncy = SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.6)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Custom View Modifiers
struct GlassMorphism: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: DesignTokens.Shadow.medium, radius: 10, x: 0, y: 5)
    }
}

struct PremiumCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .shadow(color: DesignTokens.Shadow.light, radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(DesignTokens.Colors.border, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassMorphism(cornerRadius: CGFloat = DesignTokens.CornerRadius.lg) -> some View {
        modifier(GlassMorphism(cornerRadius: cornerRadius))
    }
    
    func premiumCard() -> some View {
        modifier(PremiumCard())
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        HapticManager.impact(style)
    }
} 