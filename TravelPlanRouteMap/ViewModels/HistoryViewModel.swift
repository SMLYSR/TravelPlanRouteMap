import Foundation
import Combine

/// 历史记录 ViewModel
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var plans: [TravelPlan] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: TravelPlanRepository
    
    init(repository: TravelPlanRepository = AppDependencies.shared.repository) {
        self.repository = repository
    }
    
    /// 加载所有历史记录
    func loadPlans() {
        isLoading = true
        plans = repository.getAllPlans()
        isLoading = false
    }
    
    /// 删除指定计划
    func deletePlan(_ plan: TravelPlan) {
        do {
            try repository.deletePlan(id: plan.id)
            plans.removeAll { $0.id == plan.id }
            HapticFeedback.light()
        } catch {
            // 提供用户友好的错误提示，不暴露技术细节
            errorMessage = "删除失败，请重试"
            HapticFeedback.error()
        }
    }
    
    /// 删除指定索引的计划
    func deletePlan(at indexSet: IndexSet) {
        for index in indexSet {
            let plan = plans[index]
            do {
                try repository.deletePlan(id: plan.id)
            } catch {
                // 提供用户友好的错误提示，不暴露技术细节
                errorMessage = "删除失败，请重试"
                HapticFeedback.error()
                return
            }
        }
        plans.remove(atOffsets: indexSet)
        HapticFeedback.light()
    }
    
    /// 获取最新计划
    func getLatestPlan() -> TravelPlan? {
        return repository.getLatestPlan()
    }
    
    /// 格式化日期
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
