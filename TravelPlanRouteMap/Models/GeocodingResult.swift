import Foundation

/// 地理编码结果
struct GeocodingResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let city: String
    let citycode: String?  // 城市代码,用于公交路线规划
    
    init(id: String = UUID().uuidString, name: String, address: String, coordinate: Coordinate, city: String, citycode: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.city = city
        self.citycode = citycode
    }
}

/// POI搜索结果
struct POIResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let type: String
    let citycode: String?  // 城市代码,用于公交路线规划
    
    init(id: String = UUID().uuidString, name: String, address: String, coordinate: Coordinate, type: String, citycode: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.type = type
        self.citycode = citycode
    }
}
