import XCTest
@testable import TravelPlanRouteMap

/// AI Agent 单元测试（使用 Mock）
final class AIAgentTests: XCTestCase {
    var mockAgent: MockAIAgent!
    
    override func setUp() {
        super.setUp()
        mockAgent = MockAIAgent()
    }
    
    override func tearDown() {
        mockAgent = nil
        super.tearDown()
    }
    
    // MARK: - 测试路线优化
    
    func testOptimizeRoute() async throws {
        // Given
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975)),
            Attraction(name: "颐和园", coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755))
        ]
        
        // When
        let route = try await mockAgent.optimizeRoute(
            attractions: attractions,
            travelMode: .driving,
            prompt: "测试提示词"
        )
        
        // Then
        XCTAssertEqual(route.orderedAttractions.count, 3)
        XCTAssertFalse(route.routePath.isEmpty)
    }
    
    // MARK: - 测试住宿推荐
    
    func testRecommendAccommodations() async throws {
        // Given
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        let route = OptimizedRoute(
            orderedAttractions: attractions,
            routePath: attractions.compactMap { $0.coordinate }
        )
        
        // When
        let accommodations = try await mockAgent.recommendAccommodations(
            route: route,
            dayCount: 3,
            prompt: "测试提示词"
        )
        
        // Then
        XCTAssertEqual(accommodations.count, 2) // dayCount - 1
        for zone in accommodations {
            XCTAssertGreaterThan(zone.radius, 0)
            XCTAssertGreaterThan(zone.dayNumber, 0)
        }
    }
    
    // MARK: - 测试天数估算
    
    func testEstimateDuration() async throws {
        // Given
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        
        // When
        let days = try await mockAgent.estimateDuration(
            attractions: attractions,
            totalDistance: 10.0,
            prompt: "测试提示词"
        )
        
        // Then
        XCTAssertGreaterThanOrEqual(days, 1)
    }
    
    // MARK: - 测试不同景点数量的天数估算
    
    func testEstimateDurationWithDifferentAttractionCounts() async throws {
        // Given - 2个景点
        let attractions2 = [
            Attraction(name: "景点1", coordinate: Coordinate(latitude: 39.9, longitude: 116.4)),
            Attraction(name: "景点2", coordinate: Coordinate(latitude: 39.8, longitude: 116.3))
        ]
        
        // Given - 6个景点
        var attractions6: [Attraction] = []
        for i in 1...6 {
            attractions6.append(
                Attraction(
                    name: "景点\(i)",
                    coordinate: Coordinate(latitude: 39.9 + Double(i) * 0.01, longitude: 116.4)
                )
            )
        }
        
        // When
        let days2 = try await mockAgent.estimateDuration(
            attractions: attractions2,
            totalDistance: 5.0,
            prompt: "测试"
        )
        
        let days6 = try await mockAgent.estimateDuration(
            attractions: attractions6,
            totalDistance: 30.0,
            prompt: "测试"
        )
        
        // Then
        XCTAssertGreaterThanOrEqual(days2, 1)
        XCTAssertGreaterThanOrEqual(days6, days2)
    }
    
    // MARK: - 测试路线优化保持所有景点
    
    func testOptimizeRoutePreservesAllAttractions() async throws {
        // Given
        let attractions = [
            Attraction(id: "1", name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(id: "2", name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975)),
            Attraction(id: "3", name: "颐和园", coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755)),
            Attraction(id: "4", name: "长城", coordinate: Coordinate(latitude: 40.4319, longitude: 116.5704))
        ]
        
        // When
        let route = try await mockAgent.optimizeRoute(
            attractions: attractions,
            travelMode: .driving,
            prompt: "测试"
        )
        
        // Then - 验证属性5：路线规划返回有效排列
        XCTAssertEqual(route.orderedAttractions.count, attractions.count)
        
        let originalIds = Set(attractions.map { $0.id })
        let resultIds = Set(route.orderedAttractions.map { $0.id })
        XCTAssertEqual(originalIds, resultIds)
    }
}
