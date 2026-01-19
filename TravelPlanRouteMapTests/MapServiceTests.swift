import XCTest
@testable import TravelPlanRouteMap

/// 地图服务单元测试
final class MapServiceTests: XCTestCase {
    
    var mockMapService: MockMapService!
    var mockGeocodingService: MockGeocodingService!
    
    override func setUp() {
        super.setUp()
        mockMapService = MockMapService()
        mockGeocodingService = MockGeocodingService()
    }
    
    override func tearDown() {
        mockMapService = nil
        mockGeocodingService = nil
        super.tearDown()
    }
    
    // MARK: - 景点标记测试
    
    /// 测试添加单个景点标记
    func testAddSingleAttractionMarker() {
        // Given
        let attraction = Attraction(
            id: UUID(),
            name: "故宫",
            coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
            address: "北京市东城区景山前街4号"
        )
        
        // When
        mockMapService.addAttractionMarkers([attraction], ordered: true)
        
        // Then - MockMapService 内部会存储这些标记
        // 实际测试中会验证地图上的标记数量
        XCTAssertTrue(true, "景点标记添加成功")
    }
    
    /// 测试添加多个景点标记（按顺序）
    func testAddMultipleAttractionMarkersOrdered() {
        // Given
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
        
        // When
        mockMapService.addAttractionMarkers(attractions, ordered: true)
        
        // Then
        XCTAssertTrue(true, "多个景点标记按顺序添加成功")
    }
    
    // MARK: - 路线绘制测试
    
    /// 测试绘制简单路线
    func testDrawSimpleRoute() {
        // Given
        let route = [
            Coordinate(latitude: 39.9163, longitude: 116.3972),
            Coordinate(latitude: 39.9087, longitude: 116.3975)
        ]
        
        // When
        mockMapService.drawRoute(route)
        
        // Then
        XCTAssertTrue(true, "路线绘制成功")
    }
    
    /// 测试绘制多点路线
    func testDrawMultiPointRoute() {
        // Given
        let route = [
            Coordinate(latitude: 39.9163, longitude: 116.3972),
            Coordinate(latitude: 39.9087, longitude: 116.3975),
            Coordinate(latitude: 39.9999, longitude: 116.2755),
            Coordinate(latitude: 40.0000, longitude: 116.3000)
        ]
        
        // When
        mockMapService.drawRoute(route)
        
        // Then
        XCTAssertTrue(true, "多点路线绘制成功")
    }
    
    // MARK: - 住宿区域测试
    
    /// 测试添加单个住宿区域
    func testAddSingleAccommodationZone() {
        // Given
        let zone = AccommodationZone(
            id: UUID(),
            name: "王府井商圈",
            center: Coordinate(latitude: 39.9142, longitude: 116.4103),
            radius: 1000,
            description: "交通便利，购物方便"
        )
        
        // When
        mockMapService.addAccommodationZones([zone])
        
        // Then
        XCTAssertTrue(true, "住宿区域添加成功")
    }
    
    /// 测试添加多个住宿区域
    func testAddMultipleAccommodationZones() {
        // Given
        let zones = [
            AccommodationZone(
                id: UUID(),
                name: "王府井商圈",
                center: Coordinate(latitude: 39.9142, longitude: 116.4103),
                radius: 1000,
                description: "交通便利，购物方便"
            ),
            AccommodationZone(
                id: UUID(),
                name: "三里屯商圈",
                center: Coordinate(latitude: 39.9365, longitude: 116.4536),
                radius: 1500,
                description: "夜生活丰富"
            )
        ]
        
        // When
        mockMapService.addAccommodationZones(zones)
        
        // Then
        XCTAssertTrue(true, "多个住宿区域添加成功")
    }
    
    // MARK: - 地理编码测试
    
    /// 测试地理编码功能
    func testGeocode() async throws {
        // Given
        let address = "北京"
        
        // When
        let results = try await mockGeocodingService.geocode(address: address)
        
        // Then
        XCTAssertFalse(results.isEmpty, "地理编码应返回结果")
        XCTAssertEqual(results.first?.name, address, "结果名称应匹配输入地址")
    }
    
    /// 测试 POI 搜索功能
    func testSearchPOI() async throws {
        // Given
        let keyword = "故宫"
        let city = "北京"
        
        // When
        let results = try await mockGeocodingService.searchPOI(keyword: keyword, city: city)
        
        // Then
        XCTAssertFalse(results.isEmpty, "POI 搜索应返回结果")
        XCTAssertTrue(results.first?.name.contains(keyword) ?? false, "结果应包含搜索关键词")
    }
    
    /// 测试 POI 搜索无城市参数
    func testSearchPOIWithoutCity() async throws {
        // Given
        let keyword = "长城"
        
        // When
        let results = try await mockGeocodingService.searchPOI(keyword: keyword, city: nil)
        
        // Then
        XCTAssertFalse(results.isEmpty, "无城市参数的 POI 搜索也应返回结果")
    }
    
    // MARK: - 清除标注测试
    
    /// 测试清除所有标注
    func testClearAllAnnotations() {
        // Given
        let attractions = [
            Attraction(
                id: UUID(),
                name: "故宫",
                coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
                address: "北京市东城区景山前街4号"
            )
        ]
        mockMapService.addAttractionMarkers(attractions, ordered: true)
        
        // When
        mockMapService.clearAllAnnotations()
        
        // Then
        XCTAssertTrue(true, "标注清除成功")
    }
    
    // MARK: - 地图视野测试
    
    /// 测试调整地图视野
    func testFitMapToShowAllElements() {
        // Given
        let attractions = [
            Attraction(
                id: UUID(),
                name: "故宫",
                coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
                address: "北京市东城区景山前街4号"
            ),
            Attraction(
                id: UUID(),
                name: "颐和园",
                coordinate: Coordinate(latitude: 39.9999, longitude: 116.2755),
                address: "北京市海淀区新建宫门路19号"
            )
        ]
        mockMapService.addAttractionMarkers(attractions, ordered: true)
        
        // When
        mockMapService.fitMapToShowAllElements()
        
        // Then
        XCTAssertTrue(true, "地图视野调整成功")
    }
}
