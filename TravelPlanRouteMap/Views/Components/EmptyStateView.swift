import SwiftUI

/// 空状态视图组件
/// 用于显示空状态、错误状态和无结果状态
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
    /// 初始化空状态视图
    /// - Parameters:
    ///   - icon: SF Symbols 图标名称
    ///   - title: 主标题
    ///   - message: 描述文本
    ///   - actionTitle: 操作按钮文本（可选）
    ///   - onAction: 操作按钮回调（可选）
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondary)
                .accessibilityLabel(title)
            
            // 标题和描述
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // 可选操作按钮
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm + Spacing.xs)
                        .background(AppColors.primary)
                        .cornerRadius(24)
                }
                .accessibilityLabel(actionTitle)
                .accessibilityHint("点击\(actionTitle)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 预览

#Preview("错误状态") {
    EmptyStateView(
        icon: "wifi.slash",
        title: "加载失败",
        message: "无法加载位置信息，请检查网络连接",
        actionTitle: "重试",
        onAction: {
            print("重试按钮被点击")
        }
    )
}

#Preview("无结果状态") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "未找到结果",
        message: "请尝试其他关键词",
        actionTitle: nil,
        onAction: nil
    )
}

#Preview("空列表状态") {
    EmptyStateView(
        icon: "tray",
        title: "暂无旅行计划",
        message: "开始创建您的第一个旅行计划吧",
        actionTitle: "创建计划",
        onAction: {
            print("创建计划按钮被点击")
        }
    )
}

#Preview("网络错误状态") {
    EmptyStateView(
        icon: "exclamationmark.triangle",
        title: "服务暂时不可用",
        message: "位置服务暂时不可用，请稍后重试",
        actionTitle: "重新加载",
        onAction: {
            print("重新加载按钮被点击")
        }
    )
}

#Preview("在容器中") {
    VStack {
        Text("搜索结果")
            .font(.headline)
            .padding()
        
        EmptyStateView(
            icon: "magnifyingglass",
            title: "未找到结果",
            message: "请尝试其他关键词",
            actionTitle: nil,
            onAction: nil
        )
    }
}
