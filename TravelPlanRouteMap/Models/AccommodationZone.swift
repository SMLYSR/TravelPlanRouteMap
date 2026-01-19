import Foundation

/// 住宿区域
struct AccommodationZone: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let center: Coordinate
    let radius: Double // 单位：米
    let dayNumber: Int // 第几天的住宿
    
    init(id: String = UUID().uuidString, name: String, center: Coordinate, radius: Double, dayNumber: Int) {
        self.id = id
        self.name = name
        self.center = center
        self.radius = radius
        self.dayNumber = dayNumber
    }
}
