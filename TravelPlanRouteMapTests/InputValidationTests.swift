import XCTest
@testable import TravelPlanRouteMap

/// 输入验证单元测试
final class InputValidationTests: XCTestCase {
    
    // MARK: - 目的地验证测试
    
    @MainActor
    func testEmptyDestinationIsInvalid() async {
        // Given
        let viewModel = DestinationViewModel(geocodingService: MockGeocodingService())
        viewModel.destination = ""
        
        // When
        viewModel.validate()
        
        // Then
        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testWhitespaceDestinationIsInvalid() async {
        // Given
        let viewModel = DestinationViewModel(geocodingService: MockGeocodingService())
        viewModel.destination = "   "
        
        // When
        viewModel.validate()
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    @MainActor
    func testDestinationWithoutSelectionIsInvalid() async {
        // Given
        let viewModel = DestinationViewModel(geocodingService: MockGeocodingService())
        viewModel.destination = "北京"
        viewModel.selectedDestination = nil
        
        // When
        viewModel.validate()
        
        // Then
        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testValidDestinationWithSelection() async {
        // Given
        let viewModel = DestinationViewModel(geocodingService: MockGeocodingService())
        let result = GeocodingResult(
            name: "北京",
            address: "北京市",
            coordinate: Coordinate(latitude: 39.9, longitude: 116.4),
            city: "北京"
        )
        
        // When
        viewModel.selectDestination(result)
        
        // Then
        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - 景点列表验证测试
    
    @MainActor
    func testAttractionListWithLessThanMinimum() async {
        // Given
        let viewModel = AttractionViewModel(
            geocodingService: MockGeocodingService(),
            destination: "北京"
        )
        
        // When - 只添加1个景点
        let poi = POIResult(
            name: "故宫",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
            type: "风景名胜"
        )
        viewModel.selectAttraction(poi)
        
        // Then
        XCTAssertFalse(viewModel.canProceed())
        XCTAssertNotNil(viewModel.validateAndGetError())
    }
    
    @MainActor
    func testAttractionListWithMinimum() async {
        // Given
        let viewModel = AttractionViewModel(
            geocodingService: MockGeocodingService(),
            destination: "北京"
        )
        
        // When - 添加2个景点
        let poi1 = POIResult(
            name: "故宫",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
            type: "风景名胜"
        )
        let poi2 = POIResult(
            name: "天安门",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975),
            type: "风景名胜"
        )
        viewModel.selectAttraction(poi1)
        viewModel.selectAttraction(poi2)
        
        // Then
        XCTAssertTrue(viewModel.canProceed())
        XCTAssertNil(viewModel.validateAndGetError())
    }
    
    @MainActor
    func testAttractionListExceedsMaximum() async {
        // Given
        let viewModel = AttractionViewModel(
            geocodingService: MockGeocodingService(),
            destination: "北京"
        )
        
        // When - 添加10个景点
        for i in 1...10 {
            let poi = POIResult(
                name: "景点\(i)",
                address: "地址\(i)",
                coordinate: Coordinate(latitude: 39.9 + Double(i) * 0.01, longitude: 116.4),
                type: "风景名胜"
            )
            viewModel.selectAttraction(poi)
        }
        
        // Then - 尝试添加第11个
        let poi11 = POIResult(
            name: "景点11",
            address: "地址11",
            coordinate: Coordinate(latitude: 40.0, longitude: 116.4),
            type: "风景名胜"
        )
        viewModel.selectAttraction(poi11)
        
        XCTAssertEqual(viewModel.attractions.count, 10)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testRemoveAttraction() async {
        // Given
        let viewModel = AttractionViewModel(
            geocodingService: MockGeocodingService(),
            destination: "北京"
        )
        let poi1 = POIResult(
            name: "故宫",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
            type: "风景名胜"
        )
        let poi2 = POIResult(
            name: "天安门",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975),
            type: "风景名胜"
        )
        viewModel.selectAttraction(poi1)
        viewModel.selectAttraction(poi2)
        
        // When
        viewModel.removeAttraction(at: 0)
        
        // Then
        XCTAssertEqual(viewModel.attractions.count, 1)
        XCTAssertEqual(viewModel.attractions.first?.name, "天安门")
    }
    
    @MainActor
    func testDuplicateAttractionNotAllowed() async {
        // Given
        let viewModel = AttractionViewModel(
            geocodingService: MockGeocodingService(),
            destination: "北京"
        )
        let poi = POIResult(
            name: "故宫",
            address: "北京市东城区",
            coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
            type: "风景名胜"
        )
        
        // When
        viewModel.selectAttraction(poi)
        viewModel.selectAttraction(poi)
        
        // Then
        XCTAssertEqual(viewModel.attractions.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
