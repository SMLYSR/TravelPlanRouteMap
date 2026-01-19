import XCTest
@testable import TravelPlanRouteMap

/// 输入验证属性测试
/// Feature: ai-travel-route-planner
final class InputValidationPropertyTests: XCTestCase {
    
    // MARK: - Property 1: 输入验证一致性
    /// **Validates: Requirements 1.2, 3.2**
    /// 对于任意输入字符串，如果字符串仅包含空白字符或为空，则验证函数应拒绝该输入
    @MainActor
    func testInputValidationConsistency() async {
        // Feature: ai-travel-route-planner, Property 1: 输入验证一致性
        
        // 测试空字符串和空白字符串
        let invalidInputs = [
            "",
            " ",
            "  ",
            "\t",
            "\n",
            "   \t\n   ",
            "\r\n",
            "    "
        ]
        
        for input in invalidInputs {
            // Given
            let viewModel = DestinationViewModel(geocodingService: MockGeocodingService())
            viewModel.destination = input
            
            // When
            viewModel.validate()
            
            // Then
            XCTAssertFalse(viewModel.isValid,
                          "空白输入 '\(input.debugDescription)' 应该被拒绝")
        }
    }
    
    // MARK: - Property 4: 景点列表最小数量验证
    /// **Validates: Requirements 3.4**
    /// 对于任意景点列表，如果列表包含少于2个景点，则验证函数应拒绝该列表
    @MainActor
    func testAttractionListMinimumValidation() async {
        // Feature: ai-travel-route-planner, Property 4: 景点列表最小数量验证
        
        // 测试0个和1个景点的情况
        for count in 0...1 {
            // Given
            let viewModel = AttractionViewModel(
                geocodingService: MockGeocodingService(),
                destination: "北京"
            )
            
            // 添加指定数量的景点
            for i in 0..<count {
                let poi = POIResult(
                    name: "景点\(i)",
                    address: "地址\(i)",
                    coordinate: Coordinate(latitude: 39.9 + Double(i) * 0.01, longitude: 116.4),
                    type: "风景名胜"
                )
                viewModel.selectAttraction(poi)
            }
            
            // Then
            XCTAssertFalse(viewModel.canProceed(),
                          "少于2个景点时应该无法继续")
            XCTAssertNotNil(viewModel.validateAndGetError(),
                          "少于2个景点时应该返回错误消息")
        }
        
        // 测试2个及以上景点的情况
        for count in 2...10 {
            // Given
            let viewModel = AttractionViewModel(
                geocodingService: MockGeocodingService(),
                destination: "北京"
            )
            
            // 添加指定数量的景点
            for i in 0..<count {
                let poi = POIResult(
                    name: "景点\(i)",
                    address: "地址\(i)",
                    coordinate: Coordinate(latitude: 39.9 + Double(i) * 0.01, longitude: 116.4),
                    type: "风景名胜"
                )
                viewModel.selectAttraction(poi)
            }
            
            // Then
            XCTAssertTrue(viewModel.canProceed(),
                         "有\(count)个景点时应该可以继续")
            XCTAssertNil(viewModel.validateAndGetError(),
                        "有\(count)个景点时不应该返回错误消息")
        }
    }
    
    // MARK: - Property 16: 无效输入错误消息
    /// **Validates: Requirements 11.4**
    /// 对于任意无效输入，系统应返回非空的错误消息字符串
    func testInvalidInputErrorMessages() {
        // Feature: ai-travel-route-planner, Property 16: 无效输入错误消息
        
        let errors: [TravelPlanError] = [
            .invalidDestination,
            .invalidAttractionName,
            .insufficientAttractions,
            .tooManyAttractions,
            .networkError,
            .geocodingFailed("测试景点"),
            .aiPlanningFailed("测试原因"),
            .aiPlanningTimeout,
            .mapLoadingFailed,
            .persistenceError("测试原因")
        ]
        
        for error in errors {
            // When
            let message = error.errorDescription
            
            // Then
            XCTAssertNotNil(message, "错误 \(error) 应该有错误消息")
            XCTAssertFalse(message!.isEmpty, "错误 \(error) 的消息不应为空")
            XCTAssertGreaterThan(message!.count, 0, "错误消息应该有实际内容")
        }
    }
    
    // MARK: - Property 18: POI搜索结果有效性
    /// **Validates: Requirements 1.5, 3.6**
    /// 对于任意POI搜索结果，每个结果应包含名称、地址和有效的坐标信息
    func testPOISearchResultValidity() async throws {
        // Feature: ai-travel-route-planner, Property 18: POI搜索结果有效性
        
        let geocodingService = MockGeocodingService()
        let testKeywords = ["故宫", "天安门", "颐和园", "长城", "西湖"]
        
        for keyword in testKeywords {
            // When
            let results = try await geocodingService.searchPOI(keyword: keyword, city: "北京")
            
            // Then
            for result in results {
                XCTAssertFalse(result.name.isEmpty, "POI名称不应为空")
                XCTAssertFalse(result.address.isEmpty, "POI地址不应为空")
                XCTAssertGreaterThanOrEqual(result.coordinate.latitude, -90, "纬度应在有效范围内")
                XCTAssertLessThanOrEqual(result.coordinate.latitude, 90, "纬度应在有效范围内")
                XCTAssertGreaterThanOrEqual(result.coordinate.longitude, -180, "经度应在有效范围内")
                XCTAssertLessThanOrEqual(result.coordinate.longitude, 180, "经度应在有效范围内")
            }
        }
    }
}
