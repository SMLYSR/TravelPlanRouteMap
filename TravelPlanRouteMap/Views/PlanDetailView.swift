import SwiftUI

/// 计划详情视图
struct PlanDetailView: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            CustomNavigationBar(
                title: plan.destination,
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
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 概览卡片
                    OverviewCard(plan: plan)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                    
                    // 地图占位
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
                    
                    // 创建时间
                    HStack {
                        Text("创建于")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(plan.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.md)
                    
                    Spacer(minLength: Spacing.xxl)
                }
            }
        }
        .background(AppColors.background)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    PlanDetailView(
        plan: TravelPlan(
            destination: "北京",
            route: OptimizedRoute(
                orderedAttractions: [
                    Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972), address: "北京市东城区"),
                    Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975), address: "北京市东城区")
                ],
                routePath: []
            ),
            recommendedDays: 2,
            accommodations: [
                AccommodationZone(name: "王府井商圈", center: Coordinate(latitude: 39.9, longitude: 116.4), radius: 2000, dayNumber: 1)
            ],
            totalDistance: 15.5,
            travelMode: .driving
        ),
        onBack: {},
        onNewPlan: {}
    )
}
