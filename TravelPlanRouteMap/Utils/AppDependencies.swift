import Foundation

/// 应用依赖注入容器
class AppDependencies {
    static let shared = AppDependencies()
    
    let promptProvider: PromptProvider
    let aiAgent: AIAgent
    let geocodingService: GeocodingService
    let routePlanningService: RoutePlanningService
    let mapService: MapService
    let repository: TravelPlanRepository
    
    private init() {
        // 初始化提示词模块
        self.promptProvider = PromptModule()
        
        // 初始化地理编码服务（使用高德地图）
        self.geocodingService = AMapGeocodingService()
        
        // 初始化 AI Agent
        if !Config.openAIKey.isEmpty {
            self.aiAgent = OpenAIAgent(
                apiKey: Config.openAIKey,
                timeout: Config.aiTimeout
            )
        } else {
            self.aiAgent = MockAIAgent()
        }
        
        // 初始化路线规划服务
        self.routePlanningService = DefaultRoutePlanningService(
            aiAgent: aiAgent,
            promptProvider: promptProvider,
            geocodingService: geocodingService
        )
        
        // 初始化地图服务（使用高德地图）
        self.mapService = AMapService()
        
        // 初始化数据仓库
        self.repository = LocalTravelPlanRepository()
    }
    
    /// 用于测试的初始化方法
    init(
        promptProvider: PromptProvider,
        aiAgent: AIAgent,
        geocodingService: GeocodingService,
        routePlanningService: RoutePlanningService,
        mapService: MapService,
        repository: TravelPlanRepository
    ) {
        self.promptProvider = promptProvider
        self.aiAgent = aiAgent
        self.geocodingService = geocodingService
        self.routePlanningService = routePlanningService
        self.mapService = mapService
        self.repository = repository
    }
}
