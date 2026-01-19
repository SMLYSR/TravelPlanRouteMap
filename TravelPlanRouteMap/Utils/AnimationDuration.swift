import Foundation

/// 动画时长标准
enum AnimationDuration {
    static let microInteraction: Double = 0.2       // 150-200ms：按钮按压、开关
    static let pageTransitionIn: Double = 0.3       // 300ms：页面进入
    static let pageTransitionOut: Double = 0.25     // 250ms：页面退出
    static let loading: Double = 1.0                // 1000ms：旋转加载器
    static let listItem: Double = 0.2               // 200ms：列表项动画
}
