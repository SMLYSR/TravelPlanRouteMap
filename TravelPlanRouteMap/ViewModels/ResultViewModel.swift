import Foundation
import Combine

/// 结果展示 ViewModel
@MainActor
class ResultViewModel: ObservableObject {
    @Published var travelPlan: TravelPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSaved: Bool = false  // 新增：保存状态标记
    
    /// 导航路径（用于地图显示实际道路路线）
    /// 需求: 1.4, 6.2
    @Published var navigationPath: NavigationPath?
    
    private let planningService: RoutePlanningService
    private let repository: TravelPlanRepository
    private let routeNavigationService: RouteNavigationServiceProtocol
    
    init(
        planningService: RoutePlanningService = AppDependencies.shared.routePlanningService,
        repository: TravelPlanRepository = AppDependencies.shared.repository,
        routeNavigationService: RouteNavigationServiceProtocol = AppDependencies.shared.routeNavigationService
    ) {
        self.planningService = planningService
        self.repository = repository
        self.routeNavigationService = routeNavigationService
    }
    
    /// 规划路线
    func planRoute(destination: String, citycode: String?, attractions: [Attraction], travelMode: TravelMode?) async {
        isLoading = true
        errorMessage = nil
        navigationPath = nil
        isSaved = false  // 新增：重置保存状态
        
        do {
            let plan = try await planningService.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: travelMode
            )
            
            // 保存到本地存储
            try repository.savePlan(plan)
            
            travelPlan = plan
            isSaved = true  // 新增：标记已保存
            
            // 规划导航路线（获取实际道路路径）
            // 需求: 1.4, 6.2
            await planNavigationRoute(
                attractions: plan.route.orderedAttractions,
                travelMode: travelMode ?? .driving,
                citycode: citycode  // 传递citycode
            )
            
            isLoading = false
            HapticFeedback.success()
        } catch let error as TravelPlanError {
            errorMessage = error.errorDescription
            isLoading = false
            HapticFeedback.error()
        } catch {
            errorMessage = "规划失败：\(error.localizedDescription)"
            isLoading = false
            HapticFeedback.error()
        }
    }
    
    /// 规划导航路线（获取实际道路路径）
    /// 需求: 1.4, 6.2
    private func planNavigationRoute(attractions: [Attraction], travelMode: TravelMode, citycode: String?) async {
        do {
            let navPath = try await routeNavigationService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: citycode
            )
            navigationPath = navPath
            
            // 如果有降级路线段，打印警告
            if navPath.hasFallbackSegments {
                print("⚠️ 导航路线包含\(navPath.fallbackSegmentCount)个降级路线段")
            }
        } catch {
            // 导航路线规划失败不影响主流程，只打印警告
            print("⚠️ 导航路线规划失败: \(error.localizedDescription)")
            // navigationPath保持为nil，视图将使用routePath作为降级显示
        }
    }
    
    /// 重试规划
    func retry(destination: String, citycode: String?, attractions: [Attraction], travelMode: TravelMode?) {
        Task {
            await planRoute(destination: destination, citycode: citycode, attractions: attractions, travelMode: travelMode)
        }
    }
    
    /// 清除结果
    func clear() {
        travelPlan = nil
        errorMessage = nil
        navigationPath = nil
        isSaved = false  // 新增：重置保存状态
    }
}
