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
            
            // 规划导航路线（获取实际道路路径）
            // 需求: 1.4, 6.2
            await planNavigationRoute(
                attractions: plan.route.orderedAttractions,
                travelMode: travelMode ?? .driving,
                citycode: citycode  // 传递citycode
            )
            
            // 创建包含导航路径的完整计划
            let planWithNavigation = TravelPlan(
                id: plan.id,
                destination: plan.destination,
                route: plan.route,
                recommendedDays: plan.recommendedDays,
                accommodations: plan.accommodations,
                totalDistance: plan.totalDistance,
                createdAt: plan.createdAt,
                travelMode: plan.travelMode,
                navigationPath: navigationPath  // 保存导航路径
            )
            
            // 保存到本地存储（包含导航路径）
            try repository.savePlan(planWithNavigation)
            
            travelPlan = planWithNavigation
            isSaved = true  // 新增：标记已保存
            
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
    
    /// 重新规划路线
    /// 使用当前景点列表重新调用AI服务生成新的路线规划
    /// 需求: 3（重新规划功能优化）
    @MainActor
    func replanRoute(
        destination: String,
        citycode: String?,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async {
        // 保存当前计划作为备份
        let backupPlan = self.travelPlan
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 调用AI规划服务
            let newPlan = try await planningService.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: travelMode
            )
            
            // 规划导航路线（获取实际道路路径）
            await planNavigationRoute(
                attractions: newPlan.route.orderedAttractions,
                travelMode: travelMode ?? .driving,
                citycode: citycode
            )
            
            // 更新当前计划（保持相同ID和createdAt）
            let updatedPlan = TravelPlan(
                id: backupPlan?.id ?? newPlan.id,
                destination: newPlan.destination,
                route: newPlan.route,
                recommendedDays: newPlan.recommendedDays,
                accommodations: newPlan.accommodations,
                totalDistance: newPlan.totalDistance,
                createdAt: backupPlan?.createdAt ?? Date(),
                travelMode: newPlan.travelMode,
                navigationPath: navigationPath
            )
            
            self.travelPlan = updatedPlan
            
            // 更新存储（如果是已保存的计划）
            if backupPlan != nil {
                try repository.updatePlan(updatedPlan)
            }
            
            HapticFeedback.success()
            
        } catch {
            // 恢复备份计划
            self.travelPlan = backupPlan
            
            // 设置用户友好的错误提示
            if let travelPlanError = error as? TravelPlanError {
                self.errorMessage = travelPlanError.errorDescription ?? "重新规划失败，请稍后重试"
            } else {
                self.errorMessage = "重新规划失败，请稍后重试"
            }
            
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    /// 更新路线（编辑景点后）
    /// 使用更新后的景点列表重新规划路线
    /// 需求: 2（历史路线编辑功能）
    @MainActor
    func updateRoute(
        planId: String,
        destination: String,
        citycode: String?,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async {
        // 保存当前计划作为备份
        let backupPlan = self.travelPlan
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 调用AI规划服务
            let newPlan = try await planningService.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: travelMode
            )
            
            // 规划导航路线（获取实际道路路径）
            await planNavigationRoute(
                attractions: newPlan.route.orderedAttractions,
                travelMode: travelMode ?? .driving,
                citycode: citycode
            )
            
            // 更新当前计划（保持相同ID和createdAt）
            let updatedPlan = TravelPlan(
                id: planId,
                destination: newPlan.destination,
                route: newPlan.route,
                recommendedDays: newPlan.recommendedDays,
                accommodations: newPlan.accommodations,
                totalDistance: newPlan.totalDistance,
                createdAt: backupPlan?.createdAt ?? Date(),
                travelMode: newPlan.travelMode,
                navigationPath: navigationPath
            )
            
            self.travelPlan = updatedPlan
            
            // 更新存储
            try repository.updatePlan(updatedPlan)
            
            HapticFeedback.success()
            
        } catch {
            // 恢复备份计划
            self.travelPlan = backupPlan
            
            // 设置用户友好的错误提示
            if let travelPlanError = error as? TravelPlanError {
                self.errorMessage = travelPlanError.errorDescription ?? "更新路线失败，请稍后重试"
            } else {
                self.errorMessage = "更新路线失败，请稍后重试"
            }
            
            HapticFeedback.error()
        }
        
        isLoading = false
    }
}
