import Foundation

/// 优化后的路线
struct OptimizedRoute: Codable, Equatable {
    let orderedAttractions: [Attraction]
    let routePath: [Coordinate]
    
    /// 导航路径（可选）- 包含实际道路级别的路线信息
    /// 当路径规划服务成功时，此属性包含详细的导航路径
    /// 当为nil时，使用routePath作为降级显示
    /// 需求: 4.2
    let navigationPath: NavigationPath?
    
    var attractionCount: Int {
        orderedAttractions.count
    }
    
    init(orderedAttractions: [Attraction], routePath: [Coordinate], navigationPath: NavigationPath? = nil) {
        self.orderedAttractions = orderedAttractions
        self.routePath = routePath
        self.navigationPath = navigationPath
    }
}
