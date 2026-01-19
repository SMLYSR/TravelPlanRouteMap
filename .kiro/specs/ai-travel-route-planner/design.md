# 设计文档：AI旅行路线规划应用

## 概述

AI旅行路线规划应用是一个基于iOS的Swift应用，采用MVVM架构模式，结合AI Agent实现智能路线规划。应用的核心是一个路线优化算法，通过AI分析景点位置、出行方式等因素，生成最优游览顺序和住宿推荐。应用使用高德地图SDK进行可视化展示和地理信息服务，提供简洁流畅的用户体验。

### 核心设计原则

1. **关注点分离**: UI层、业务逻辑层、数据层和AI交互层严格分离
2. **可测试性**: 所有核心逻辑都可以通过单元测试和属性测试验证
3. **可维护性**: 提示词独立管理，便于优化AI效果；AI模块独立设计，便于后期迁移到服务端
4. **用户体验优先**: 流畅的交互和清晰的视觉反馈
5. **数据验证**: 使用高德地图POI搜索和地理编码，防止用户输入非法数据
6. **统一地图服务**: 所有地图相关功能均使用高德地图SDK，确保一致性

## 架构

### 整体架构

应用采用MVVM（Model-View-ViewModel）架构，结合Coordinator模式管理导航流程。

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Destination  │  │  Attraction  │  │    Result    │     │
│  │     View     │  │     View     │  │     View     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      ViewModel Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Destination  │  │  Attraction  │  │    Result    │     │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Route Planning Service                  │  │
│  │  ┌────────────────┐      ┌────────────────┐         │  │
│  │  │   AI Agent     │ ←──→ │ Prompt Module  │         │  │
│  │  └────────────────┘      └────────────────┘         │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Accommodation Service                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Repository  │  │  Local Store │  │   Map SDK    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 模块职责

1. **View Layer（视图层）**
   - 负责UI渲染和用户交互
   - 使用SwiftUI构建声明式UI
   - 绑定ViewModel的状态和事件

2. **ViewModel Layer（视图模型层）**
   - 管理视图状态
   - 处理用户输入验证
   - 调用业务逻辑服务
   - 将业务数据转换为视图数据

3. **Business Logic Layer（业务逻辑层）**
   - Route Planning Service: 核心路线规划逻辑
   - AI Agent: 与AI模型交互，执行智能规划
   - Prompt Module: 管理所有AI提示词
   - Accommodation Service: 住宿区域推荐逻辑

4. **Data Layer（数据层）**
   - Repository: 数据访问抽象层
   - Local Store: 本地数据持久化（UserDefaults/CoreData）
   - Map SDK Wrapper: 高德地图SDK封装

## 组件和接口

### 1. 提示词模块（Prompt Module）

提示词模块负责管理所有与AI交互的提示词，支持动态配置和版本管理。该模块独立设计，便于后期从客户端迁移至服务端。

**设计理由：** 将提示词独立管理可以：
1. 方便优化AI效果而不影响其他代码
2. 支持A/B测试不同的提示词策略
3. 便于后期迁移到服务端统一管理

```swift
protocol PromptProvider {
    func getRouteOptimizationPrompt(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) -> String
    
    func getAccommodationRecommendationPrompt(
        route: PlannedRoute,
        dayCount: Int,
        travelMode: TravelMode?
    ) -> String
    
    func getDurationEstimationPrompt(
        attractions: [Attraction],
        totalDistance: Double
    ) -> String
}

class PromptModule: PromptProvider {
    private let templates: PromptTemplates
    
    func getRouteOptimizationPrompt(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) -> String {
        // 构建路线优化提示词
        // 包含：目的地、景点列表、出行方式、优化目标
    }
    
    func getAccommodationRecommendationPrompt(
        route: PlannedRoute,
        dayCount: Int,
        travelMode: TravelMode?
    ) -> String {
        // 构建住宿推荐提示词
        // 包含：路线信息、天数、推荐原则
        // 根据出行方式限制推荐范围：
        // - 步行/公共交通：1-3km
        // - 自驾：3-5km
    }
    
    func getDurationEstimationPrompt(
        attractions: [Attraction],
        totalDistance: Double
    ) -> String {
        // 构建游玩天数估算提示词
        // 包含：景点数量、总距离、单个景点预计游玩时间
        // 注意：需要综合考虑距离、景点数量、单个景点所需时间等因素
    }
}
```

### 2. AI Agent

AI Agent负责与AI模型通信，执行路线规划和推荐任务。使用OpenAI接口格式，便于后期迁移到服务端或更换AI服务提供商。

**设计理由：** 
1. 使用标准OpenAI接口格式，兼容性好
2. 独立的Agent层便于后期迁移到服务端
3. 支持更换不同的AI模型而不影响业务逻辑

```swift
protocol AIAgent {
    func optimizeRoute(
        attractions: [Attraction],
        travelMode: TravelMode?,
        prompt: String
    ) async throws -> OptimizedRoute
    
    func recommendAccommodations(
        route: PlannedRoute,
        dayCount: Int,
        prompt: String
    ) async throws -> [AccommodationZone]
    
    func estimateDuration(
        attractions: [Attraction],
        totalDistance: Double,
        prompt: String
    ) async throws -> Int
}

class OpenAIAgent: AIAgent {
    private let apiKey: String
    private let model: String = "gpt-4"
    private let baseURL: String = "https://api.openai.com/v1"
    
    // 使用标准OpenAI接口格式
    func optimizeRoute(
        attractions: [Attraction],
        travelMode: TravelMode?,
        prompt: String
    ) async throws -> OptimizedRoute {
        // 构建OpenAI API请求
        let request = OpenAIRequest(
            model: model,
            messages: [
                Message(role: "system", content: "你是一个专业的旅行路线规划助手"),
                Message(role: "user", content: prompt)
            ],
            temperature: 0.7
        )
        
        // 调用OpenAI API
        // 解析返回的路线顺序
        // 返回优化后的路线
    }
    
    // 其他方法实现...
}

// OpenAI API 数据模型
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
}

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}
```

### 3. 路线规划服务（Route Planning Service）

路线规划服务协调AI Agent和提示词模块，执行完整的路线规划流程。

```swift
protocol RoutePlanningService {
    func planRoute(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async throws -> TravelPlan
}

class DefaultRoutePlanningService: RoutePlanningService {
    private let aiAgent: AIAgent
    private let promptProvider: PromptProvider
    private let geocoder: GeocodingService
    
    func planRoute(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async throws -> TravelPlan {
        // 1. 获取景点地理坐标
        let geocodedAttractions = try await geocodeAttractions(attractions)
        
        // 2. 生成路线优化提示词
        let routePrompt = promptProvider.getRouteOptimizationPrompt(
            destination: destination,
            attractions: geocodedAttractions,
            travelMode: travelMode
        )
        
        // 3. 调用AI优化路线
        let optimizedRoute = try await aiAgent.optimizeRoute(
            attractions: geocodedAttractions,
            travelMode: travelMode,
            prompt: routePrompt
        )
        
        // 4. 计算总距离
        let totalDistance = calculateTotalDistance(optimizedRoute)
        
        // 5. 估算游玩天数
        let durationPrompt = promptProvider.getDurationEstimationPrompt(
            attractions: geocodedAttractions,
            totalDistance: totalDistance
        )
        let recommendedDays = try await aiAgent.estimateDuration(
            attractions: geocodedAttractions,
            totalDistance: totalDistance,
            prompt: durationPrompt
        )
        
        // 6. 推荐住宿区域
        let accommodationPrompt = promptProvider.getAccommodationRecommendationPrompt(
            route: optimizedRoute,
            dayCount: recommendedDays,
            travelMode: travelMode
        )
        let accommodations = try await aiAgent.recommendAccommodations(
            route: optimizedRoute,
            dayCount: recommendedDays,
            prompt: accommodationPrompt
        )
        
        // 7. 构建完整旅行计划
        return TravelPlan(
            destination: destination,
            route: optimizedRoute,
            recommendedDays: recommendedDays,
            accommodations: accommodations,
            totalDistance: totalDistance
        )
    }
    
    private func geocodeAttractions(_ attractions: [Attraction]) async throws -> [Attraction] {
        // 景点已经通过POI搜索获取了坐标，直接返回
        // 如果有景点缺少坐标，使用高德地图地理编码服务补充
        return try await withThrowingTaskGroup(of: Attraction.self) { group in
            for attraction in attractions {
                if attraction.coordinate == nil {
                    group.addTask {
                        let results = try await self.geocoder.geocode(address: attraction.name)
                        guard let first = results.first else {
                            throw TravelPlanError.geocodingFailed(attraction.name)
                        }
                        return Attraction(
                            id: attraction.id,
                            name: attraction.name,
                            coordinate: first.coordinate,
                            address: first.address
                        )
                    }
                } else {
                    group.addTask { attraction }
                }
            }
            
            var geocoded: [Attraction] = []
            for try await attraction in group {
                geocoded.append(attraction)
            }
            return geocoded
        }
    }
    
    private func calculateTotalDistance(_ route: OptimizedRoute) -> Double {
        // 计算路线总距离
    }
}
```

### 4. 地图服务（Map Service）

地图服务封装高德地图SDK，提供地图显示、标注、地理编码和POI搜索功能。所有与地图相关的能力均使用高德地图SDK实现。

**设计理由：**
1. 统一使用高德地图SDK，避免多个地图服务混用
2. 封装地理编码和POI搜索，支持用户输入验证
3. 提供模糊搜索功能，防止用户输入非法数据

```swift
protocol MapService {
    func displayMap(in view: UIView, region: MapRegion)
    func addAttractionMarkers(_ attractions: [Attraction], ordered: Bool)
    func drawRoute(_ route: [Coordinate])
    func addAccommodationZones(_ zones: [AccommodationZone])
    func fitMapToShowAllElements()
}

// 地理编码服务（使用高德地图SDK）
protocol GeocodingService {
    func geocode(address: String) async throws -> [GeocodingResult]
    func searchPOI(keyword: String, city: String?) async throws -> [POIResult]
}

// 地理编码结果
struct GeocodingResult {
    let name: String
    let address: String
    let coordinate: Coordinate
    let city: String
}

// POI搜索结果
struct POIResult {
    let name: String
    let address: String
    let coordinate: Coordinate
    let type: String
}

class AMapService: MapService {
    private var mapView: MAMapView?
    
    func displayMap(in view: UIView, region: MapRegion) {
        // 初始化高德地图视图
        let map = MAMapView(frame: view.bounds)
        
        // 配置地图样式（基于 UI/UX 指南）
        configureMapStyle(map)
        
        map.centerCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        view.addSubview(map)
        self.mapView = map
    }
    
    // 地图样式配置（基于 UI/UX 指南 5.1）
    private func configureMapStyle(_ mapView: MAMapView) {
        mapView.mapType = .standard
        mapView.showsBuildings = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // 可选：自定义地图配色
        // let styleOptions = MAMapCustomStyleOptions()
        // styleOptions.styleDataPath = "style.data"
        // mapView.setCustomMapStyleOptions(styleOptions)
    }
    
    func addAttractionMarkers(_ attractions: [Attraction], ordered: Bool) {
        // 添加景点标记（使用自定义标记视图）
        for (index, attraction) in attractions.enumerated() {
            guard let coordinate = attraction.coordinate else { continue }
            
            let annotation = MAPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            annotation.title = ordered ? "\(index + 1). \(attraction.name)" : attraction.name
            mapView?.addAnnotation(annotation)
        }
    }
    
    func drawRoute(_ route: [Coordinate]) {
        // 绘制路线（基于 UI/UX 指南 5.3）
        let coordinates = route.map { coord in
            CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        let polyline = MAPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        mapView?.add(polyline)
    }
    
    func addAccommodationZones(_ zones: [AccommodationZone]) {
        // 添加住宿区域标注（基于 UI/UX 指南 5.4）
        for zone in zones {
            let circle = MACircle(
                center: CLLocationCoordinate2D(
                    latitude: zone.center.latitude,
                    longitude: zone.center.longitude
                ),
                radius: zone.radius
            )
            mapView?.add(circle)
        }
    }
    
    func fitMapToShowAllElements() {
        // 调整地图视野以显示所有元素
        mapView?.showAnnotations(mapView?.annotations, animated: true)
    }
}

// 高德地图地理编码服务实现
class AMapGeocodingService: GeocodingService {
    private let search = AMapSearchAPI()
    
    func geocode(address: String) async throws -> [GeocodingResult] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = AMapGeocodeSearchRequest()
            request.address = address
            
            search?.aMapGeocodeSearch(request) { request, response in
                guard let geocodes = response?.geocodes else {
                    continuation.resume(throwing: TravelPlanError.geocodingFailed(address))
                    return
                }
                
                let results = geocodes.compactMap { geocode -> GeocodingResult? in
                    guard let location = geocode.location else { return nil }
                    return GeocodingResult(
                        name: geocode.formattedAddress ?? "",
                        address: geocode.formattedAddress ?? "",
                        coordinate: Coordinate(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),
                        city: geocode.city ?? ""
                    )
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    func searchPOI(keyword: String, city: String?) async throws -> [POIResult] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = AMapPOIKeywordsSearchRequest()
            request.keywords = keyword
            request.city = city
            request.requireExtension = true
            
            search?.aMapPOIKeywordsSearch(request) { request, response in
                guard let pois = response?.pois else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = pois.compactMap { poi -> POIResult? in
                    guard let location = poi.location else { return nil }
                    return POIResult(
                        name: poi.name ?? "",
                        address: poi.address ?? "",
                        coordinate: Coordinate(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),
                        type: poi.type ?? ""
                    )
                }
                
                continuation.resume(returning: results)
            }
        }
    }
}

// 地图代理方法扩展（实现自定义样式）
extension AMapService: MAMapViewDelegate {
    
// 地图代理方法扩展（实现自定义样式）
extension AMapService: MAMapViewDelegate {
    // 自定义景点标记视图（基于 UI/UX 指南 5.2）
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        guard annotation is MAPointAnnotation else { return nil }
        
        let identifier = "AttractionAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? AttractionAnnotationView
        
        if annotationView == nil {
            annotationView = AttractionAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        annotationView?.annotation = annotation
        return annotationView
    }
    
    // 自定义路线样式（基于 UI/UX 指南 5.3）
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay is MAPolyline {
            let renderer = MAPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 6
            renderer.strokeColor = UIColor(hex: "06B6D4")  // 主色（天空蓝）
            renderer.lineJoinType = .round
            renderer.lineCapType = .round
            return renderer
        }
        
        if overlay is MACircle {
            let renderer = MACircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor(hex: "EC4899").withAlphaComponent(0.15)  // 粉红色，15% 透明度
            renderer.strokeColor = UIColor(hex: "EC4899")  // 粉红色边框
            renderer.lineWidth = 2
            return renderer
        }
        
        return nil
    }
}

// 自定义景点标记视图（基于 UI/UX 指南 5.2）
class AttractionAnnotationView: MAAnnotationView {
    let indexLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    override init(annotation: MAAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let size: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        // 渐变背景（天空蓝渐变）
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = size / 2
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 序号标签
        indexLabel.frame = bounds
        indexLabel.textAlignment = .center
        indexLabel.font = .systemFont(ofSize: 18, weight: .bold)
        indexLabel.textColor = .white
        addSubview(indexLabel)
        
        // 阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
```

### 5. 数据仓库（Repository）

数据仓库提供数据访问抽象，支持本地持久化。所有数据存储在客户端本地，提供基础的增删改查功能。

**设计理由：**
1. 使用UserDefaults进行轻量级数据存储
2. 支持基本的CRUD操作
3. 为后期迁移到CoreData或云端存储预留接口

```swift
protocol TravelPlanRepository {
    func savePlan(_ plan: TravelPlan) throws
    func getLatestPlan() -> TravelPlan?
    func getAllPlans() -> [TravelPlan]
    func deletePlan(id: String) throws
    func updatePlan(_ plan: TravelPlan) throws
}

class LocalTravelPlanRepository: TravelPlanRepository {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "travel_plans"
    
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // 创建：保存新计划
    func savePlan(_ plan: TravelPlan) throws {
        var plans = getAllPlans()
        plans.insert(plan, at: 0)
        let allData = try encoder.encode(plans)
        userDefaults.set(allData, forKey: storageKey)
    }
    
    // 读取：获取最新计划
    func getLatestPlan() -> TravelPlan? {
        return getAllPlans().first
    }
    
    // 读取：获取所有计划
    func getAllPlans() -> [TravelPlan] {
        guard let data = userDefaults.data(forKey: storageKey),
              let plans = try? decoder.decode([TravelPlan].self, from: data) else {
            return []
        }
        return plans
    }
    
    // 更新：修改现有计划
    func updatePlan(_ plan: TravelPlan) throws {
        var plans = getAllPlans()
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
            let data = try encoder.encode(plans)
            userDefaults.set(data, forKey: storageKey)
        } else {
            throw TravelPlanError.persistenceError("计划不存在")
        }
    }
    
    // 删除：移除指定计划
    func deletePlan(id: String) throws {
        var plans = getAllPlans()
        plans.removeAll { $0.id == id }
        let data = try encoder.encode(plans)
        userDefaults.set(data, forKey: storageKey)
    }
}
```

```swift
protocol TravelPlanRepository {
    func savePlan(_ plan: TravelPlan) throws
    func getLatestPlan() -> TravelPlan?
    func getAllPlans() -> [TravelPlan]
    func deletePlan(id: String) throws
}

class LocalTravelPlanRepository: TravelPlanRepository {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func savePlan(_ plan: TravelPlan) throws {
        let data = try encoder.encode(plan)
        var plans = getAllPlans()
        plans.insert(plan, at: 0)
        let allData = try encoder.encode(plans)
        userDefaults.set(allData, forKey: "travel_plans")
    }
    
    func getLatestPlan() -> TravelPlan? {
        return getAllPlans().first
    }
    
    func getAllPlans() -> [TravelPlan] {
        guard let data = userDefaults.data(forKey: "travel_plans"),
              let plans = try? decoder.decode([TravelPlan].self, from: data) else {
            return []
        }
        return plans
    }
    
    func deletePlan(id: String) throws {
        var plans = getAllPlans()
        plans.removeAll { $0.id == id }
        let data = try encoder.encode(plans)
        userDefaults.set(data, forKey: "travel_plans")
    }
}
```

## 数据模型

### 核心数据模型

```swift
// 坐标
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

// 出行方式
enum TravelMode: String, Codable {
    case publicTransport = "公共交通"
    case driving = "自驾"
}

// 景点
struct Attraction: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var coordinate: Coordinate?
    var address: String?  // 用于 UI 显示
    
    init(id: String = UUID().uuidString, name: String, coordinate: Coordinate? = nil, address: String? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
}

// 优化后的路线
struct OptimizedRoute: Codable, Equatable {
    let orderedAttractions: [Attraction]
    let routePath: [Coordinate]
    
    var attractionCount: Int {
        orderedAttractions.count
    }
}

// 住宿区域
struct AccommodationZone: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let center: Coordinate
    let radius: Double // 单位：米
    let dayNumber: Int // 第几天的住宿
    
    init(id: String = UUID().uuidString, name: String, center: Coordinate, radius: Double, dayNumber: Int) {
        self.id = id
        self.name = name
        self.center = center
        self.radius = radius
        self.dayNumber = dayNumber
    }
}

// 旅行计划
struct TravelPlan: Codable, Identifiable, Equatable {
    let id: String
    let destination: String
    let route: OptimizedRoute
    let recommendedDays: Int
    let accommodations: [AccommodationZone]
    let totalDistance: Double // 单位：公里
    let createdAt: Date
    let travelMode: TravelMode?
    
    init(
        id: String = UUID().uuidString,
        destination: String,
        route: OptimizedRoute,
        recommendedDays: Int,
        accommodations: [AccommodationZone],
        totalDistance: Double,
        createdAt: Date = Date(),
        travelMode: TravelMode? = nil
    ) {
        self.id = id
        self.destination = destination
        self.route = route
        self.recommendedDays = recommendedDays
        self.accommodations = accommodations
        self.totalDistance = totalDistance
        self.createdAt = createdAt
        self.travelMode = travelMode
    }
}

// 地图区域
struct MapRegion: Equatable {
    let center: Coordinate
    let span: MapSpan
}

struct MapSpan: Equatable {
    let latitudeDelta: Double
    let longitudeDelta: Double
}
```

### UI 组件样式

基于 UI/UX 指南，定义可复用的组件样式：

```swift
// 主要按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.microInteraction), value: configuration.isPressed)
    }
}

// 次要按钮样式
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.microInteraction), value: configuration.isPressed)
    }
}

// 自定义输入框
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 24, height: 24)
            
            TextField(placeholder, text: $text)
                .font(.body)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// 景点卡片
struct AttractionCard: View {
    let attraction: Attraction
    let index: Int
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // 序号标记
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(attraction.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppColors.text)
                
                if let address = attraction.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 加载视图
struct LoadingView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(AppColors.border, lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        reduceMotion ? .none : .linear(duration: AnimationDuration.loading).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text("正在规划路线...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// 错误视图
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "F97316"))
            
            Text(message)
                .font(.body)
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                HapticFeedback.light()
                onRetry()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 200)
        }
        .padding(Spacing.xl)
    }
}
```

### ViewModel数据模型

```swift
// 目的地输入ViewModel
class DestinationViewModel: ObservableObject {
    @Published var destination: String = ""
    @Published var searchResults: [GeocodingResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedDestination: GeocodingResult?
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let geocodingService: GeocodingService
    
    init(geocodingService: GeocodingService) {
        self.geocodingService = geocodingService
    }
    
    // 搜索目的地（使用高德地理编码）
    func searchDestination(keyword: String) async {
        guard !keyword.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        do {
            searchResults = try await geocodingService.geocode(address: keyword)
        } catch {
            errorMessage = "搜索失败：\(error.localizedDescription)"
            searchResults = []
        }
        isSearching = false
    }
    
    // 选择目的地
    func selectDestination(_ result: GeocodingResult) {
        selectedDestination = result
        destination = result.name
        searchResults = []
        validate()
    }
    
    func validate() {
        isValid = selectedDestination != nil && !destination.trimmingCharacters(in: .whitespaces).isEmpty
        errorMessage = isValid ? nil : "请选择有效的目的地"
    }
}

// 景点输入ViewModel
class AttractionViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var currentInput: String = ""
    @Published var searchResults: [POIResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var travelMode: TravelMode?
    
    private let geocodingService: GeocodingService
    private let destination: String
    let maxAttractions = 10
    
    init(geocodingService: GeocodingService, destination: String) {
        self.geocodingService = geocodingService
        self.destination = destination
    }
    
    // 模糊搜索景点（使用高德POI搜索）
    func searchAttractions(keyword: String) async {
        guard !keyword.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        do {
            searchResults = try await geocodingService.searchPOI(
                keyword: keyword,
                city: destination
            )
        } catch {
            errorMessage = "搜索失败：\(error.localizedDescription)"
            searchResults = []
        }
        isSearching = false
    }
    
    // 从搜索结果中选择景点
    func selectAttraction(_ result: POIResult) {
        guard attractions.count < maxAttractions else {
            errorMessage = "最多支持\(maxAttractions)个景点"
            return
        }
        
        let attraction = Attraction(
            name: result.name,
            coordinate: result.coordinate,
            address: result.address
        )
        attractions.append(attraction)
        currentInput = ""
        searchResults = []
        errorMessage = nil
    }
    
    func removeAttraction(at index: Int) {
        attractions.remove(at: index)
    }
    
    func canProceed() -> Bool {
        return attractions.count >= 2
    }
}

// 结果展示ViewModel
class ResultViewModel: ObservableObject {
    @Published var travelPlan: TravelPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let planningService: RoutePlanningService
    private let repository: TravelPlanRepository
    
    init(planningService: RoutePlanningService, repository: TravelPlanRepository) {
        self.planningService = planningService
        self.repository = repository
    }
    
    func planRoute(destination: String, attractions: [Attraction], travelMode: TravelMode?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let plan = try await planningService.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: travelMode
            )
            
            try repository.savePlan(plan)
            
            await MainActor.run {
                self.travelPlan = plan
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "规划失败：\(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
```


## 正确性属性

属性是一种特征或行为，应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性是人类可读规范和机器可验证正确性保证之间的桥梁。

### 属性 1：输入验证一致性

*对于任意*输入字符串（目的地或景点名称），如果字符串仅包含空白字符或为空，则验证函数应拒绝该输入并返回错误

**验证需求：1.2, 3.2**

### 属性 2：目的地保存往返一致性

*对于任意*有效的目的地字符串，提交后保存再读取应返回相同的目的地值

**验证需求：1.3**

### 属性 3：出行方式保存一致性

*对于任意*出行方式选择（公共交通或自驾），保存后读取应返回相同的出行方式

**验证需求：2.2**

### 属性 4：景点列表最小数量验证

*对于任意*景点列表，如果列表包含少于2个景点，则验证函数应拒绝该列表并返回错误

**验证需求：3.4**

### 属性 5：路线规划返回有效排列

*对于任意*包含N个景点的列表，路线规划返回的顺序应该是这N个景点的有效排列（包含所有景点且每个景点恰好出现一次）

**验证需求：4.1**

### 属性 6：路线优化减少距离

*对于任意*景点列表，优化后的路线总距离应小于等于原始输入顺序的总距离

**验证需求：4.2**

### 属性 7：规划结果完整性

*对于任意*成功的路线规划，返回的TravelPlan对象应包含所有必需字段：景点顺序、路线路径、推荐天数、住宿区域和总距离

**验证需求：4.4**

### 属性 8：推荐天数为正整数

*对于任意*路线规划结果，推荐的游玩天数应为正整数（≥1）

**验证需求：5.1**

### 属性 9：住宿区域数量与天数关系

*对于任意*推荐游玩天数大于1的旅行计划，住宿区域的数量应等于推荐天数减1（因为最后一天不需要住宿）

**验证需求：6.2**

### 属性 17：住宿区域范围限制

*对于任意*住宿推荐，如果出行方式为步行或公共交通，住宿区域半径应在1-3km范围内；如果出行方式为自驾，住宿区域半径应在3-5km范围内

**验证需求：6.6**

### 属性 10：地图元素完整性

*对于任意*旅行计划，地图上显示的景点标记数量应等于路线中的景点数量，路径应连接所有景点，住宿区域标注数量应等于住宿区域数量

**验证需求：7.1, 7.2, 7.3, 7.4**

### 属性 11：提示词模块完整性

*对于任意*提示词请求（路线规划、住宿推荐、天数计算），提示词模块应返回非空的提示词字符串

**验证需求：8.2, 8.3, 8.5**

### 属性 12：数据持久化往返一致性

*对于任意*旅行计划对象，保存到本地存储后再读取应返回等价的对象（所有字段值相同）

**验证需求：10.1**

### 属性 13：历史记录增长

*对于任意*初始历史记录列表，添加一个新的旅行计划后，历史记录数量应增加1

**验证需求：10.3**

### 属性 14：历史记录数据完整性

*对于任意*历史记录中的旅行计划，应包含目的地、景点数量和创建时间字段

**验证需求：10.4**

### 属性 15：历史记录删除

*对于任意*历史记录列表和其中的某个计划ID，删除该ID后，列表中不应再包含该ID的计划

**验证需求：10.5**

### 属性 16：无效输入错误消息

*对于任意*无效输入，系统应返回非空的错误消息字符串

**验证需求：11.4**

### 属性 18：POI搜索结果有效性

*对于任意*POI搜索结果，每个结果应包含名称、地址和有效的坐标信息

**验证需求：1.5, 3.6**

## 错误处理

### 错误类型

应用定义以下错误类型：

```swift
enum TravelPlanError: Error, LocalizedError {
    case invalidDestination
    case invalidAttractionName
    case insufficientAttractions
    case tooManyAttractions
    case networkError
    case geocodingFailed(String)
    case aiPlanningFailed(String)
    case mapLoadingFailed
    case persistenceError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDestination:
            return "请输入有效的目的地"
        case .invalidAttractionName:
            return "景点名称不能为空"
        case .insufficientAttractions:
            return "至少需要2个景点才能规划路线"
        case .tooManyAttractions:
            return "最多支持10个景点"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .geocodingFailed(let attraction):
            return "无法识别景点：\(attraction)"
        case .aiPlanningFailed(let reason):
            return "规划失败：\(reason)"
        case .mapLoadingFailed:
            return "地图加载失败，请稍后重试"
        case .persistenceError(let reason):
            return "数据保存失败：\(reason)"
        }
    }
}
```

### 错误处理策略

1. **输入验证错误**
   - 在ViewModel层立即捕获
   - 显示内联错误消息
   - 阻止无效操作继续执行

2. **网络错误**
   - 使用重试机制（最多3次）
   - 显示用户友好的错误消息
   - 提供"重试"按钮

3. **AI规划错误**
   - 设置超时时间（30秒）
   - 超时后显示错误并允许重试
   - 记录错误日志用于调试

4. **地图加载错误**
   - 显示错误提示
   - 提供"重新加载"选项
   - 降级到文本列表显示（如果地图完全不可用）

5. **持久化错误**
   - 捕获并记录错误
   - 不阻止用户继续使用应用
   - 显示警告消息

### 错误恢复流程

```swift
class ErrorHandler {
    static func handle(_ error: Error, in viewModel: Any, retry: (() -> Void)? = nil) {
        let message: String
        let canRetry: Bool
        
        if let travelError = error as? TravelPlanError {
            message = travelError.errorDescription ?? "未知错误"
            canRetry = [.networkError, .aiPlanningFailed(""), .mapLoadingFailed].contains { type in
                String(describing: travelError).contains(String(describing: type))
            }
        } else {
            message = error.localizedDescription
            canRetry = false
        }
        
        // 在主线程更新UI
        DispatchQueue.main.async {
            if let vm = viewModel as? ResultViewModel {
                vm.errorMessage = message
                vm.isLoading = false
            }
            
            // 如果可以重试且提供了重试闭包，显示重试选项
            if canRetry, let retry = retry {
                // 显示重试对话框
            }
        }
    }
}
```

## 测试策略

### 双重测试方法

应用采用单元测试和基于属性的测试相结合的方法，确保全面的测试覆盖：

1. **单元测试**：验证特定示例、边缘情况和错误条件
2. **基于属性的测试**：验证所有输入的通用属性

两者是互补的，共同提供全面的覆盖（单元测试捕获具体错误，属性测试验证一般正确性）。

### 基于属性的测试配置

- 使用Swift的测试框架和属性测试库（如SwiftCheck）
- 每个属性测试最少运行100次迭代
- 每个测试必须引用其设计文档属性
- 标签格式：**Feature: ai-travel-route-planner, Property {编号}: {属性文本}**

### 测试覆盖范围

#### 1. 输入验证测试

**单元测试**：
- 测试空字符串输入
- 测试纯空白字符串输入
- 测试有效输入
- 测试特殊字符输入
- 测试POI搜索结果选择
- 测试地理编码结果选择

**属性测试**：
- 属性1：输入验证一致性
- 属性4：景点列表最小数量验证
- 属性18：POI搜索结果有效性

#### 2. 数据持久化测试

**单元测试**：
- 测试保存单个计划
- 测试保存多个计划
- 测试删除计划
- 测试读取不存在的计划

**属性测试**：
- 属性2：目的地保存往返一致性
- 属性3：出行方式保存一致性
- 属性12：数据持久化往返一致性
- 属性13：历史记录增长
- 属性15：历史记录删除

#### 3. 路线规划测试

**单元测试**：
- 测试2个景点的规划
- 测试10个景点的规划
- 测试不同出行方式的规划
- 测试规划失败场景

**属性测试**：
- 属性5：路线规划返回有效排列
- 属性6：路线优化减少距离
- 属性7：规划结果完整性
- 属性8：推荐天数为正整数
- 属性9：住宿区域数量与天数关系
- 属性17：住宿区域范围限制

#### 4. 提示词模块测试

**单元测试**：
- 测试路线规划提示词生成
- 测试住宿推荐提示词生成
- 测试天数计算提示词生成

**属性测试**：
- 属性11：提示词模块完整性

#### 5. 地图显示测试

**单元测试**：
- 测试景点标记添加
- 测试路线绘制
- 测试住宿区域标注

**属性测试**：
- 属性10：地图元素完整性

#### 6. 错误处理测试

**单元测试**：
- 测试网络错误处理
- 测试地图加载错误处理
- 测试AI规划超时处理
- 测试无效输入错误消息

**属性测试**：
- 属性16：无效输入错误消息

### 测试示例

#### 单元测试示例

```swift
import XCTest
@testable import TravelPlanner

class DestinationValidationTests: XCTestCase {
    var viewModel: DestinationViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DestinationViewModel()
    }
    
    func testEmptyDestinationIsInvalid() {
        viewModel.destination = ""
        viewModel.validate()
        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testWhitespaceDestinationIsInvalid() {
        viewModel.destination = "   "
        viewModel.validate()
        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testValidDestinationIsAccepted() {
        viewModel.destination = "北京"
        viewModel.validate()
        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

#### 基于属性的测试示例

```swift
import XCTest
import SwiftCheck
@testable import TravelPlanner

class RouteOptimizationPropertyTests: XCTestCase {
    // Feature: ai-travel-route-planner, Property 5: 路线规划返回有效排列
    func testRouteReturnsValidPermutation() {
        property("规划后的路线应包含所有原始景点且每个景点恰好出现一次") <- forAll { (attractionNames: ArrayOf<String>) in
            // 生成2-10个景点
            let names = Array(attractionNames.getArray.prefix(10))
            guard names.count >= 2 else { return Discard() }
            
            let attractions = names.enumerated().map { index, name in
                Attraction(
                    id: "\(index)",
                    name: name.isEmpty ? "景点\(index)" : name,
                    coordinate: Coordinate(
                        latitude: 39.9 + Double(index) * 0.1,
                        longitude: 116.4 + Double(index) * 0.1
                    )
                )
            }
            
            let service = MockRoutePlanningService()
            let result = try? await service.planRoute(
                destination: "北京",
                attractions: attractions,
                travelMode: nil
            )
            
            guard let plan = result else { return false }
            
            // 验证：返回的景点数量相同
            guard plan.route.orderedAttractions.count == attractions.count else {
                return false
            }
            
            // 验证：所有原始景点都在结果中
            let originalIds = Set(attractions.map { $0.id })
            let resultIds = Set(plan.route.orderedAttractions.map { $0.id })
            
            return originalIds == resultIds
        }
    }
    
    // Feature: ai-travel-route-planner, Property 12: 数据持久化往返一致性
    func testPersistenceRoundTrip() {
        property("保存后读取应返回相同的旅行计划") <- forAll { (seed: Int) in
            let repository = LocalTravelPlanRepository()
            
            // 生成随机旅行计划
            let plan = generateRandomTravelPlan(seed: seed)
            
            // 保存
            try? repository.savePlan(plan)
            
            // 读取
            let retrieved = repository.getLatestPlan()
            
            // 验证相等
            return retrieved == plan
        }
    }
}
```

### 集成测试

除了单元测试和属性测试，还需要进行端到端的集成测试：

1. **完整流程测试**
   - 从输入目的地到显示规划结果的完整流程
   - 验证所有组件正确协作

2. **地图集成测试**
   - 验证高德地图SDK正确集成
   - 验证地图元素正确显示

3. **AI集成测试**
   - 使用模拟AI响应测试规划流程
   - 验证提示词正确传递给AI

### 测试数据生成

为了支持基于属性的测试，需要实现随机数据生成器：

```swift
extension Attraction: Arbitrary {
    public static var arbitrary: Gen<Attraction> {
        return Gen.compose { c in
            Attraction(
                name: c.generate(using: String.arbitrary),
                coordinate: c.generate(using: Coordinate.arbitrary)
            )
        }
    }
}

extension Coordinate: Arbitrary {
    public static var arbitrary: Gen<Coordinate> {
        return Gen.compose { c in
            Coordinate(
                latitude: c.generate(using: Double.arbitrary.suchThat { $0 >= -90 && $0 <= 90 }),
                longitude: c.generate(using: Double.arbitrary.suchThat { $0 >= -180 && $0 <= 180 })
            )
        }
    }
}

extension TravelMode: Arbitrary {
    public static var arbitrary: Gen<TravelMode> {
        return Gen.fromElements(of: [.publicTransport, .driving])
    }
}
```

### 性能测试

虽然不是主要关注点，但应该进行基本的性能测试：

1. **路线规划性能**
   - 10个景点的规划应在30秒内完成
   - 测试不同景点数量的规划时间

2. **地图渲染性能**
   - 地图加载应在3秒内完成
   - 添加10个标记应流畅无卡顿

3. **数据持久化性能**
   - 保存100个历史记录应在1秒内完成
   - 读取历史记录应即时响应

## 实现注意事项

### UI/UX 实现

详细的 UI/UX 实现指南请参考：`.kiro/specs/ai-travel-route-planner/ui-ux-guide.md`

**关键要点：**

1. **严格遵循设计系统**
   - 使用定义的配色方案（AppColors）
   - 统一圆角半径为 12pt
   - 使用标准间距系统（Spacing）
   - 遵循动画时长标准

2. **无障碍优先**
   - 始终检查 `accessibilityReduceMotion`
   - 确保文本对比度至少 4.5:1
   - 触摸目标最小 44×44pt
   - 支持 VoiceOver

3. **性能优化**
   - 渐变使用 CAGradientLayer
   - 列表使用 LazyVStack/LazyHStack
   - 地图标注使用复用机制
   - 动画使用 transform 和 opacity

4. **触觉反馈**
   - 仅在重要操作时使用
   - 不要过度使用（避免每次点击都震动）

### 高德地图SDK集成

**重要：** 整个程序内嵌高德地图SDK，所有与地图显示、位置信息和景点间规划线路的能力均使用高德地图。

**官方文档：** https://lbs.amap.com/api/ios-sdk/summary

1. **SDK配置**
   - 在Info.plist中添加API Key
   - 配置位置权限描述
   - 导入AMapFoundationKit和MAMapKit

2. **地图初始化**
   ```swift
   // 在AppDelegate中配置
   AMapServices.shared().apiKey = "YOUR_API_KEY"
   ```

3. **地图视图使用**
   - 使用UIViewRepresentable包装MAMapView以在SwiftUI中使用
   - 实现Coordinator处理地图代理方法

4. **地理编码和POI搜索**
   - 使用AMapSearchAPI进行地理编码
   - 使用POI搜索实现景点和目的地的模糊搜索
   - 防止用户输入非法数据

5. **路线规划**
   - 使用高德地图的路径规划API获取景点间的实际路线
   - 支持不同出行方式（步行、公交、驾车）的路线规划

### AI提示词设计

提示词应该清晰、具体，包含所有必要信息：

**路线优化提示词模板**：
```
你是一个专业的旅行路线规划助手。请根据以下信息规划最优游览顺序：

目的地：{destination}
景点列表：
{attractions with coordinates}
出行方式：{travel_mode}

规划要求：
1. 最小化总行程距离
2. 避免回头路和冤枉路
3. 考虑{travel_mode}的特点（公共交通考虑换乘便利性，自驾考虑停车便利性）
4. 返回景点的最优游览顺序（使用景点ID）

请以JSON格式返回：
{
  "ordered_attraction_ids": ["id1", "id2", ...],
  "reasoning": "规划理由"
}
```

**天数估算提示词模板**：
```
请根据以下信息估算合理的游玩天数：

景点列表：
{attractions with names}
总距离：{total_distance} 公里
出行方式：{travel_mode}

估算要求：
1. 综合考虑景点数量、总距离、单个景点预计游玩时间
2. 考虑出行方式对时间的影响
3. 合理安排每天的行程，不要强行凑天数或凑个数
4. 每天游玩时间建议控制在8-10小时

请以JSON格式返回：
{
  "recommended_days": 3,
  "reasoning": "估算理由",
  "daily_breakdown": [
    {
      "day": 1,
      "estimated_hours": 8,
      "attractions_count": 3
    }
  ]
}
```

**住宿推荐提示词模板**：
```
请根据以下旅行路线推荐住宿区域：

路线信息：
{route with attractions and coordinates}
推荐天数：{day_count}
出行方式：{travel_mode}

推荐要求：
1. 每天推荐一个住宿区域（最后一天除外）
2. 住宿位置应靠近当天最后一个景点或第二天第一个景点
3. 考虑交通便利性
4. 根据出行方式限制推荐范围：
   - 步行或公共交通：推荐范围控制在1-3km内
   - 自驾：推荐范围控制在3-5km内

请以JSON格式返回：
{
  "accommodations": [
    {
      "day_number": 1,
      "name": "区域名称",
      "center": {"latitude": xx, "longitude": xx},
      "radius": 1000
    }
  ]
}
```

### 数据模型序列化

所有数据模型都应实现Codable协议，支持JSON序列化：

```swift
extension TravelPlan {
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
    
    static func fromJSON(_ data: Data) throws -> TravelPlan {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TravelPlan.self, from: data)
    }
}
```

### UI设计规范

详细的 UI/UX 设计规范请参考：`.kiro/specs/ai-travel-route-planner/ui-ux-guide.md`

#### 设计系统概览

**视觉风格：** Aurora UI（极光界面）
- 流动的渐变效果，营造探索氛围
- 柔和的色彩过渡
- 现代感强，适合旅行类应用

#### 配色方案

```swift
// 主题颜色定义（基于 UI/UX 指南）
enum AppColors {
    // 主色系
    static let primary = Color(hex: "06B6D4")      // 天空蓝 - 主要按钮、强调元素
    static let secondary = Color(hex: "0EA5E9")    // 浅蓝 - 次要按钮、链接
    static let accent = Color(hex: "EC4899")       // 粉红 - CTA按钮、住宿区域
    
    // 背景和文本
    static let background = Color(hex: "FDF2F8")   // 柔和粉白 - 主背景
    static let text = Color(hex: "1E293B")         // 深灰蓝 - 主要文本
    static let border = Color(hex: "E2E8F0")       // 浅灰 - 边框、分隔线
}

// 颜色扩展工具类
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```

#### 字体系统

```swift
// 使用 SF Pro（iOS 系统字体）
// 标题层级
.font(.largeTitle)      // 34pt - 页面主标题
.font(.title)           // 28pt - 区块标题
.font(.title2)          // 22pt - 次级标题
.font(.title3)          // 20pt - 卡片标题

// 正文层级
.font(.body)            // 17pt - 正文
.font(.callout)         // 16pt - 说明文字
.font(.subheadline)     // 15pt - 次要信息
.font(.footnote)        // 13pt - 脚注
.font(.caption)         // 12pt - 图注

// 字重
.bold               // 标题、重要信息
.semibold           // 次级标题、按钮文字
.regular            // 正文
.light              // 辅助信息
```

#### 圆角规范

统一使用 **12pt** 圆角半径（圆角扁平风格）：
- 卡片：12pt
- 按钮：12pt
- 输入框：12pt
- 所有容器组件：12pt

#### 间距系统

```swift
// 标准间距系统
enum Spacing {
    static let xs: CGFloat = 4      // 紧密相关元素（图标+文字）
    static let sm: CGFloat = 8      // 同组内元素
    static let md: CGFloat = 16     // 标准间距（最常用）
    static let lg: CGFloat = 24     // 区块间距
    static let xl: CGFloat = 32     // 大区块间距
    static let xxl: CGFloat = 48    // 页面顶部/底部留白
}
```

#### 动画规范

```swift
// 动画时长标准
enum AnimationDuration {
    static let microInteraction: Double = 0.2       // 150-200ms：按钮按压、开关
    static let pageTransitionIn: Double = 0.3       // 300ms：页面进入
    static let pageTransitionOut: Double = 0.25     // 250ms：页面退出
    static let loading: Double = 1.0                // 1000ms：旋转加载器
    static let listItem: Double = 0.2               // 200ms：列表项动画
}

// 缓动函数
// - 进入动画：.easeOut
// - 退出动画：.easeIn
// - 微交互：.easeInOut
// - 加载动画：.linear
// - 列表项：.spring(response: 0.3, dampingFraction: 0.7)

// 重要：始终检查减弱动画设置
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? .none : .spring()
}
```

#### 触觉反馈

```swift
enum HapticFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// 使用场景：
// - light(): 按钮点击、选择项
// - medium(): 重要操作确认
// - success(): 路线规划完成
// - error(): 输入错误、操作失败
```

#### 无障碍要求

1. **文本对比度**
   - 正文文本：至少 4.5:1
   - 大号文本（18pt+）：至少 3:1
   - 图标和重要元素：至少 3:1

2. **触摸目标尺寸**
   - 按钮：最小 44pt × 44pt
   - 列表项：最小高度 44pt
   - 图标按钮：48pt × 48pt（含内边距）

3. **动画减弱支持**
   - 始终检查 `accessibilityReduceMotion`
   - 装饰性动画可被禁用
   - 保留必要的状态变化反馈

#### 性能优化

1. **渐变优化**
   - 使用 CAGradientLayer 而非实时渲染
   - 限制同时显示的渐变数量

2. **列表优化**
   - 使用 LazyVStack/LazyHStack
   - 避免在滚动时执行复杂计算

3. **动画优化**
   - 使用 transform 和 opacity（避免 frame 动画）
   - 限制同时运行的动画数量

### 依赖注入

使用依赖注入提高可测试性：

```swift
class AppDependencies {
    let promptProvider: PromptProvider
    let aiAgent: AIAgent
    let routePlanningService: RoutePlanningService
    let mapService: MapService
    let repository: TravelPlanRepository
    
    init() {
        self.promptProvider = PromptModule()
        self.aiAgent = OpenAIAgent(apiKey: Config.openAIKey)
        self.routePlanningService = DefaultRoutePlanningService(
            aiAgent: aiAgent,
            promptProvider: promptProvider,
            geocoder: AMapGeocodingService()
        )
        self.mapService = AMapService()
        self.repository = LocalTravelPlanRepository()
    }
    
    // 用于测试的初始化方法
    init(
        promptProvider: PromptProvider,
        aiAgent: AIAgent,
        routePlanningService: RoutePlanningService,
        mapService: MapService,
        repository: TravelPlanRepository
    ) {
        self.promptProvider = promptProvider
        self.aiAgent = aiAgent
        self.routePlanningService = routePlanningService
        self.mapService = mapService
        self.repository = repository
    }
}
```

## 总结

本设计文档描述了AI旅行路线规划应用的完整架构和实现方案。核心设计包括：

1. **清晰的架构分层**：MVVM模式确保UI、业务逻辑和数据层的分离
2. **独立的提示词模块**：便于维护和优化AI交互效果，支持后期迁移到服务端
3. **标准OpenAI接口**：使用OpenAI接口格式，便于更换AI服务提供商或迁移到服务端
4. **全面的测试策略**：结合单元测试和基于属性的测试
5. **健壮的错误处理**：覆盖各种异常情况
6. **统一的高德地图集成**：所有地图相关功能（显示、地理编码、POI搜索、路线规划）均使用高德地图SDK
7. **智能输入验证**：通过POI搜索和地理编码防止用户输入非法数据
8. **本地数据持久化**：提供完整的CRUD功能，支持历史记录管理
9. **专业的 UI/UX 设计**：基于 Aurora UI 设计系统，提供流畅的用户体验

### 关键设计决策

1. **POI搜索集成**：用户输入目的地和景点时，通过高德地图POI搜索提供候选列表，确保数据有效性
2. **住宿范围限制**：根据出行方式智能限制住宿推荐范围（步行/公交：1-3km，自驾：3-5km）
3. **综合天数估算**：AI估算游玩天数时综合考虑景点数量、距离、单个景点游玩时间等因素
4. **模块化AI层**：AI Agent独立设计，便于后期从客户端迁移到服务端
5. **本地优先存储**：当前版本数据存储在客户端，为后期云端同步预留接口

### UI/UX 设计亮点

- **Aurora UI 风格**：流动的渐变效果，营造探索氛围
- **天空蓝配色**：符合旅行主题，视觉舒适
- **12pt 统一圆角**：圆角扁平风格，现代简洁
- **标准间距系统**：4-48pt 六级间距，布局一致
- **流畅动画**：150-300ms 微交互，支持减弱动画
- **无障碍友好**：对比度达标，触摸目标合规
- **性能优化**：CAGradientLayer、LazyVStack、标注复用

详细的 UI/UX 规范请参考：`.kiro/specs/ai-travel-route-planner/ui-ux-guide.md`

设计遵循SOLID原则，确保代码的可维护性、可测试性和可扩展性。
