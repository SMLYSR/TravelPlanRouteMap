import Foundation

/// 应用依赖注入容器
class AppDependencies {
    static let shared = AppDependencies()
    
    let promptProvider: PromptProvider
    let repository: TravelPlanRepository
    
    // 延迟初始化的服务（避免启动时阻塞主线程）
    private var _aiAgent: AIAgent?
    private var _geocodingService: GeocodingService?
    private var _routePlanningService: RoutePlanningService?
    private var _mapService: MapService?
    private var _routeNavigationService: RouteNavigationServiceProtocol?
    
    var aiAgent: AIAgent {
        if _aiAgent == nil {
            if !Config.openAIKey.isEmpty {
                _aiAgent = OpenAIAgent(
                    apiKey: Config.openAIKey,
                    timeout: Config.aiTimeout
                )
            } else {
                _aiAgent = MockAIAgent()
            }
        }
        return _aiAgent!
    }
    
    var geocodingService: GeocodingService {
        if _geocodingService == nil {
            _geocodingService = AMapGeocodingService()
        }
        return _geocodingService!
    }
    
    var routePlanningService: RoutePlanningService {
        if _routePlanningService == nil {
            _routePlanningService = DefaultRoutePlanningService(
                aiAgent: aiAgent,
                promptProvider: promptProvider,
                geocodingService: geocodingService
            )
        }
        return _routePlanningService!
    }
    
    var mapService: MapService {
        if _mapService == nil {
            _mapService = AMapService()
        }
        return _mapService!
    }
    
    /// 路径导航服务
    /// 需求: 1.1, 1.2, 1.3, 1.4
    var routeNavigationService: RouteNavigationServiceProtocol {
        if _routeNavigationService == nil {
            _routeNavigationService = RouteNavigationService()
        }
        return _routeNavigationService!
    }
    
    private init() {
        // 只初始化轻量级服务
        self.promptProvider = PromptModule()
        self.repository = LocalTravelPlanRepository()
    }
    
    /// 用于测试的初始化方法
    init(
        promptProvider: PromptProvider,
        aiAgent: AIAgent,
        geocodingService: GeocodingService,
        routePlanningService: RoutePlanningService,
        mapService: MapService,
        repository: TravelPlanRepository,
        routeNavigationService: RouteNavigationServiceProtocol? = nil
    ) {
        self.promptProvider = promptProvider
        self._aiAgent = aiAgent
        self._geocodingService = geocodingService
        self._routePlanningService = routePlanningService
        self._mapService = mapService
        self.repository = repository
        self._routeNavigationService = routeNavigationService
    }
}
