import Foundation

/// 地理编码服务协议
protocol GeocodingService {
    /// 地理编码：地址转坐标
    func geocode(address: String) async throws -> [GeocodingResult]
    
    /// POI搜索：模糊搜索
    func searchPOI(keyword: String, city: String?) async throws -> [POIResult]
}

/// 模拟地理编码服务（用于开发和测试）
class MockGeocodingService: GeocodingService {
    func geocode(address: String) async throws -> [GeocodingResult] {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 返回模拟数据
        return [
            GeocodingResult(
                name: address,
                address: "\(address)市中心",
                coordinate: Coordinate(latitude: 39.9042, longitude: 116.4074),
                city: address
            )
        ]
    }
    
    func searchPOI(keyword: String, city: String?) async throws -> [POIResult] {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 返回模拟数据
        let mockPOIs = [
            POIResult(
                name: "\(keyword)景点1",
                address: "\(city ?? "")市\(keyword)路1号",
                coordinate: Coordinate(latitude: 39.9042 + Double.random(in: -0.1...0.1), longitude: 116.4074 + Double.random(in: -0.1...0.1)),
                type: "风景名胜"
            ),
            POIResult(
                name: "\(keyword)景点2",
                address: "\(city ?? "")市\(keyword)路2号",
                coordinate: Coordinate(latitude: 39.9042 + Double.random(in: -0.1...0.1), longitude: 116.4074 + Double.random(in: -0.1...0.1)),
                type: "风景名胜"
            ),
            POIResult(
                name: "\(keyword)景点3",
                address: "\(city ?? "")市\(keyword)路3号",
                coordinate: Coordinate(latitude: 39.9042 + Double.random(in: -0.1...0.1), longitude: 116.4074 + Double.random(in: -0.1...0.1)),
                type: "风景名胜"
            )
        ]
        
        return mockPOIs
    }
}
