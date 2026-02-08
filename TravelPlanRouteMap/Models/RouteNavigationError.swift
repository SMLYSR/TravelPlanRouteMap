import Foundation

/// 路径导航错误
/// 用于表示路径规划过程中可能发生的各种错误情况
enum RouteNavigationError: Error, LocalizedError {
    /// API初始化失败
    case apiNotInitialized
    
    /// 路径规划请求失败
    case routePlanningFailed(String)
    
    /// 无效的坐标
    case invalidCoordinate
    
    /// 请求超时
    case timeout
    
    /// 无可用路线
    case noRouteAvailable
    
    var errorDescription: String? {
        switch self {
        case .apiNotInitialized:
            return "路径规划服务未初始化"
        case .routePlanningFailed(let message):
            return "路径规划失败: \(message)"
        case .invalidCoordinate:
            return "无效的坐标"
        case .timeout:
            return "请求超时"
        case .noRouteAvailable:
            return "无可用路线"
        }
    }
}
