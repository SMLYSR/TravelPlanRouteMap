import XCTest
@testable import TravelPlanRouteMap

/// ResultViewModel 单元测试
@MainActor
final class ResultViewModelTests: XCTestCase {
    
    var viewModel: ResultViewModel!
    var mockPlanningService: MockRoutePlanningService!
    var mockRepository: MockTravelPlanRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPlanningService = MockRoutePlanningService()
        mockRepository = MockTravelPlanRepository()
        viewModel = ResultViewModel(
            planningService: mockPlanningService,
            repository: mockRepository
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockPlanningService = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - 路线规划成功场景测试
    
    /// 测试路线规划成功
    func testPlanRouteSuccess() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 3)
        let travelMode = TravelMode.driving
        
        // 配置 Mock 返回成功结果
        mockPlanningService.shouldSucceed = true
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        // Then
        XCTAssertNotNil(viewModel.travelPlan, "规划成功后应有结果")
        XCTAssertNil(viewModel.errorMessage, "规划成功后不应有错误消息")
        XCTAssertFalse(viewModel.isLoading, "规划完成后加载状态应为 false")
    }
    
    /// 测试规划结果包含正确的目的地
    func testPlanRouteContainsCorrectDestination() async {
        // Given
        let destination = "上海"
        let attractions = createTestAttractions(count: 2)
        mockPlanningService.shouldSucceed = true
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .publicTransport
        )
        
        // Then
        XCTAssertEqual(viewModel.travelPlan?.destination, destination, "结果应包含正确的目的地")
    }
    
    // MARK: - 路线规划失败场景测试
    
    /// 测试路线规划失败
    func testPlanRouteFailure() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        
        // 配置 Mock 返回失败
        mockPlanningService.shouldSucceed = false
        mockPlanningService.errorToThrow = TravelPlanError.aiPlanningFailed
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertNil(viewModel.travelPlan, "规划失败后不应有结果")
        XCTAssertNotNil(viewModel.errorMessage, "规划失败后应有错误消息")
        XCTAssertFalse(viewModel.isLoading, "规划完成后加载状态应为 false")
    }
    
    /// 测试网络错误处理
    func testPlanRouteNetworkError() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        
        mockPlanningService.shouldSucceed = false
        mockPlanningService.errorToThrow = TravelPlanError.networkError
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .walking
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "网络错误应显示错误消息")
        XCTAssertTrue(viewModel.errorMessage?.contains("网络") ?? false, "错误消息应包含网络相关信息")
    }
    
    // MARK: - 加载状态测试
    
    /// 测试加载状态管理
    func testLoadingStateManagement() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        mockPlanningService.shouldSucceed = true
        mockPlanningService.delay = 0.1 // 添加延迟以观察加载状态
        
        // 初始状态
        XCTAssertFalse(viewModel.isLoading, "初始加载状态应为 false")
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "规划完成后加载状态应为 false")
    }
    
    // MARK: - 错误处理测试
    
    /// 测试 AI 规划超时错误
    func testAIPlanningTimeoutError() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        
        mockPlanningService.shouldSucceed = false
        mockPlanningService.errorToThrow = TravelPlanError.aiPlanningTimeout
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "超时错误应显示错误消息")
    }
    
    /// 测试无效输入错误
    func testInvalidInputError() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 1) // 少于 2 个景点
        
        mockPlanningService.shouldSucceed = false
        mockPlanningService.errorToThrow = TravelPlanError.invalidInput("景点数量不足")
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "无效输入应显示错误消息")
    }
    
    // MARK: - 数据保存测试
    
    /// 测试规划结果自动保存
    func testPlanResultAutoSave() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 3)
        mockPlanningService.shouldSucceed = true
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertTrue(mockRepository.savePlanCalled, "规划成功后应自动保存")
    }
    
    /// 测试规划失败不保存
    func testPlanFailureNoSave() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        mockPlanningService.shouldSucceed = false
        mockPlanningService.errorToThrow = TravelPlanError.aiPlanningFailed
        
        // When
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertFalse(mockRepository.savePlanCalled, "规划失败后不应保存")
    }
    
    // MARK: - 清除结果测试
    
    /// 测试清除结果
    func testClearResult() async {
        // Given
        let destination = "北京"
        let attractions = createTestAttractions(count: 2)
        mockPlanningService.shouldSucceed = true
        
        await viewModel.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        XCTAssertNotNil(viewModel.travelPlan, "规划后应有结果")
        
        // When
        viewModel.clear()
        
        // Then
        XCTAssertNil(viewModel.travelPlan, "清除后结果应为 nil")
        XCTAssertNil(viewModel.errorMessage, "清除后错误消息应为 nil")
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

// MARK: - Mock 类

/// Mock 路线规划服务
class MockRoutePlanningService: RoutePlanningService {
    var shouldSucceed = true
    var errorToThrow: Error?
    var delay: TimeInterval = 0
    
    func planRoute(destination: String, attractions: [Attraction], travelMode: TravelMode?) async throws -> TravelPlan {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldSucceed {
            return TravelPlan(
                id: UUID(),
                destination: destination,
                attractions: attractions,
                travelMode: travelMode ?? .driving,
                optimizedRoute: OptimizedRoute(
                    orderedAttractions: attractions,
                    totalDistance: 10.5,
                    estimatedDuration: 120
                ),
                recommendedDays: 2,
                accommodationZones: [
                    AccommodationZone(
                        id: UUID(),
                        name: "测试住宿区",
                        center: Coordinate(latitude: 39.9, longitude: 116.4),
                        radius: 1000,
                        description: "测试描述"
                    )
                ],
                createdAt: Date()
            )
        } else {
            throw errorToThrow ?? TravelPlanError.aiPlanningFailed
        }
    }
}

/// Mock 旅行计划仓库
class MockTravelPlanRepository: TravelPlanRepository {
    var savePlanCalled = false
    var savedPlans: [TravelPlan] = []
    
    func savePlan(_ plan: TravelPlan) throws {
        savePlanCalled = true
        savedPlans.append(plan)
    }
    
    func getLatestPlan() throws -> TravelPlan? {
        return savedPlans.last
    }
    
    func getAllPlans() throws -> [TravelPlan] {
        return savedPlans
    }
    
    func deletePlan(id: UUID) throws {
        savedPlans.removeAll { $0.id == id }
    }
    
    func updatePlan(_ plan: TravelPlan) throws {
        if let index = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[index] = plan
        }
    }
}
