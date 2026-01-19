import Foundation

/// 坐标结构体
struct Coordinate: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
