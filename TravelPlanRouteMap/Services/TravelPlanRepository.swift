import Foundation

/// 旅行计划仓库协议
protocol TravelPlanRepository {
    /// 保存旅行计划
    func savePlan(_ plan: TravelPlan) throws
    
    /// 获取最新的旅行计划
    func getLatestPlan() -> TravelPlan?
    
    /// 获取所有旅行计划
    func getAllPlans() -> [TravelPlan]
    
    /// 删除指定ID的旅行计划
    func deletePlan(id: String) throws
    
    /// 更新旅行计划
    func updatePlan(_ plan: TravelPlan) throws
    
    /// 获取指定ID的旅行计划
    func getPlan(id: String) -> TravelPlan?
}

/// 本地旅行计划仓库实现
class LocalTravelPlanRepository: TravelPlanRepository {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let storageKey = "travel_plans"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// 保存新计划
    func savePlan(_ plan: TravelPlan) throws {
        var plans = getAllPlans()
        plans.insert(plan, at: 0)
        let allData = try encoder.encode(plans)
        userDefaults.set(allData, forKey: storageKey)
    }
    
    /// 获取最新计划
    func getLatestPlan() -> TravelPlan? {
        return getAllPlans().first
    }
    
    /// 获取所有计划
    func getAllPlans() -> [TravelPlan] {
        guard let data = userDefaults.data(forKey: storageKey),
              let plans = try? decoder.decode([TravelPlan].self, from: data) else {
            return []
        }
        return plans
    }
    
    /// 更新现有计划
    func updatePlan(_ plan: TravelPlan) throws {
        var plans = getAllPlans()
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
            let data = try encoder.encode(plans)
            userDefaults.set(data, forKey: storageKey)
        } else {
            throw TravelPlanError.planNotFound
        }
    }
    
    /// 获取指定ID的旅行计划
    func getPlan(id: String) -> TravelPlan? {
        return getAllPlans().first { $0.id == id }
    }
    
    /// 删除指定计划
    func deletePlan(id: String) throws {
        var plans = getAllPlans()
        let originalCount = plans.count
        plans.removeAll { $0.id == id }
        
        if plans.count == originalCount {
            throw TravelPlanError.persistenceError("计划不存在")
        }
        
        let data = try encoder.encode(plans)
        userDefaults.set(data, forKey: storageKey)
    }
    
    /// 清除所有计划（用于测试）
    func clearAll() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
