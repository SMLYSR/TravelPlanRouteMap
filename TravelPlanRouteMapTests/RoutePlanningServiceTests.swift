import XCTest
@testable import TravelPlanRouteMap

/// 路线规划服务单元测试
final class RoutePlanningServiceTests: XCTestCase {
    var service: DefaultRoutePlanningService!
    var mockAIAgent: MockAIAgent!
    var mockGeocoder: MockGeocodingService!
    var promptModule: PromptModule!
    
    override func setUp() {
        super.setUp()
        mockAIAgent = MockAIAgent()
        mockGeocoder = MockGeocodingService()
        promptModule = PromptModule()
        service = DefaultRoutePlanningService(
            aiAgent: mockAIAgent,
            promptProvider: promptModule,
            geocoder: mockGeocoder
        )
    }
    
    override func tearDown() {
        service = nil
        mockAIAgent = nil
        mockGeocoder = nil
        promptModule = nil
        super.tearDown()
    }
    
    // MARK: - 测试2个景点的规划
    
    func testPlanRouteWithTwoAttractions() async throws {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        
        // When
        let plan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertEqual(plan.destination, "北京")
        XCTAssertEqual(plan.route.attractionCount, 2)
        XCTAssertGreaterThanOrEqual(plan.recommendedDays, 1)
    }
    
    // MARK: - 测试10个景点的规划
    
    func testPlanRouteWithTenAttractions() async throws {
        // Given
        let destination = "北京"
        var attractions: [Attraction] = []
        for i in 1...10 {
            attractions.append(
                Attraction(
                    name: "景点\(i)",
                    coordinate: Coordinate(
                        latitude: 39.9 + Double(i) * 0.01,
                        longitude: 116.4 + Double(i) * 0.01
                    )
                )
            )
        }
        
        // When
        let plan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then
        XCTAssertEqual(plan.route.attractionCount, 10)
        XCTAssertGreaterThanOrEqual(plan.recommendedDays, 1)
    }
    
    // MARK: - 测试不同出行方式的规划
    
    func testPlanRouteWithDifferentTravelModes() async throws {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        
        // When - 自驾
        let drivingPlan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // When - 公共交通
        let publicTransportPlan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .publicTransport
        )
        
        // When - 步行
        let walkingPlan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .walking
        )
        
        // Then
        XCTAssertEqual(drivingPlan.travelMode, .driving)
        XCTAssertEqual(publicTransportPlan.travelMode, .publicTransport)
        XCTAssertEqual(walkingPlan.travelMode, .walking)
    }
    
    // MARK: - 测试规划失败场景 - 无效目的地
    
    func testPlanRouteWithInvalidDestination() async {
        // Given
        let destination = ""
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        
        // When/Then
        do {
            _ = try await service.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: .driving
            )
            XCTFail("应该抛出错误")
        } catch let error as TravelPlanError {
            XCTAssertEqual(error, .invalidDestination)
        } catch {
            XCTFail("错误类型不正确")
        }
    }
    
    // MARK: - 测试规划失败场景 - 景点不足
    
    func testPlanRouteWithInsufficientAttractions() async {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972))
        ]
        
        // When/Then
        do {
            _ = try await service.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: .driving
            )
            XCTFail("应该抛出错误")
        } catch let error as TravelPlanError {
            XCTAssertEqual(error, .insufficientAttractions)
        } catch {
            XCTFail("错误类型不正确")
        }
    }
    
    // MARK: - 测试规划失败场景 - 景点过多
    
    func testPlanRouteWithTooManyAttractions() async {
        // Given
        let destination = "北京"
        var attractions: [Attraction] = []
        for i in 1...11 {
            attractions.append(
                Attraction(
                    name: "景点\(i)",
                    coordinate: Coordinate(latitude: 39.9 + Double(i) * 0.01, longitude: 116.4)
                )
            )
        }
        
        // When/Then
        do {
            _ = try await service.planRoute(
                destination: destination,
                attractions: attractions,
                travelMode: .driving
            )
            XCTFail("应该抛出错误")
        } catch let error as TravelPlanError {
            XCTAssertEqual(error, .tooManyAttractions)
        } catch {
            XCTFail("错误类型不正确")
        }
    }
    
    // MARK: - 测试规划结果完整性
    
    func testPlanResultCompleteness() async throws {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975)),
            Attraction(name: "颐和园", coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755))
        ]
        
        // When
        let plan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then - 验证属性7：规划结果完整性
        XCTAssertFalse(plan.destination.isEmpty)
        XCTAssertFalse(plan.route.orderedAttractions.isEmpty)
        XCTAssertGreaterThanOrEqual(plan.recommendedDays, 1)
        XCTAssertGreaterThanOrEqual(plan.totalDistance, 0)
    }
    
    // MARK: - 测试推荐天数为正整数
    
    func testRecommendedDaysIsPositive() async throws {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        
        // When
        let plan = try await service.planRoute(
            destination: destination,
            attractions: attractions,
            travelMode: .driving
        )
        
        // Then - 验证属性8：推荐天数为正整数
        XCTAssertGreaterThanOrEqual(plan.recommendedDays, 1)
    }
}

// MARK: - TravelPlanError Equatable
extension TravelPlanError: Equatable {
    public static func == (lhs: TravelPlanError, rhs: TravelPlanError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidDestination, .invalidDestination),
             (.invalidAttractionName, .invalidAttractionName),
             (.insufficientAttractions, .insufficientAttractions),
             (.tooManyAttractions, .tooManyAttractions),
             (.networkError, .networkError),
             (.mapLoadingFailed, .mapLoadingFailed),
             (.aiPlanningTimeout, .aiPlanningTimeout):
            return true
        case (.geocodingFailed(let a), .geocodingFailed(let b)):
            return a == b
        case (.aiPlanningFailed(let a), .aiPlanningFailed(let b)):
            return a == b
        case (.persistenceError(let a), .persistenceError(let b)):
            return a == b
        default:
            return false
        }
    }
}
