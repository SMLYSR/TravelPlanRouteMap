import XCTest
@testable import TravelPlanRouteMap

/// 数据持久化属性测试
/// Feature: ai-travel-route-planner
final class DataPersistencePropertyTests: XCTestCase {
    var repository: LocalTravelPlanRepository!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "PropertyTestSuite")!
        testUserDefaults.removePersistentDomain(forName: "PropertyTestSuite")
        repository = LocalTravelPlanRepository(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "PropertyTestSuite")
        repository = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Property 2: 目的地保存往返一致性
    /// **Validates: Requirements 1.3**
    /// 对于任意有效的目的地字符串，提交后保存再读取应返回相同的目的地值
    func testDestinationRoundTripConsistency() throws {
        // Feature: ai-travel-route-planner, Property 2: 目的地保存往返一致性
        let testDestinations = [
            "北京", "上海", "广州", "深圳", "杭州",
            "成都", "西安", "南京", "武汉", "重庆",
            "Test City", "城市123", "北京市朝阳区"
        ]
        
        for destination in testDestinations {
            // Given
            let plan = createTestPlan(destination: destination)
            
            // When
            try repository.savePlan(plan)
            let retrieved = repository.getLatestPlan()
            
            // Then
            XCTAssertEqual(retrieved?.destination, destination,
                          "目的地 '\(destination)' 保存后读取应保持一致")
            
            // Cleanup
            try? repository.deletePlan(id: plan.id)
        }
    }
    
    // MARK: - Property 3: 出行方式保存一致性
    /// **Validates: Requirements 2.2**
    /// 对于任意出行方式选择，保存后读取应返回相同的出行方式
    func testTravelModeConsistency() throws {
        // Feature: ai-travel-route-planner, Property 3: 出行方式保存一致性
        let travelModes: [TravelMode?] = [.walking, .publicTransport, .driving, nil]
        
        for mode in travelModes {
            // Given
            let plan = createTestPlan(destination: "测试城市", travelMode: mode)
            
            // When
            try repository.savePlan(plan)
            let retrieved = repository.getLatestPlan()
            
            // Then
            XCTAssertEqual(retrieved?.travelMode, mode,
                          "出行方式 '\(String(describing: mode))' 保存后读取应保持一致")
            
            // Cleanup
            try? repository.deletePlan(id: plan.id)
        }
    }
    
    // MARK: - Property 12: 数据持久化往返一致性
    /// **Validates: Requirements 10.1**
    /// 对于任意旅行计划对象，保存到本地存储后再读取应返回等价的对象
    func testPersistenceRoundTripConsistency() throws {
        // Feature: ai-travel-route-planner, Property 12: 数据持久化往返一致性
        
        // 测试多种不同配置的计划
        for i in 1...20 {
            // Given - 生成随机计划
            let attractionCount = Int.random(in: 2...10)
            var attractions: [Attraction] = []
            for j in 1...attractionCount {
                attractions.append(
                    Attraction(
                        name: "景点\(i)-\(j)",
                        coordinate: Coordinate(
                            latitude: Double.random(in: 30...40),
                            longitude: Double.random(in: 110...120)
                        ),
                        address: "地址\(i)-\(j)"
                    )
                )
            }
            
            let route = OptimizedRoute(
                orderedAttractions: attractions,
                routePath: attractions.compactMap { $0.coordinate }
            )
            
            let recommendedDays = Int.random(in: 1...7)
            var accommodations: [AccommodationZone] = []
            if recommendedDays > 1 {
                for day in 1..<recommendedDays {
                    accommodations.append(
                        AccommodationZone(
                            name: "住宿区域\(day)",
                            center: Coordinate(
                                latitude: Double.random(in: 30...40),
                                longitude: Double.random(in: 110...120)
                            ),
                            radius: Double.random(in: 1000...5000),
                            dayNumber: day
                        )
                    )
                }
            }
            
            let plan = TravelPlan(
                destination: "城市\(i)",
                route: route,
                recommendedDays: recommendedDays,
                accommodations: accommodations,
                totalDistance: Double.random(in: 10...100),
                travelMode: TravelMode.allCases.randomElement()
            )
            
            // When
            try repository.savePlan(plan)
            let retrieved = repository.getLatestPlan()
            
            // Then
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved?.id, plan.id)
            XCTAssertEqual(retrieved?.destination, plan.destination)
            XCTAssertEqual(retrieved?.recommendedDays, plan.recommendedDays)
            XCTAssertEqual(retrieved?.totalDistance, plan.totalDistance)
            XCTAssertEqual(retrieved?.travelMode, plan.travelMode)
            XCTAssertEqual(retrieved?.route.attractionCount, plan.route.attractionCount)
            XCTAssertEqual(retrieved?.accommodations.count, plan.accommodations.count)
            
            // Cleanup
            try? repository.deletePlan(id: plan.id)
        }
    }
    
    // MARK: - Property 13: 历史记录增长
    /// **Validates: Requirements 10.3**
    /// 对于任意初始历史记录列表，添加一个新的旅行计划后，历史记录数量应增加1
    func testHistoryRecordGrowth() throws {
        // Feature: ai-travel-route-planner, Property 13: 历史记录增长
        
        for iteration in 1...10 {
            // Given
            let initialCount = repository.getAllPlans().count
            let plan = createTestPlan(destination: "测试城市\(iteration)")
            
            // When
            try repository.savePlan(plan)
            
            // Then
            let newCount = repository.getAllPlans().count
            XCTAssertEqual(newCount, initialCount + 1,
                          "添加计划后，历史记录数量应增加1")
        }
    }
    
    // MARK: - Property 15: 历史记录删除
    /// **Validates: Requirements 10.5**
    /// 对于任意历史记录列表和其中的某个计划ID，删除该ID后，列表中不应再包含该ID的计划
    func testHistoryRecordDeletion() throws {
        // Feature: ai-travel-route-planner, Property 15: 历史记录删除
        
        // 先添加一些计划
        var planIds: [String] = []
        for i in 1...5 {
            let plan = createTestPlan(destination: "城市\(i)")
            try repository.savePlan(plan)
            planIds.append(plan.id)
        }
        
        // 随机删除并验证
        for id in planIds.shuffled() {
            // When
            try repository.deletePlan(id: id)
            
            // Then
            let remainingPlans = repository.getAllPlans()
            let containsDeletedId = remainingPlans.contains { $0.id == id }
            XCTAssertFalse(containsDeletedId,
                          "删除后，列表中不应再包含该ID的计划")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlan(destination: String, travelMode: TravelMode? = .driving) -> TravelPlan {
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
            travelMode: travelMode
        )
    }
}
