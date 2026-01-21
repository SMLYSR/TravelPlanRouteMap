import Foundation

/// 导航路径 - 包含所有路线段的完整路径
/// 需求: 4.2, 2.3
struct NavigationPath: Codable, Equatable {
    /// 所有路线段（按顺序）
    let segments: [RouteSegment]
    
    /// 出行方式
    let travelMode: TravelMode
    
    /// 获取所有路径坐标点（用于地图绘制）
    /// 合并所有路线段的坐标点，跳过相邻路线段的重复连接点
    var allCoordinates: [Coordinate] {
        var coordinates: [Coordinate] = []
        for (index, segment) in segments.enumerated() {
            if index == 0 {
                coordinates.append(contentsOf: segment.pathCoordinates)
            } else {
                // 跳过第一个点（与上一段的终点重复）
                coordinates.append(contentsOf: segment.pathCoordinates.dropFirst())
            }
        }
        return coordinates
    }
    
    /// 总距离（米）
    var totalDistance: Int {
        segments.compactMap { $0.distance }.reduce(0, +)
    }
    
    /// 总时间（秒）
    var totalDuration: Int {
        segments.compactMap { $0.duration }.reduce(0, +)
    }
    
    /// 是否包含降级路线段
    var hasFallbackSegments: Bool {
        segments.contains { $0.isFallback }
    }
    
    /// 降级路线段数量
    var fallbackSegmentCount: Int {
        segments.filter { $0.isFallback }.count
    }
}
