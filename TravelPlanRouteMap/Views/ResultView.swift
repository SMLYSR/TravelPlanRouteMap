import SwiftUI

/// 结果展示视图 - 全屏地图 + 可拖拽底部面板
struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel
    let destination: String
    let citycode: String?  // 城市代码,用于公交路线规划
    let attractions: [Attraction]
    let travelMode: TravelMode?
    var onBack: () -> Void
    var onNewPlan: () -> Void
    
    var body: some View {
        ZStack {
            // 背景色
            Color.white.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingOverlay(message: "AI 正在规划最优路线...")
            } else if let error = viewModel.errorMessage {
                ErrorOverlay(message: error) {
                    viewModel.retry(
                        destination: destination,
                        citycode: citycode,
                        attractions: attractions,
                        travelMode: travelMode
                    )
                }
            } else if let plan = viewModel.travelPlan {
                // 主内容
                TravelPlanContentView(
                    plan: plan,
                    navigationPath: viewModel.navigationPath,
                    isSaved: viewModel.isSaved,  // 新增：传递保存状态
                    onBack: onBack,
                    onRefresh: {
                        Task {
                            await viewModel.planRoute(
                                destination: destination,
                                citycode: citycode,
                                attractions: attractions,
                                travelMode: travelMode
                            )
                        }
                    }
                )
            }
        }
        .onAppear {
            if viewModel.travelPlan == nil && !viewModel.isLoading {
                Task {
                    await viewModel.planRoute(
                        destination: destination,
                        citycode: citycode,
                        attractions: attractions,
                        travelMode: travelMode
                    )
                }
            }
        }
    }
}

// MARK: - 主内容视图

struct TravelPlanContentView: View {
    let plan: TravelPlan
    /// 导航路径（用于显示实际道路路线）
    /// 需求: 3.4, 6.3
    var navigationPath: NavigationPath? = nil
    var isSaved: Bool = false  // 新增：保存状态
    var onBack: () -> Void
    var onRefresh: () -> Void
    
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
            FullScreenMapView(
                plan: plan,
                navigationPath: navigationPath,
                selectedAttraction: selectedAttraction,
                selectedAccommodationZone: selectedAccommodationZone,
                isSaved: isSaved,  // 新增：传递保存状态
                onBack: onBack,
                onRefresh: onRefresh
            )
            
            // 可展开/收起的底部面板
            VStack(spacing: 0) {
                Spacer()
                
                CollapsibleSheet(
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

// MARK: - 地图区域

struct MapSection: View {
    let plan: TravelPlan
    var onBack: () -> Void
    var onRefresh: () -> Void
    
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
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("AI 智游")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "3B82F6"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "374151"))
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

struct PlanSection: View {
    let plan: TravelPlan
    @State private var selectedAttraction: Attraction? = nil
    @State private var selectedAccommodationZone: AccommodationZone? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 圆角顶部
            RoundedCornerTop()
            
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                PlanHeader(plan: plan)
                
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
    }
}

// MARK: - 圆角顶部

struct RoundedCornerTop: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(height: 24)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .offset(y: -12)
    }
}

// MARK: - 标题区域

struct PlanHeader: View {
    let plan: TravelPlan
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("您的行程方案")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text("\(plan.recommendedDays) 天 · \(plan.route.attractionCount) 个景点")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "9CA3AF"))
        }
    }
}

// MARK: - 行程描述

struct PlanDescription: View {
    let plan: TravelPlan
    
    var body: some View {
        Text("该区域位于\(plan.destination)中心，拥有大量高品质商务及舒适型酒店，符合Comfort偏好。自驾前往各景点均有便捷的高速入口连接，且方便游玩市内的宽窄巷子。")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "6B7280"))
            .lineSpacing(6)
    }
}

// MARK: - 住宿推荐卡片

struct AccommodationCard: View {
    let zone: AccommodationZone
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(zone.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("优选")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "3B82F6"))
                        
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "EFF6FF"))
                    .cornerRadius(4)
                }
                
                Text("考虑到自驾前往各景点的行程，周边的酒店设施更新更舒适，商务氛围浓厚。此区域停车方便，更贴合自驾用户的舒适住宿需求。")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6B7280"))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(Color(hex: "F9FAFB"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 时间轴视图

struct TimelineView: View {
    let plan: TravelPlan
    @Binding var selectedAttraction: Attraction?
    @Binding var selectedAccommodationZone: AccommodationZone?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(groupAttractionsByDay(), id: \.day) { dayGroup in
                DayTimelineView(
                    day: dayGroup.day,
                    title: dayGroup.title,
                    attractions: dayGroup.attractions,
                    isLastDay: dayGroup.day == plan.recommendedDays,
                    selectedAttraction: $selectedAttraction,
                    selectedAccommodationZone: $selectedAccommodationZone
                )
            }
        }
    }
    
    private func groupAttractionsByDay() -> [DayGroup] {
        let attractionsPerDay = max(1, plan.route.orderedAttractions.count / plan.recommendedDays)
        var groups: [DayGroup] = []
        
        for day in 1...plan.recommendedDays {
            let startIndex = (day - 1) * attractionsPerDay
            let endIndex = day == plan.recommendedDays 
                ? plan.route.orderedAttractions.count 
                : min(day * attractionsPerDay, plan.route.orderedAttractions.count)
            
            if startIndex < plan.route.orderedAttractions.count {
                let dayAttractions = Array(plan.route.orderedAttractions[startIndex..<endIndex])
                let title = generateDayTitle(for: dayAttractions, day: day)
                groups.append(DayGroup(day: day, title: title, attractions: dayAttractions))
            }
        }
        
        return groups
    }
    
    private func generateDayTitle(for attractions: [Attraction], day: Int) -> String {
        if attractions.isEmpty { return "自由活动" }
        if day == 1 {
            return "川西自然与水利文化之旅"
        } else {
            return "乐山人文与成都市井体验"
        }
    }
}

struct DayGroup {
    let day: Int
    let title: String
    let attractions: [Attraction]
}

// MARK: - 单日时间轴

struct DayTimelineView: View {
    let day: Int
    let title: String
    let attractions: [Attraction]
    let isLastDay: Bool
    @Binding var selectedAttraction: Attraction?
    @Binding var selectedAccommodationZone: AccommodationZone?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day 标签和标题
            HStack(spacing: 12) {
                Text("Day \(day)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "1E3A5F"))
                    .cornerRadius(14)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
            }
            .padding(.top, 8)
            
            // 景点列表
            VStack(spacing: 0) {
                ForEach(Array(attractions.enumerated()), id: \.element.id) { index, attraction in
                    AttractionTimelineRow(
                        attraction: attraction,
                        isLast: index == attractions.count - 1 && isLastDay,
                        isSelected: selectedAttraction?.id == attraction.id,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedAttraction?.id == attraction.id {
                                    selectedAttraction = nil  // 取消选中
                                } else {
                                    selectedAttraction = attraction  // 选中
                                    selectedAccommodationZone = nil  // 清除住宿区域选中
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(.bottom, isLastDay ? 0 : 8)
    }
}

// MARK: - 景点时间轴行

struct AttractionTimelineRow: View {
    let attraction: Attraction
    let isLast: Bool
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    // 根据景点类型估算游玩时间
    var estimatedDuration: String {
        let name = attraction.name
        if name.contains("山") || name.contains("峰") {
            return "4小时"
        } else if name.contains("寺") || name.contains("庙") || name.contains("塔") {
            return "2小时"
        } else if name.contains("博物") || name.contains("纪念") {
            return "2.5小时"
        } else if name.contains("公园") || name.contains("湖") {
            return "3小时"
        } else if name.contains("街") || name.contains("巷") || name.contains("古镇") {
            return "2.5小时"
        } else {
            return "3小时"
        }
    }
    
    // 生成景点描述
    var attractionDescription: String {
        let name = attraction.name
        if name.contains("熊猫") {
            return "建议早晨入园，此时大熊猫最为活跃，且避开午后高温。"
        } else if name.contains("都江堰") {
            return "午后游览这一世界文化遗产，领略宏大的治水工程，地理位置距离熊猫谷极近。"
        } else if name.contains("乐山") || name.contains("大佛") {
            return "早晨驾车南下前往乐山，参观摩崖石刻造像，体验壮丽的人文景观。"
        } else if name.contains("宽窄") || name.contains("巷子") {
            return "返回成都市区后游览，适合傍晚散步并体验川西特色建筑与市井文化。"
        } else {
            return "游览\(name)，感受当地独特的自然风光与人文魅力。"
        }
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(alignment: .top, spacing: 16) {
                // 左侧时间轴
                VStack(spacing: 0) {
                    // 蓝色圆点（选中时放大）
                    Circle()
                        .fill(Color(hex: "3B82F6"))
                        .frame(width: isSelected ? 14 : 10, height: isSelected ? 14 : 10)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "3B82F6").opacity(0.3), lineWidth: isSelected ? 4 : 0)
                        )
                    
                    // 连接线
                    if !isLast {
                        Rectangle()
                            .fill(Color(hex: "E5E7EB"))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 14)
                .padding(.leading, 6)
                
                // 右侧内容
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(attraction.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? Color(hex: "3B82F6") : Color(hex: "1F2937"))
                        
                        Spacer()
                        
                        // 游玩时间标签
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(estimatedDuration)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "3B82F6"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "EFF6FF"))
                        .cornerRadius(12)
                    }
                    
                    Text(attractionDescription)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6B7280"))
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(isSelected ? Color(hex: "F0F9FF") : Color.clear)
                .cornerRadius(12)
                .padding(.bottom, isLast ? 0 : 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 圆角扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 全屏地图视图

struct FullScreenMapView: View {
    let plan: TravelPlan
    /// 导航路径（用于显示实际道路路线）
    /// 需求: 3.4, 6.3
    var navigationPath: NavigationPath? = nil
    var selectedAttraction: Attraction? = nil
    var selectedAccommodationZone: AccommodationZone? = nil
    var isSaved: Bool = false  // 新增：保存状态
    var onBack: () -> Void
    var onRefresh: () -> Void
    
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
                selectedAccommodationZone: selectedAccommodationZone,
                navigationPath: navigationPath
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
                
                // 新增：保存状态指示器
                if isSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("已保存")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "374151"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 54)
        }
    }
}

// MARK: - 可拖拽底部面板（保留但不使用）

// MARK: - 可折叠底部面板

struct CollapsibleSheet: View {
    let plan: TravelPlan
    @Binding var isExpanded: Bool
    @Binding var selectedAttraction: Attraction?
    @Binding var selectedAccommodationZone: AccommodationZone?
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    
    // 拖动状态
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    // 计算当前高度
    private var currentHeight: CGFloat {
        let baseHeight = isExpanded ? expandedHeight : collapsedHeight
        return max(collapsedHeight, min(expandedHeight, baseHeight - dragOffset))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏（横杠 + 标题 + 箭头按钮）
            SheetControlBar(
                plan: plan,
                isExpanded: $isExpanded,
                onDragChanged: handleDragChanged,
                onDragEnded: handleDragEnded
            )
            
            // 内容区域（展开时显示）
            if isExpanded || dragOffset < 0 {
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .opacity(currentHeight > collapsedHeight + 50 ? 1 : 0)
            }
        }
        .frame(height: currentHeight)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // 处理拖动变化
    private func handleDragChanged(_ value: CGFloat) {
        dragOffset = value
    }
    
    // 处理拖动结束
    private func handleDragEnded(_ value: CGFloat) {
        let velocity = value - lastDragValue
        lastDragValue = value
        
        // 根据拖动距离和速度决定展开或收起
        let threshold = (expandedHeight - collapsedHeight) / 3
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if isExpanded {
                // 当前是展开状态
                if dragOffset > threshold || velocity > 5 {
                    // 向下拖动超过阈值或速度够快，收起
                    isExpanded = false
                }
            } else {
                // 当前是收起状态
                if dragOffset < -threshold || velocity < -5 {
                    // 向上拖动超过阈值或速度够快，展开
                    isExpanded = true
                }
            }
            
            // 重置拖动偏移
            dragOffset = 0
        }
    }
}

// MARK: - 面板控制栏

struct SheetControlBar: View {
    let plan: TravelPlan
    @Binding var isExpanded: Bool
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: ((CGFloat) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // 可拖动的横杠区域
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(hex: "D1D5DB"))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDragChanged?(value.translation.height)
                    }
                    .onEnded { value in
                        onDragEnded?(value.translation.height)
                    }
            )
            
            // 标题行 + 箭头按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("您的行程方案")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Text("\(plan.recommendedDays) 天 · \(plan.route.attractionCount) 个景点")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6B7280"))
                }
                
                Spacer()
                
                // 展开/收起箭头按钮
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
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

// MARK: - 面板标题（保留兼容）

struct SheetHeader: View {
    let plan: TravelPlan
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("您的行程方案")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text("\(plan.recommendedDays) 天 · \(plan.route.attractionCount) 个景点")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - 加载覆盖层

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(Color(hex: "3B82F6"))
                
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "6B7280"))
            }
        }
    }
}

// MARK: - 错误覆盖层

struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: onRetry) {
                    Text("重试")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color(hex: "3B82F6"))
                        .cornerRadius(24)
                }
            }
        }
    }
}

#Preview {
    ResultView(
        viewModel: ResultViewModel(),
        destination: "成都",
        citycode: "028",  // 成都城市代码
        attractions: [
            Attraction(name: "熊猫谷", coordinate: Coordinate(latitude: 31.0, longitude: 103.6)),
            Attraction(name: "都江堰", coordinate: Coordinate(latitude: 30.9, longitude: 103.5)),
            Attraction(name: "乐山大佛", coordinate: Coordinate(latitude: 29.5, longitude: 103.8)),
            Attraction(name: "宽窄巷子", coordinate: Coordinate(latitude: 30.6, longitude: 104.0))
        ],
        travelMode: .driving,
        onBack: {},
        onNewPlan: {}
    )
}
