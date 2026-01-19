import Foundation
import Combine

/// 结果展示 ViewModel
@MainActor
class ResultViewModel: ObservableObject {
    @Published var travelPlan: TravelPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let planningService: RoutePlanningService
    private let repository: TravelPlanRepository
    
    init(
        planningService: RoutePlanningService = AppDependencies.shared.routePlanningService,
        repository: TravelPlanRepository = AppDependencies.shared.repository
    ) {
        self.planningService = planningService
        self.repository = repository
    }
    
    /// 规划路线
    func planRoute(destination: String, attractions: [Attraction], travelMode: TravelMode?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let plan = try await planningService.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: travelMode
            )
            
            // 保存到本地存储
            try repository.savePlan(plan)
            
            travelPlan = plan
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
    
    /// 重试规划
    func retry(destination: String, attractions: [Attraction], travelMode: TravelMode?) {
        Task {
            await planRoute(destination: destination, attractions: attractions, travelMode: travelMode)
        }
    }
    
    /// 清除结果
    func clear() {
        travelPlan = nil
        errorMessage = nil
    }
}
