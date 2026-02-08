import Foundation

/// 路线段 - 表示两个相邻景点之间的导航路径
/// 需求: 4.1, 2.4
struct RouteSegment: Codable, Equatable {
    /// 起点坐标
    let origin: Coordinate
    
    /// 终点坐标
    let destination: Coordinate
    
    /// 路径坐标点序列（实际道路级别）
    let pathCoordinates: [Coordinate]
    
    /// 出行方式x
    let travelMode: TravelMode
    
    /// 预计距离（米）
    let distance: Int?
    
    /// 预计时间（秒）
    let duration: Int?
    
    /// 是否为降级路线（直线连接）
    let isFallback: Bool
    
    /// 创建降级路线段（直线连接）
    /// 当路径规划API失败时，使用此方法创建简单的直线连接作为降级方案
    /// - Parameters:
    ///   - origin: 起点坐标
    ///   - destination: 终点坐标
    ///   - travelMode: 出行方式
    /// - Returns: 降级路线段（仅包含起点和终点两个坐标点）
    static func fallback(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode
    ) -> RouteSegment {
        return RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: [origin, destination],
            travelMode: travelMode,
            distance: nil,
            duration: nil,
            isFallback: true
        )
    }
}
