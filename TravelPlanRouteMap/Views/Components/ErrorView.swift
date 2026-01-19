import SwiftUI

/// 错误视图组件
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "F97316"))
            
            Text(message)
                .font(.body)
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                HapticFeedback.light()
                onRetry()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 200)
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    ErrorView(message: "网络连接失败，请检查网络设置") {
        print("重试")
    }
}
