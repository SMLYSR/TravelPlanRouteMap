import SwiftUI

/// 计划详情视图 - 全屏地图 + 可收起底部面板
struct PlanDetailView: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onNewPlan: () -> Void
    var onDelete: (() -> Void)?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // 主内容
            DetailContentView(
                plan: plan,
                onBack: onBack,
                onNewPlan: onNewPlan,
                onDelete: onDelete != nil ? { showDeleteAlert = true } : nil
            )
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("确定要删除「\(plan.destination)」的旅行计划吗？此操作无法撤销。")
        }
    }
}

// MARK: - 主内容视图

struct DetailContentView: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onNewPlan: () -> Void
    var onDelete: (() -> Void)?
    
    // 面板展开/收起状态
    @State private var isExpanded: Bool = true
    // 选中的景点（用于地图聚焦）
    @State private var selectedAttraction: Attraction? = nil
    // 选中的住宿区域（用于地图聚焦）
    @State private var selectedAccommodationZone: AccommodationZone? = nil
    
    // 面板高度 - 使用固定值避免 GeometryReader
    private let collapsedHeight: CGFloat = 90
    private let expandedHeight: CGFloat = UIScreen.main.bounds.height - 180
    
    var body: some View {
        ZStack {
            // 全屏地图
            DetailFullScreenMapView(
                plan: plan,
                selectedAttraction: selectedAttraction,
                selectedAccommodationZone: selectedAccommodationZone,
                onBack: onBack,
                onNewPlan: onNewPlan,
                onDelete: onDelete
            )
            
            // 可展开/收起的底部面板
            VStack(spacing: 0) {
                Spacer()
                
                DetailCollapsibleSheet(
                    plan: plan,
                    isExpanded: $isExpanded,
                    selectedAttraction: $selectedAttraction,
                    selectedAccommodationZone: $selectedAccommodationZone,
                    collapsedHeight: collapsedHeight,
                    expandedHeight: expandedHeight
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - 全屏地图视图

struct DetailFullScreenMapView: View {
    let plan: TravelPlan
    var selectedAttraction: Attraction? = nil
    var selectedAccommodationZone: AccommodationZone? = nil
    var onBack: () -> Void
    var onNewPlan: () -> Void
    var onDelete: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .top) {
            // 全屏地图
            MapViewWrapper(
                region: MapRegion(
                    center: plan.route.routePath.first ?? Coordinate(latitude: 39.9042, longitude: 116.4074),
                    span: MapSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
                ),
                attractions: plan.route.orderedAttractions,
                route: plan.route.routePath,
                accommodationZones: plan.accommodations,
                selectedAttraction: selectedAttraction,
                selectedAccommodationZone: selectedAccommodationZone
            )
            .ignoresSafeArea()
            
            // 浮动导航栏
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "374151"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // 删除按钮
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "EF4444"))
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                        }
                    }
                    
                    // 新建按钮
                    Button(action: onNewPlan) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 54)
        }
    }
}

// MARK: - 可折叠底部面板

struct DetailCollapsibleSheet: View {
    let plan: TravelPlan
    @Binding var isExpanded: Bool
    @Binding var selectedAttraction: Attraction?
    @Binding var selectedAccommodationZone: AccommodationZone?
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏（横杠 + 标题 + 箭头按钮）
            DetailSheetControlBar(plan: plan, isExpanded: $isExpanded)
            
            // 内容区域（展开时显示）
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 行程描述
                        PlanDescription(plan: plan)
                        
                        // 住宿推荐
                        if !plan.accommodations.isEmpty {
                            AccommodationCard(zone: plan.accommodations.first!) {
                                // 点击住宿卡片时聚焦到该区域
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedAccommodationZone = plan.accommodations.first
                                    selectedAttraction = nil  // 取消景点选中
                                }
                            }
                        }
                        
                        // 时间轴行程
                        TimelineView(
                            plan: plan,
                            selectedAttraction: $selectedAttraction,
                            selectedAccommodationZone: $selectedAccommodationZone
                        )
                        
                        // 创建时间
                        HStack {
                            Spacer()
                            Text("创建于 \(formatDate(plan.createdAt))")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "9CA3AF"))
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(height: isExpanded ? expandedHeight : collapsedHeight)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 面板控制栏

struct DetailSheetControlBar: View {
    let plan: TravelPlan
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 可点击的横杠
            Button(action: {
                isExpanded.toggle()
            }) {
                Capsule()
                    .fill(Color(hex: "D1D5DB"))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 标题行 + 箭头按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.destination)
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
                
                // 展开/收起箭头按钮
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "6B7280"))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "F3F4F6"))
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
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
