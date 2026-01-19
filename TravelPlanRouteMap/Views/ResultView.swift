import SwiftUI

/// 结果展示视图
struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel
    let destination: String
    let attractions: [Attraction]
    let travelMode: TravelMode?
    var onBack: () -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: "规划结果",
                showBackButton: true,
                onBack: onBack,
                trailingContent: AnyView(
                    Button(action: onNewPlan) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
                    }
                )
            )
            
            if viewModel.isLoading {
                // 加载状态
                Spacer()
                LoadingView(message: "正在为您规划最优路线...")
                Spacer()
            } else if let error = viewModel.errorMessage {
                // 错误状态
                Spacer()
                ErrorView(message: error) {
                    viewModel.retry(
                        destination: destination,
                        attractions: attractions,
                        travelMode: travelMode
                    )
                }
                Spacer()
            } else if let plan = viewModel.travelPlan {
                // 结果展示
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // 概览卡片
                        OverviewCard(plan: plan)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                        
                        // 地图占位（实际应用中使用 MapViewWrapper）
                        MapPlaceholder(plan: plan)
                            .frame(height: 250)
                            .padding(.horizontal, Spacing.md)
                        
                        // 景点顺序
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("游览顺序")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                                .padding(.horizontal, Spacing.md)
                            
                            ForEach(Array(plan.route.orderedAttractions.enumerated()), id: \.element.id) { index, attraction in
                                AttractionCard(
                                    attraction: attraction,
                                    index: index + 1
                                )
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                        
                        // 住宿推荐
                        if !plan.accommodations.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("住宿推荐")
                                    .font(.headline)
                                    .foregroundColor(AppColors.text)
                                    .padding(.horizontal, Spacing.md)
                                
                                ForEach(plan.accommodations) { zone in
                                    AccommodationCard(zone: zone)
                                        .padding(.horizontal, Spacing.md)
                                }
                            }
                        }
                        
                        Spacer(minLength: Spacing.xxl)
                    }
                }
            } else {
                // 初始状态 - 开始规划
                Spacer()
                EmptyStateView(
                    icon: "map",
                    title: "准备就绪",
                    message: "点击下方按钮开始规划您的旅程",
                    actionTitle: "开始规划"
                ) {
                    Task {
                        await viewModel.planRoute(
                            destination: destination,
                            attractions: attractions,
                            travelMode: travelMode
                        )
                    }
                }
                Spacer()
            }
        }
        .background(AppColors.background)
        .onAppear {
            if viewModel.travelPlan == nil && !viewModel.isLoading {
                Task {
                    await viewModel.planRoute(
                        destination: destination,
                        attractions: attractions,
                        travelMode: travelMode
                    )
                }
            }
        }
    }
}

/// 概览卡片
struct OverviewCard: View {
    let plan: TravelPlan
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.destination)
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppColors.text)
                    
                    if let mode = plan.travelMode {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: mode.iconName)
                            Text(mode.displayName)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundColor(AppColors.primary)
            }
            
            Divider()
            
            HStack(spacing: Spacing.lg) {
                StatItem(
                    icon: "calendar",
                    value: "\(plan.recommendedDays)",
                    label: "推荐天数"
                )
                
                StatItem(
                    icon: "mappin.and.ellipse",
                    value: "\(plan.route.attractionCount)",
                    label: "景点数量"
                )
                
                StatItem(
                    icon: "arrow.triangle.swap",
                    value: String(format: "%.1f", plan.totalDistance),
                    label: "总距离(km)"
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

/// 统计项
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.text)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 住宿卡片
struct AccommodationCard: View {
    let zone: AccommodationZone
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bed.double.fill")
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("第\(zone.dayNumber)天住宿")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(zone.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppColors.text)
                
                Text("推荐范围：\(Int(zone.radius))米内")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

/// 地图占位视图
struct MapPlaceholder: View {
    let plan: TravelPlan
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.1), AppColors.secondary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 内容
            VStack(spacing: Spacing.md) {
                Image(systemName: "map.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
                
                Text("地图视图")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Text("集成高德地图后显示完整路线")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    ResultView(
        viewModel: ResultViewModel(),
        destination: "北京",
        attractions: [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ],
        travelMode: .driving,
        onBack: {},
        onNewPlan: {}
    )
}
