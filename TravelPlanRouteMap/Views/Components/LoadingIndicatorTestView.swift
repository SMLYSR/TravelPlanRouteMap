import SwiftUI

/// LoadingIndicator 组件测试视图
/// 用于手动测试三种样式和辅助功能支持
struct LoadingIndicatorTestView: View {
    @State private var selectedStyle: LoadingIndicator.LoadingStyle = .inline
    @State private var showLoading = true
    @State private var reduceMotion = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                // 样式选择器
                Picker("Loading 样式", selection: $selectedStyle) {
                    Text("内联").tag(LoadingIndicator.LoadingStyle.inline)
                    Text("全屏").tag(LoadingIndicator.LoadingStyle.fullScreen)
                    Text("遮罩").tag(LoadingIndicator.LoadingStyle.overlay)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 控制开关
                Toggle("显示 Loading", isOn: $showLoading)
                    .padding(.horizontal)
                
                Toggle("减少动态效果", isOn: $reduceMotion)
                    .padding(.horizontal)
                
                Divider()
                
                // 预览区域
                ZStack {
                    // 背景内容
                    VStack(spacing: Spacing.md) {
                        Text("背景内容区域")
                            .font(.headline)
                        
                        Rectangle()
                            .fill(AppColors.primary.opacity(0.2))
                            .frame(height: 150)
                            .cornerRadius(12)
                        
                        Text("这是一些示例文本，用于展示遮罩效果")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Loading 指示器
                    if showLoading {
                        LoadingIndicator(
                            message: "正在加载数据...",
                            style: selectedStyle
                        )
                    }
                }
                
                Spacer()
                
                // 说明文本
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("测试说明：")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("• 切换样式查看不同的 Loading 效果")
                        .font(.caption)
                    Text("• 开启「减少动态效果」查看静态图标")
                        .font(.caption)
                    Text("• 等待 3 秒查看额外提示信息")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding()
                .background(AppColors.background)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .navigationTitle("LoadingIndicator 测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LoadingIndicatorTestView()
}
