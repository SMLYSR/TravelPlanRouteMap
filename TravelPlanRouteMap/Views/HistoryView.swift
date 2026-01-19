import SwiftUI

/// 历史记录视图
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    var onSelectPlan: (TravelPlan) -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: "我的旅行",
                showBackButton: false,
                trailingContent: AnyView(
                    Button(action: onNewPlan) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
                    }
                )
            )
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.plans.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "map",
                    title: "暂无规划记录",
                    message: "开始创建您的第一个旅行计划吧",
                    actionTitle: "创建计划",
                    onAction: onNewPlan
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.plans) { plan in
                            HistoryPlanCard(plan: plan, viewModel: viewModel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .onTapGesture {
                                    HapticFeedback.light()
                                    onSelectPlan(plan)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if let index = viewModel.plans.firstIndex(where: { $0.id == plan.id }) {
                                            viewModel.deletePlan(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .background(AppColors.background)
            }
        }
        .background(AppColors.background)
        .onAppear {
            viewModel.loadPlans()
        }
    }
}

/// 历史计划卡片
struct HistoryPlanCard: View {
    let plan: TravelPlan
    let viewModel: HistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.destination)
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text(viewModel.formatDate(plan.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let mode = plan.travelMode {
                    Image(systemName: mode.iconName)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            Divider()
            
            HStack(spacing: Spacing.lg) {
                Label("\(plan.route.attractionCount)个景点", systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(plan.recommendedDays)天", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(String(format: "%.1fkm", plan.totalDistance), systemImage: "arrow.triangle.swap")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    HistoryView(
        onSelectPlan: { _ in },
        onNewPlan: {}
    )
}
