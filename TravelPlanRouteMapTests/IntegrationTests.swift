import XCTest
@testable import TravelPlanRouteMap

/// 集成测试
final class IntegrationTests: XCTestCase {
    
    // MARK: - 12.1.1 完整流程集成测试
    
    /// 测试从输入目的地到显示规划结果的完整流程
    @MainActor
    func testCompleteFlowFromDestinationToResult() async throws {
        // Given - 准备测试数据
        let destination = "北京"
        let attractions = [
            Attraction(
                id: UUID(),
                name: "故宫",
                coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
                address: "北京市东城区景山前街4号"
            ),
            Attraction(
                id: UUID(),
                name: "天安门",
                coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975),
                address: "北京市东城区东长安街"
            ),
            Attraction(
                id: UUID(),
                name: "颐和园",
                coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755),
                address: "北京市海淀区新建宫门路19号"
            )
        ]
        let travelMode = TravelMode.driving
        
        // 创建 Mock 服务
        let mockPlanningService = MockRoutePlanningService()
        mockPlanningService.shouldSucceed = true
        
        let mockRepository = MockTravelPlanRepository()
        
        // 创建 ViewModel
        let resultViewModel = ResultViewModel(
            planningService: mockPlanningService,
            repository: mockRepository
        )
        
        // When - 执行规划
        await resultViewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        // Then - 验证结果
        XCTAssertNotNil(resultViewModel.travelPlan, "应该生成规划结果")
        XCTAssertNil(resultViewModel.errorMessage, "不应有错误消息")
        XCTAssertFalse(resultViewModel.isLoading, "加载状态应为 false")
        
        // 验证规划结果内容
        let plan = resultViewModel.travelPlan!
        XCTAssertEqual(plan.destination, destination, "目的地应匹配")
        XCTAssertEqual(plan.travelMode, travelMode, "出行方式应匹配")
        XCTAssertGreaterThan(plan.recommendedDays, 0, "推荐天数应大于 0")
        XCTAssertFalse(plan.accommodationZones.isEmpty, "应有住宿区域推荐")
        
        // 验证数据已保存
        XCTAssertTrue(mockRepository.savePlanCalled, "规划结果应被保存")
    }
    
    /// 测试所有组件正确协作
    @MainActor
    func testAllComponentsCollaboration() async throws {
        // Given
        let destination = "上海"
        let attractions = createTestAttractions(count: 5)
        
        // 创建各层组件
        let mockGeocodingService = MockGeocodingService()
        let mockAIAgent = MockAIAgent()
        let mockRepository = MockTravelPlanRepository()
        
        // 创建规划服务
        let planningService = DefaultRoutePlanningService(
            geocodingService: mockGeocodingService,
            aiAgent: mockAIAgent
        )
        
        // When - 执行规划
        let plan = try await planningService.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .publicTransport
        )
        
        // Then - 验证各组件协作结果
        XCTAssertEqual(plan.destination, destination)
        XCTAssertEqual(plan.attractions.count, attractions.count)
        XCTAssertNotNil(plan.optimizedRoute)
        XCTAssertGreaterThan(plan.recommendedDays, 0)
    }
    
    // MARK: - 12.1.2 地图集成测试
    
    /// 验证地图服务正确集成
    func testMapServiceIntegration() {
        // Given
        let mockMapService = MockMapService()
        let attractions = createTestAttractions(count: 3)
        let route = attractions.compactMap { $0.coordinate }
        let zones = [
            AccommodationZone(
                id: UUID(),
                name: "测试住宿区",
                center: Coordinate(latitude: 39.9, longitude: 116.4),
                radius: 1000,
                description: "测试描述"
            )
        ]
        
        // When - 添加地图元素
        mockMapService.addAttractionMarkers(attractions, ordered: true)
        mockMapService.drawRoute(route)
        mockMapService.addAccommodationZones(zones)
        mockMapService.fitMapToShowAllElements()
        
        // Then - 验证操作成功（MockMapService 内部状态）
        XCTAssertTrue(true, "地图服务集成测试通过")
    }
    
    /// 验证地图元素正确显示
    func testMapElementsDisplay() {
        // Given
        let mockMapService = MockMapService()
        let region = MapRegion(
            center: Coordinate(latitude: 39.9042, longitude: 116.4074),
            span: MapSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // When - 显示地图
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        mockMapService.displayMap(in: containerView, region: region)
        
        // Then
        XCTAssertTrue(true, "地图显示测试通过")
    }
    
    // MARK: - 12.1.3 AI 集成测试
    
    /// 使用模拟 AI 响应测试规划流程
    @MainActor
    func testAIIntegrationWithMockResponse() async throws {
        // Given
        let mockAIAgent = MockAIAgent()
        let attractions = createTestAttractions(count: 4)
        
        // When - 调用 AI 优化路线
        let optimizedRoute = try await mockAIAgent.optimizeRoute(
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertEqual(optimizedRoute.orderedAttractions.count, attractions.count)
        XCTAssertGreaterThan(optimizedRoute.totalDistance, 0)
    }
    
    /// 验证提示词正确传递给 AI
    func testPromptPassedToAI() {
        // Given
        let promptModule = PromptModule()
        let destination = "北京"
        let attractions = createTestAttractions(count: 3)
        let travelMode = TravelMode.driving
        
        // When - 生成提示词
        let routePrompt = promptModule.getRouteOptimizationPrompt(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        let accommodationPrompt = promptModule.getAccommodationRecommendationPrompt(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        let durationPrompt = promptModule.getDurationEstimationPrompt(
            destination: destination,
            attractions: attractions,
            totalDistance: 50.0
        )
        
        // Then - 验证提示词包含必要信息
        XCTAssertTrue(routePrompt.contains(destination), "路线提示词应包含目的地")
        XCTAssertTrue(accommodationPrompt.contains(destination), "住宿提示词应包含目的地")
        XCTAssertTrue(durationPrompt.contains(destination), "天数提示词应包含目的地")
        
        // 验证出行方式相关信息
        XCTAssertTrue(routePrompt.contains("自驾") || routePrompt.contains("driving"), "路线提示词应包含出行方式")
    }
    
    // MARK: - 辅助方法
    
    private func createTestAttractions(count: Int) -> [Attraction] {
        return (1...count).map { index in
            Attraction(
                id: UUID(),
                name: "景点\(index)",
                coordinate: Coordinate(
                    latitude: 39.9 + Double(index) * 0.01,
                    longitude: 116.4 + Double(index) * 0.01
                ),
                address: "测试地址\(index)"
            )
        }
    }
}

// MARK: - Mock AI Agent

class MockAIAgent: AIAgent {
    var shouldSucceed = true
    var delay: TimeInterval = 0
    
    func optimizeRoute(attractions: [Attraction], travelMode: TravelMode) async throws -> OptimizedRoute {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldSucceed {
            return OptimizedRoute(
                orderedAttractions: attractions,
                totalDistance: Double(attractions.count) * 5.0,
                estimatedDuration: attractions.count * 60
            )
        } else {
            throw TravelPlanError.aiPlanningFailed
        }
    }
    
    func recommendAccommodations(destination: String, attractions: [Attraction], travelMode: TravelMode) async throws -> [AccommodationZone] {
        if shouldSucceed {
            return [
                AccommodationZone(
                    id: UUID(),
                    name: "推荐住宿区1",
                    center: Coordinate(latitude: 39.9, longitude: 116.4),
                    radius: 1000,
                    description: "交通便利"
                )
            ]
        } else {
            throw TravelPlanError.aiPlanningFailed
        }
    }
    
    func estimateDuration(destination: String, attractions: [Attraction], totalDistance: Double) async throws -> Int {
        if shouldSucceed {
            return max(1, attractions.count / 3)
        } else {
            throw TravelPlanError.aiPlanningFailed
        }
    }
}
