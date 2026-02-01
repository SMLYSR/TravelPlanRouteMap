import SwiftUI

/// 目的地输入视图
struct DestinationInputView: View {
    @StateObject private var viewModel = DestinationViewModel()
    @Binding var selectedDestination: GeocodingResult?
    var onNext: () -> Void
    var onBack: () -> Void  // 新增：返回回调
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: "选择目的地",
                showBackButton: true,  // 改为 true
                onBack: onBack  // 使用新增的回调
            )
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 标题区域
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("您想去哪里？")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppColors.text)
                        
                        Text("输入城市名称开始规划您的旅程")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // 搜索输入框
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        CustomTextField(
                            text: $viewModel.destination,
                            placeholder: "请输入目的地城市",
                            icon: "magnifyingglass"
                        ) {
                            viewModel.searchDestination()
                        }
                        .onChange(of: viewModel.destination) { _, newValue in
                            if newValue.count >= 2 {
                                viewModel.searchDestination()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // 根据状态显示不同内容
                    if viewModel.isSearching {
                        // Loading 状态 - 使用内联加载指示器
                        LoadingIndicator(message: "搜索中...", style: .inline)
                            .padding(.top, Spacing.md)
                    } else if let error = viewModel.errorMessage {
                        // 错误状态 - 使用空状态视图
                        EmptyStateView(
                            icon: "wifi.slash",
                            title: "加载失败",
                            message: error,
                            actionTitle: "重试",
                            onAction: {
                                viewModel.searchDestination()
                            }
                        )
                        .padding(.top, Spacing.xl)
                    } else if viewModel.searchResults.isEmpty && !viewModel.destination.trimmingCharacters(in: .whitespaces).isEmpty {
                        // 无结果状态 - 使用空状态视图
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "未找到结果",
                            message: "请尝试其他关键词",
                            actionTitle: nil,
                            onAction: nil
                        )
                        .padding(.top, Spacing.xl)
                    } else if !viewModel.searchResults.isEmpty {
                        // 搜索结果列表
                        VStack(spacing: Spacing.sm) {
                            ForEach(viewModel.searchResults) { result in
                                SearchResultRow(result: result) {
                                    viewModel.selectDestination(result)
                                    selectedDestination = result
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // 已选择的目的地
                    if let selected = viewModel.selectedDestination {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("已选择")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(AppColors.text)
                                    
                                    Text(selected.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.clearSelection()
                                    selectedDestination = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(Spacing.md)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // 底部按钮
            VStack {
                Button("下一步") {
                    HapticFeedback.medium()
                    onNext()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isValid)
                .opacity(viewModel.isValid ? 1 : 0.5)
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.95))
        }
        .background(AppColors.background)
    }
}

/// 搜索结果行
struct SearchResultRow: View {
    let result: GeocodingResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "mappin")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.body)
                        .foregroundColor(AppColors.text)
                    
                    Text(result.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DestinationInputView(
        selectedDestination: .constant(nil),
        onNext: {
            print("Next")
        },
        onBack: {
            print("Back")
        }
    )
}
