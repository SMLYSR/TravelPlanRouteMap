import SwiftUI

/// 计划详情视图 - 顶部地图 + 底部行程方案
struct PlanDetailView: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部地图区域
                DetailMapSection(plan: plan, onBack: onBack, onNewPlan: onNewPlan)
                
                // 行程方案区域
                DetailPlanSection(plan: plan)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.white)
    }
}

// MARK: - 地图区域

struct DetailMapSection: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // 地图
            MapViewWrapper(
                region: MapRegion(
                    center: plan.route.routePath.first ?? Coordinate(latitude: 39.9042, longitude: 116.4074),
                    span: MapSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
                ),
                attractions: plan.route.orderedAttractions,
                route: plan.route.routePath,
                accommodationZones: []
            )
            .frame(height: 280)
            
            // 浮动导航栏
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(plan.destination)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "374151"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                
                Spacer()
                
                Button(action: onNewPlan) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "3B82F6"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
        }
    }
}

// MARK: - 行程方案区域

struct DetailPlanSection: View {
    let plan: TravelPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 圆角顶部
            RoundedCornerTop()
            
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                DetailPlanHeader(plan: plan)
                
                // 行程描述
                PlanDescription(plan: plan)
                
                // 住宿推荐
                if !plan.accommodations.isEmpty {
                    AccommodationCard(zone: plan.accommodations.first!)
                }
                
                // 时间轴行程
                TimelineView(plan: plan)
                
                // 创建时间
                HStack {
                    Spacer()
                    Text("创建于 \(formatDate(plan.createdAt))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9CA3AF"))
                    Spacer()
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 标题区域

struct DetailPlanHeader: View {
    let plan: TravelPlan
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("您的行程方案")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1F2937"))
                
                HStack(spacing: 8) {
                    Text("\(plan.recommendedDays) 天")
                    Text("·")
                    Text("\(plan.route.attractionCount) 个景点")
                    Text("·")
                    Text(String(format: "%.1f km", plan.totalDistance))
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6B7280"))
            }
            
            Spacer()
        }
    }
}

#Preview {
    PlanDetailView(
        plan: TravelPlan(
            destination: "成都",
            route: OptimizedRoute(
                orderedAttractions: [
                    Attraction(name: "熊猫谷", coordinate: Coordinate(latitude: 31.0, longitude: 103.6), address: "成都市都江堰市"),
                    Attraction(name: "都江堰", coordinate: Coordinate(latitude: 30.9, longitude: 103.5), address: "成都市都江堰市"),
                    Attraction(name: "乐山大佛", coordinate: Coordinate(latitude: 29.5, longitude: 103.8), address: "乐山市市中区"),
                    Attraction(name: "宽窄巷子", coordinate: Coordinate(latitude: 30.6, longitude: 104.0), address: "成都市青羊区")
                ],
                routePath: [
                    Coordinate(latitude: 31.0, longitude: 103.6),
                    Coordinate(latitude: 30.9, longitude: 103.5),
                    Coordinate(latitude: 29.5, longitude: 103.8),
                    Coordinate(latitude: 30.6, longitude: 104.0)
                ]
            ),
            recommendedDays: 2,
            accommodations: [
                AccommodationZone(name: "成都南站/高新区", center: Coordinate(latitude: 30.6, longitude: 104.0), radius: 2000, dayNumber: 1)
            ],
            totalDistance: 119.6,
            travelMode: .driving
        ),
        onBack: {},
        onNewPlan: {}
    )
}
