import SwiftUI

/// 出行方式选择视图
struct TravelModeSelectionView: View {
    @Binding var selectedMode: TravelMode
    var onNext: () -> Void
    var onSkip: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: "选择出行方式",
                showBackButton: true,
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 标题区域
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("您打算怎么出行？")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppColors.text)
                        
                        Text("选择出行方式以优化路线规划")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // 出行方式选项
                    VStack(spacing: Spacing.md) {
                        ForEach(TravelMode.allCases, id: \.self) { mode in
                            TravelModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode
                            ) {
                                selectedMode = mode
                                HapticFeedback.light()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // 底部按钮
            VStack(spacing: Spacing.sm) {
                Button("下一步") {
                    HapticFeedback.medium()
                    onNext()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("跳过，使用默认") {
                    HapticFeedback.light()
                    onSkip()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.95))
        }
        .background(AppColors.background)
    }
}

/// 出行方式卡片
struct TravelModeCard: View {
    let mode: TravelMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [AppColors.border, AppColors.border],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mode.iconName)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                // 文字
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppColors.text)
                    
                    Text(modeDescription(mode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.title2)
                }
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func modeDescription(_ mode: TravelMode) -> String {
        switch mode {
        case .walking:
            return "适合短距离，享受沿途风景"
        case .publicTransport:
            return "经济实惠，优化换乘路线"
        case .driving:
            return "灵活自由，考虑停车便利"
        }
    }
}

#Preview {
    TravelModeSelectionView(
        selectedMode: .constant(.driving),
        onNext: {},
        onSkip: {},
        onBack: {}
    )
}
