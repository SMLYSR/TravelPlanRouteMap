import Foundation

/// 景点结构体
struct Attraction: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    var coordinate: Coordinate?
    var address: String?
    
    init(id: String = UUID().uuidString, name: String, coordinate: Coordinate? = nil, address: String? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
}
