import SwiftUI

/// 空状态视图组件
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.6))
            
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppColors.text)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(actionTitle) {
                    HapticFeedback.light()
                    onAction()
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    EmptyStateView(
        icon: "map",
        title: "暂无规划记录",
        message: "开始创建您的第一个旅行计划吧",
        actionTitle: "创建计划",
        onAction: {}
    )
}
