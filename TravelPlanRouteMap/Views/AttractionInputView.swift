import SwiftUI

/// 景点输入视图
struct AttractionInputView: View {
    @ObservedObject var viewModel: AttractionViewModel
    var onNext: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: "添加景点",
                showBackButton: true,
                onBack: onBack
            )
            
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
                        
                        // 错误提示
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, Spacing.sm)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    // 搜索结果列表
                    if viewModel.isSearching {
                        ProgressView()
                            .padding()
                    } else if !viewModel.searchResults.isEmpty {
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
                Button("开始规划") {
                    if let error = viewModel.validateAndGetError() {
                        viewModel.errorMessage = error
                        HapticFeedback.error()
                    } else {
                        HapticFeedback.medium()
                        onNext()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canProceed())
                .opacity(viewModel.canProceed() ? 1 : 0.5)
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.95))
        }
        .background(AppColors.background)
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
    AttractionInputView(
        viewModel: AttractionViewModel(destination: "北京"),
        onNext: {},
        onBack: {}
    )
}
