import Foundation

/// 旅行计划
struct TravelPlan: Codable, Identifiable, Equatable {
    let id: String
    let destination: String
    let route: OptimizedRoute
    let recommendedDays: Int
    let accommodations: [AccommodationZone]
    let totalDistance: Double // 单位：公里
    let createdAt: Date
    let travelMode: TravelMode?
    let navigationPath: NavigationPath?  // 新增：实际导航路径（包含道路路线）
    
    init(
        id: String = UUID().uuidString,
        destination: String,
        route: OptimizedRoute,
        recommendedDays: Int,
        accommodations: [AccommodationZone],
        totalDistance: Double,
        createdAt: Date = Date(),
        travelMode: TravelMode? = nil,
        navigationPath: NavigationPath? = nil
    ) {
        self.id = id
        self.destination = destination
        self.route = route
        self.recommendedDays = recommendedDays
        self.accommodations = accommodations
        self.totalDistance = totalDistance
        self.createdAt = createdAt
        self.travelMode = travelMode
        self.navigationPath = navigationPath
    }
}
