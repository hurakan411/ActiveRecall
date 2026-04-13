import SwiftUI

// MARK: - App Colors (要件定義 5.2 カラースキーム)
struct AppColors {
    /// ソフトデニム #64748B
    static let primary = Color(hex: "64748B")
    /// セージグリーン #869D7A
    static let secondary = Color(hex: "869D7A")
    /// ミスティグリーン #A7C4BC
    static let success = Color(hex: "A7C4BC")
    /// テラコッタ / サンド #E2A676
    static let warning = Color(hex: "E2A676")
    /// ウォームグレー #E5E7EB
    static let border = Color(hex: "E5E7EB")
    /// アイボリー #F9F8F6
    static let background = Color(hex: "F9F8F6")
    /// カード面 #FFFFFF
    static let surface = Color.white
    /// テキストメイン #334155
    static let textPrimary = Color(hex: "334155")
    /// テキストサブ #94A3B8
    static let textSecondary = Color(hex: "94A3B8")
    /// テキスト反転
    static let textOnPrimary = Color.white

    static func scoreColor(_ level: StudyLog.ScoreLevel) -> Color {
        switch level {
        case .excellent: return success
        case .good: return secondary
        case .fair: return warning
        case .needsWork: return primary
        }
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
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
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

// MARK: - View Modifiers (要件定義 5.3 UIコンポーネント)

/// ソフト・フラットカード: 白背景, 1ptボーダー, 16pt角丸
struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

/// ソフトボタン: 淡い面 + 濃い文字
struct SoftButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func softCard() -> some View {
        modifier(SoftCardModifier())
    }
}

// MARK: - Date Formatting
extension Date {
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }

    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
}
