import Foundation

/// 优化后的路线
struct OptimizedRoute: Codable, Equatable {
    let orderedAttractions: [Attraction]
    let routePath: [Coordinate]
    
    var attractionCount: Int {
        orderedAttractions.count
    }
    
    init(orderedAttractions: [Attraction], routePath: [Coordinate]) {
        self.orderedAttractions = orderedAttractions
        self.routePath = routePath
    }
}
