import Foundation

/// 地理编码结果
struct GeocodingResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let city: String
    
    init(id: String = UUID().uuidString, name: String, address: String, coordinate: Coordinate, city: String) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.city = city
    }
}

/// POI搜索结果
struct POIResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let type: String
    
    init(id: String = UUID().uuidString, name: String, address: String, coordinate: Coordinate, type: String) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.type = type
    }
}
