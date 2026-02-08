import SwiftUI
import UIKit

/// 应用颜色系统
enum AppColors {
    // 主色系
    static let primary = Color(hex: "06B6D4")      // 天空蓝 - 主要按钮、强调元素
    static let secondary = Color(hex: "0EA5E9")    // 浅蓝 - 次要按钮、链接
    static let accent = Color(hex: "EC4899")       // 粉红 - CTA按钮、住宿区域
    
    // 背景和文本
    static let background = Color(hex: "FDF2F8")   // 柔和粉白 - 主背景
    static let text = Color(hex: "1E293B")         // 深灰蓝 - 主要文本
    static let textSecondary = Color(hex: "6B7280") // 灰色 - 次要文本
    static let border = Color(hex: "E2E8F0")       // 浅灰 - 边框、分隔线
    
    // UIColor 版本（用于 UIKit 组件）
    static let primaryUI = UIColor(hex: "06B6D4")
    static let secondaryUI = UIColor(hex: "0EA5E9")
    static let accentUI = UIColor(hex: "EC4899")
    static let backgroundUI = UIColor(hex: "FDF2F8")
    static let textUI = UIColor(hex: "1E293B")
    static let textSecondaryUI = UIColor(hex: "6B7280")
    static let borderUI = UIColor(hex: "E2E8F0")
}

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

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
