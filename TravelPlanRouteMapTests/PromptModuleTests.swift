import XCTest
@testable import TravelPlanRouteMap

/// 提示词模块单元测试
final class PromptModuleTests: XCTestCase {
    var promptModule: PromptModule!
    
    override func setUp() {
        super.setUp()
        promptModule = PromptModule()
    }
    
    override func tearDown() {
        promptModule = nil
        super.tearDown()
    }
    
    // MARK: - 测试路线规划提示词生成
    
    func testRouteOptimizationPromptGeneration() {
        // Given
        let destination = "北京"
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        let travelMode = TravelMode.driving
        
        // When
        let prompt = promptModule.getRouteOptimizationPrompt(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        // Then
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("北京"))
        XCTAssertTrue(prompt.contains("故宫"))
        XCTAssertTrue(prompt.contains("天安门"))
        XCTAssertTrue(prompt.contains("自驾"))
        XCTAssertTrue(prompt.contains("JSON"))
    }
    
    func testRouteOptimizationPromptWithPublicTransport() {
        // Given
        let destination = "上海"
        let attractions = [
            Attraction(name: "外滩", coordinate: Coordinate(latitude: 31.2304, longitude: 121.4737)),
            Attraction(name: "东方明珠", coordinate: Coordinate(latitude: 31.2397, longitude: 121.4998))
        ]
        let travelMode = TravelMode.publicTransport
        
        // When
        let prompt = promptModule.getRouteOptimizationPrompt(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        // Then
        XCTAssertTrue(prompt.contains("公共交通"))
        XCTAssertTrue(prompt.contains("换乘"))
    }
    
    func testRouteOptimizationPromptWithWalking() {
        // Given
        let destination = "杭州"
        let attractions = [
            Attraction(name: "西湖", coordinate: Coordinate(latitude: 30.2590, longitude: 120.1388)),
            Attraction(name: "雷峰塔", coordinate: Coordinate(latitude: 30.2318, longitude: 120.1485))
        ]
        let travelMode = TravelMode.walking
        
        // When
        let prompt = promptModule.getRouteOptimizationPrompt(
            destination: destination,
            attractions: attractions,
            travelMode: travelMode
        )
        
        // Then
        XCTAssertTrue(prompt.contains("步行"))
    }
    
    // MARK: - 测试住宿推荐提示词生成
    
    func testAccommodationRecommendationPromptGeneration() {
        // Given
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975))
        ]
        let route = OptimizedRoute(
            orderedAttractions: attractions,
            routePath: attractions.compactMap { $0.coordinate }
        )
        let dayCount = 3
        let travelMode = TravelMode.driving
        
        // When
        let prompt = promptModule.getAccommodationRecommendationPrompt(
            route: route,
            dayCount: dayCount,
            travelMode: travelMode
        )
        
        // Then
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("故宫"))
        XCTAssertTrue(prompt.contains("3"))
        XCTAssertTrue(prompt.contains("3-5km"))
        XCTAssertTrue(prompt.contains("JSON"))
    }
    
    func testAccommodationPromptWithPublicTransport() {
        // Given
        let attractions = [
            Attraction(name: "景点1", coordinate: Coordinate(latitude: 39.9, longitude: 116.4))
        ]
        let route = OptimizedRoute(orderedAttractions: attractions, routePath: [])
        
        // When
        let prompt = promptModule.getAccommodationRecommendationPrompt(
            route: route,
            dayCount: 2,
            travelMode: .publicTransport
        )
        
        // Then
        XCTAssertTrue(prompt.contains("1-3km"))
    }
    
    // MARK: - 测试天数估算提示词生成
    
    func testDurationEstimationPromptGeneration() {
        // Given
        let attractions = [
            Attraction(name: "故宫", coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972)),
            Attraction(name: "天安门", coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975)),
            Attraction(name: "颐和园", coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755))
        ]
        let totalDistance = 25.5
        
        // When
        let prompt = promptModule.getDurationEstimationPrompt(
            attractions: attractions,
            totalDistance: totalDistance
        )
        
        // Then
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("故宫"))
        XCTAssertTrue(prompt.contains("天安门"))
        XCTAssertTrue(prompt.contains("颐和园"))
        XCTAssertTrue(prompt.contains("25.5"))
        XCTAssertTrue(prompt.contains("3"))  // 景点数量
        XCTAssertTrue(prompt.contains("JSON"))
    }
    
    // MARK: - 测试提示词非空（属性11验证）
    
    func testAllPromptsAreNonEmpty() {
        // Given
        let attractions = [
            Attraction(name: "景点", coordinate: Coordinate(latitude: 39.9, longitude: 116.4))
        ]
        let route = OptimizedRoute(orderedAttractions: attractions, routePath: [])
        
        // When/Then
        let routePrompt = promptModule.getRouteOptimizationPrompt(
            destination: "测试",
            attractions: attractions,
            travelMode: nil
        )
        XCTAssertFalse(routePrompt.isEmpty)
        
        let accommodationPrompt = promptModule.getAccommodationRecommendationPrompt(
            route: route,
            dayCount: 1,
            travelMode: nil
        )
        XCTAssertFalse(accommodationPrompt.isEmpty)
        
        let durationPrompt = promptModule.getDurationEstimationPrompt(
            attractions: attractions,
            totalDistance: 10.0
        )
        XCTAssertFalse(durationPrompt.isEmpty)
    }
}
