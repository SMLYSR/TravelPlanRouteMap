import Foundation
import os.log

/// 高德地图错误处理器
/// 统一处理高德SDK错误，提供用户友好的错误提示和详细的日志记录
struct AMapErrorHandler {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TravelPlanRouteMap",
        category: "AMapService"
    )
    
    /// 将高德SDK错误转换为用户友好的提示
    /// - Parameter error: 高德SDK返回的错误
    /// - Returns: 用户友好的错误提示文本
    static func getUserMessage(from error: Error) -> String {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        // 记录详细错误日志
        logger.error("AMap SDK Error: code=\(errorCode), domain=\(nsError.domain), description=\(nsError.localizedDescription)")
        
        // 返回用户友好提示
        switch errorCode {
        case 1800...1899:
            // 客户端错误
            return "无法加载位置信息，请检查网络连接"
        case 2000...2999:
            // 请求参数错误
            return "位置信息加载失败，请重试"
        case 3000...3999:
            // 引擎返回错误
            return "位置服务暂时不可用，请稍后重试"
        case 4000...4999:
            // 协议解析错误
            return "数据加载失败，请重试"
        default:
            // 其他错误（5000+）
            return "服务暂时不可用，请稍后重试"
        }
    }
    
    /// 记录错误详情（用于开发调试）
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误发生的上下文信息
    static func logError(_ error: Error, context: String) {
        let nsError = error as NSError
        logger.error("""
            Context: \(context)
            Error Code: \(nsError.code)
            Domain: \(nsError.domain)
            Description: \(nsError.localizedDescription)
            User Info: \(nsError.userInfo)
            """)
    }
}
