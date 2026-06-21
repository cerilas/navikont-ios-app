import SwiftUI

// MARK: - NaviKont Design System

struct NKColors {
    // Primary palette
    static let primaryGradientStart = Color(hex: "667EEA")
    static let primaryGradientEnd = Color(hex: "764BA2")
    
    // Accent palette
    static let accentTeal = Color(hex: "2DD4BF")
    static let accentCyan = Color(hex: "22D3EE")
    static let accentAmber = Color(hex: "FBBF24")
    static let accentRose = Color(hex: "FB7185")
    
    // Semantic
    static let success = Color(hex: "34D399")
    static let warning = Color(hex: "FBBF24")
    static let danger = Color(hex: "F87171")
    static let info = Color(hex: "60A5FA")
    
    // Background
    static let bgPrimary = Color(hex: "0F0F23")
    static let bgSecondary = Color(hex: "1A1A3E")
    static let bgCard = Color(hex: "1E1E42")
    static let bgCardLight = Color(hex: "2A2A5E")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0C0")
    static let textTertiary = Color(hex: "6B6B8D")
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let tealGradient = LinearGradient(
        colors: [accentTeal, accentCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let coolGradient = LinearGradient(
        colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, bgSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.12),
            Color.white.opacity(0.04)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NKColors.glassGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Hex Color Extension

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

// MARK: - Module Type Helpers

struct ModuleTypeUI {
    let icon: String
    let gradient: LinearGradient
    let color: Color
    
    static func forType(_ type: String) -> ModuleTypeUI {
        switch type {
        case "article", "html_content":
            return ModuleTypeUI(
                icon: "doc.richtext.fill",
                gradient: NKColors.coolGradient,
                color: Color(hex: "8B5CF6")
            )
        case "video":
            return ModuleTypeUI(
                icon: "play.circle.fill",
                gradient: NKColors.warmGradient,
                color: Color(hex: "F97316")
            )
        case "exercise", "kegel_exercise":
            return ModuleTypeUI(
                icon: "figure.run",
                gradient: NKColors.tealGradient,
                color: NKColors.accentTeal
            )
        case "breathing", "breathing_exercise":
            return ModuleTypeUI(
                icon: "wind",
                gradient: LinearGradient(
                    colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "06B6D4")
            )
        case "quiz", "questionnaire", "question_answer":
            return ModuleTypeUI(
                icon: "list.clipboard.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "F59E0B")
            )
        case "checkin", "daily_checkin":
            return ModuleTypeUI(
                icon: "heart.text.clipboard.fill",
                gradient: NKColors.tealGradient,
                color: NKColors.accentTeal
            )
        case "timer":
            return ModuleTypeUI(
                icon: "timer",
                gradient: LinearGradient(
                    colors: [Color(hex: "7C3AED"), Color(hex: "A855F7")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "A855F7")
            )
        case "measurement", "measurement_input", "patient_measurements":
            return ModuleTypeUI(
                icon: "ruler.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "EC4899"), Color(hex: "BE185D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "EC4899")
            )
        case "file_pdf":
            return ModuleTypeUI(
                icon: "doc.fill",
                gradient: LinearGradient(
                    colors: [Color(hex: "DC2626"), Color(hex: "F97316")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                color: Color(hex: "DC2626")
            )
        case "consent":
            return ModuleTypeUI(
                icon: "signature",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        case "education_card":
            return ModuleTypeUI(
                icon: "lightbulb.fill",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        case "task":
            return ModuleTypeUI(
                icon: "checkmark.seal.fill",
                gradient: NKColors.tealGradient,
                color: NKColors.success
            )
        default:
            return ModuleTypeUI(
                icon: "square.grid.2x2.fill",
                gradient: NKColors.primaryGradient,
                color: NKColors.primaryGradientStart
            )
        }
    }

    static func localizedName(_ type: String) -> String {
        switch type {
        case "article", "html_content": return "Makale"
        case "video": return "Video"
        case "exercise", "kegel_exercise": return "Egzersiz"
        case "breathing", "breathing_exercise": return "Nefes Egzersizi"
        case "quiz", "questionnaire", "question_answer": return "Değerlendirme"
        case "checkin", "daily_checkin": return "Günlük Check-in"
        case "timer": return "Zamanlayıcı"
        case "measurement", "measurement_input", "patient_measurements": return "Ölçüm"
        case "file_pdf": return "PDF Rehber"
        case "consent": return "Onam"
        case "education_card": return "Bilgi Kartı"
        case "task": return "Görev"
        default: return "İçerik"
        }
    }
}

// MARK: - Animated Shimmer

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
