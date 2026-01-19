import XCTest
@testable import TravelPlanRouteMap

/// 数据持久化单元测试
final class TravelPlanRepositoryTests: XCTestCase {
    var repository: LocalTravelPlanRepository!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // 使用独立的 UserDefaults 进行测试
        testUserDefaults = UserDefaults(suiteName: "TestSuite")!
        testUserDefaults.removePersistentDomain(forName: "TestSuite")
        repository = LocalTravelPlanRepository(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "TestSuite")
        repository = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - 测试保存单个计划
    
    func testSaveSinglePlan() throws {
        // Given
        let plan = createTestPlan(destination: "北京")
        
        // When
        try repository.savePlan(plan)
        
        // Then
        let plans = repository.getAllPlans()
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.destination, "北京")
    }
    
    // MARK: - 测试保存多个计划
    
    func testSaveMultiplePlans() throws {
        // Given
        let plan1 = createTestPlan(destination: "北京")
        let plan2 = createTestPlan(destination: "上海")
        let plan3 = createTestPlan(destination: "广州")
        
        // When
        try repository.savePlan(plan1)
        try repository.savePlan(plan2)
        try repository.savePlan(plan3)
        
        // Then
        let plans = repository.getAllPlans()
        XCTAssertEqual(plans.count, 3)
        // 最新的计划应该在最前面
        XCTAssertEqual(plans[0].destination, "广州")
        XCTAssertEqual(plans[1].destination, "上海")
        XCTAssertEqual(plans[2].destination, "北京")
    }
    
    // MARK: - 测试获取最新计划
    
    func testGetLatestPlan() throws {
        // Given
        let plan1 = createTestPlan(destination: "北京")
        let plan2 = createTestPlan(destination: "上海")
        
        // When
        try repository.savePlan(plan1)
        try repository.savePlan(plan2)
        
        // Then
        let latest = repository.getLatestPlan()
        XCTAssertNotNil(latest)
        XCTAssertEqual(latest?.destination, "上海")
    }
    
    // MARK: - 测试删除计划
    
    func testDeletePlan() throws {
        // Given
        let plan1 = createTestPlan(destination: "北京")
        let plan2 = createTestPlan(destination: "上海")
        try repository.savePlan(plan1)
        try repository.savePlan(plan2)
        
        // When
        try repository.deletePlan(id: plan1.id)
        
        // Then
        let plans = repository.getAllPlans()
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.destination, "上海")
    }
    
    // MARK: - 测试删除不存在的计划
    
    func testDeleteNonExistentPlan() {
        // Given
        let nonExistentId = "non-existent-id"
        
        // When/Then
        XCTAssertThrowsError(try repository.deletePlan(id: nonExistentId)) { error in
            XCTAssertTrue(error is TravelPlanError)
        }
    }
    
    // MARK: - 测试更新计划
    
    func testUpdatePlan() throws {
        // Given
        var plan = createTestPlan(destination: "北京")
        try repository.savePlan(plan)
        
        // When
        let updatedPlan = TravelPlan(
            id: plan.id,
            destination: "北京（已更新）",
            route: plan.route,
            recommendedDays: 5,
            accommodations: plan.accommodations,
            totalDistance: plan.totalDistance,
            createdAt: plan.createdAt,
            travelMode: plan.travelMode
        )
        try repository.updatePlan(updatedPlan)
        
        // Then
        let retrieved = repository.getLatestPlan()
        XCTAssertEqual(retrieved?.destination, "北京（已更新）")
        XCTAssertEqual(retrieved?.recommendedDays, 5)
    }
    
    // MARK: - 测试读取空列表
    
    func testGetAllPlansWhenEmpty() {
        // When
        let plans = repository.getAllPlans()
        
        // Then
        XCTAssertTrue(plans.isEmpty)
    }
    
    // MARK: - 测试获取最新计划（空列表）
    
    func testGetLatestPlanWhenEmpty() {
        // When
        let latest = repository.getLatestPlan()
        
        // Then
        XCTAssertNil(latest)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlan(destination: String) -> TravelPlan {
        let attractions = [
            Attraction(name: "景点1", coordinate: Coordinate(latitude: 39.9, longitude: 116.4)),
            Attraction(name: "景点2", coordinate: Coordinate(latitude: 39.8, longitude: 116.3))
        ]
        
        let route = OptimizedRoute(
            orderedAttractions: attractions,
            routePath: attractions.compactMap { $0.coordinate }
        )
        
        return TravelPlan(
            destination: destination,
            route: route,
            recommendedDays: 2,
            accommodations: [],
            totalDistance: 10.5,
            travelMode: .driving
        )
    }
}
