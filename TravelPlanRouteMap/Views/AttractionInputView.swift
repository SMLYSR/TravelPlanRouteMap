import SwiftUI

/// 景点输入视图
struct AttractionInputView: View {
    @ObservedObject var viewModel: AttractionViewModel
    var editMode: Bool = false
    var onNext: (() -> Void)?
    var onBack: (() -> Void)?
    var onComplete: (([Attraction]) -> Void)?
    
    @State private var showCancelAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏（非编辑模式）
            if !editMode {
                CustomNavigationBar(
                    title: "添加景点",
                    showBackButton: true,
                    onBack: onBack ?? {}
                )
            }
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 标题区域
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("想去哪些景点？")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppColors.text)
                        
                        Text("添加2-10个景点，我们将为您规划最优路线")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // 搜索输入框
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        CustomTextField(
                            text: $viewModel.currentInput,
                            placeholder: "搜索景点名称",
                            icon: "magnifyingglass"
                        ) {
                            viewModel.searchAttractions()
                        }
                        .onChange(of: viewModel.currentInput) { _, newValue in
                            if newValue.count >= 2 {
                                viewModel.searchAttractions()
                            }
                        }
                        
                        // 景点数量提示
                        HStack {
                            Text("已添加 \(viewModel.attractions.count)/\(viewModel.maxAttractions) 个景点")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if viewModel.attractions.count < viewModel.minAttractions {
                                Text("至少需要\(viewModel.minAttractions)个")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
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
                                viewModel.searchAttractions()
                            }
                        )
                        .padding(.top, Spacing.xl)
                    } else if !viewModel.searchResults.isEmpty {
                        // 搜索结果列表
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.searchResults) { result in
                                POIResultRow(result: result) {
                                    viewModel.selectAttraction(result)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // 已添加的景点列表
                    if !viewModel.attractions.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("已添加的景点")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.md)
                            
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(Array(viewModel.attractions.enumerated()), id: \.element.id) { index, attraction in
                                    AttractionCard(
                                        attraction: attraction,
                                        index: index + 1,
                                        onDelete: {
                                            viewModel.removeAttraction(attraction)
                                        }
                                    )
                                    .padding(.horizontal, Spacing.md)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // 底部按钮
            VStack {
                if editMode {
                    // 编辑模式：完成按钮
                    Button("完成") {
                        if let error = viewModel.validateAndGetError() {
                            viewModel.errorMessage = error
                            HapticFeedback.error()
                        } else {
                            HapticFeedback.medium()
                            onComplete?(viewModel.attractions)
                            dismiss()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.canProceed())
                    .opacity(viewModel.canProceed() ? 1 : 0.5)
                } else {
                    // 普通模式：开始规划按钮
                    Button("开始规划") {
                        if let error = viewModel.validateAndGetError() {
                            viewModel.errorMessage = error
                            HapticFeedback.error()
                        } else {
                            HapticFeedback.medium()
                            onNext?()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.canProceed())
                    .opacity(viewModel.canProceed() ? 1 : 0.5)
                }
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.95))
        }
        .background(AppColors.background)
        // 编辑模式：使用 NavigationView 和工具栏
        .if(editMode) { view in
            view
                .navigationTitle("编辑景点")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showCancelAlert = true
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
                .alert("放弃编辑的更改吗？", isPresented: $showCancelAlert) {
                    Button("继续编辑", role: .cancel) { }
                    Button("放弃", role: .destructive) {
                        dismiss()
                    }
                }
        }
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// POI搜索结果行
struct POIResultRow: View {
    let result: POIResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
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
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppColors.primary)
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        AttractionInputView(
            viewModel: AttractionViewModel(destination: "北京"),
            editMode: false,
            onNext: {},
            onBack: {}
        )
    }
}

#Preview("编辑模式") {
    NavigationView {
        AttractionInputView(
            viewModel: AttractionViewModel(
                destination: "北京",
                preselectedAttractions: [
                    Attraction(name: "故宫", coordinate: .init(latitude: 39.9163, longitude: 116.3972), address: "北京市东城区"),
                    Attraction(name: "天安门", coordinate: .init(latitude: 39.9075, longitude: 116.3972), address: "北京市东城区")
                ]
            ),
            editMode: true,
            onComplete: { attractions in
                print("完成编辑，景点数量：\(attractions.count)")
            }
        )
    }
}
