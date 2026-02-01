import SwiftUI

/// 统一的加载指示器组件
/// 支持全屏、遮罩和内联三种显示样式
struct LoadingIndicator: View {
    let message: String
    var style: LoadingStyle = .inline
    
    @State private var showExtraMessage = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    /// Loading 显示样式
    enum LoadingStyle {
        case fullScreen      // 全屏遮罩
        case overlay         // 半透明遮罩
        case inline          // 内联显示
    }
    
    var body: some View {
        Group {
            switch style {
            case .fullScreen:
                fullScreenLoading
            case .overlay:
                overlayLoading
            case .inline:
                inlineLoading
            }
        }
        .onAppear {
            // 3秒后显示额外提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showExtraMessage = true
                }
            }
        }
    }
    
    // MARK: - 全屏Loading
    private var fullScreenLoading: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                progressView
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.text)
                
                if showExtraMessage {
                    Text("正在处理，请稍候...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
        }
        .accessibilityLabel("\(message)，请稍候")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - 半透明遮罩Loading
    private var overlayLoading: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                progressView
                    .tint(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if showExtraMessage {
                    Text("正在处理，请稍候...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .transition(.opacity)
                }
            }
            .padding(Spacing.lg)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
        .accessibilityLabel("\(message)，请稍候")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - 内联Loading
    private var inlineLoading: some View {
        HStack(spacing: Spacing.sm + Spacing.xs) {
            progressView
                .scaleEffect(0.8)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.sm + Spacing.xs)
        .accessibilityLabel(message)
    }
    
    // MARK: - 进度视图（支持辅助功能）
    private var progressView: some View {
        Group {
            if reduceMotion {
                // 静态加载指示器（减少动态效果模式）
                Image(systemName: "hourglass")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
                    .accessibilityLabel("加载中")
            } else {
                // 动画加载指示器
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColors.primary)
                    .accessibilityLabel("加载中")
            }
        }
    }
}

// MARK: - 预览

#Preview("全屏") {
    LoadingIndicator(message: "正在规划路线...", style: .fullScreen)
}

#Preview("遮罩") {
    ZStack {
        // 模拟背景内容
        Color.gray.ignoresSafeArea()
        
        VStack {
            Text("背景内容")
                .font(.title)
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 200)
        }
        
        LoadingIndicator(message: "正在重新规划...", style: .overlay)
    }
}

#Preview("内联") {
    VStack(spacing: Spacing.lg) {
        Text("搜索结果")
            .font(.headline)
        
        LoadingIndicator(message: "搜索中...", style: .inline)
        
        Spacer()
    }
    .padding()
}

#Preview("减少动态效果") {
    LoadingIndicator(message: "正在加载...", style: .fullScreen)
}
