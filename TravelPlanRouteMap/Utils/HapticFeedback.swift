import UIKit

/// 触觉反馈工具类
enum HapticFeedback {
    /// 轻触觉反馈 - 用于按钮点击、选择项
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// 中等触觉反馈 - 用于重要操作确认
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// 成功触觉反馈 - 用于路线规划完成
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// 错误触觉反馈 - 用于输入错误、操作失败
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    /// 警告触觉反馈
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
