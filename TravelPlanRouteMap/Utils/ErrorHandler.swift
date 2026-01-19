import Foundation

/// 错误处理工具类
class ErrorHandler {
    
    /// 处理错误并返回用户友好的消息
    static func handle(_ error: Error) -> String {
        if let travelError = error as? TravelPlanError {
            return travelError.errorDescription ?? "未知错误"
        }
        
        // 处理网络错误
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "网络连接失败，请检查网络设置"
            case .timedOut:
                return "请求超时，请稍后重试"
            case .cannotFindHost, .cannotConnectToHost:
                return "无法连接到服务器，请稍后重试"
            default:
                return "网络错误：\(urlError.localizedDescription)"
            }
        }
        
        return error.localizedDescription
    }
    
    /// 判断错误是否可以重试
    static func canRetry(_ error: Error) -> Bool {
        if let travelError = error as? TravelPlanError {
            switch travelError {
            case .networkError, .aiPlanningTimeout, .mapLoadingFailed:
                return true
            case .aiPlanningFailed:
                return true
            default:
                return false
            }
        }
        
        if error is URLError {
            return true
        }
        
        return false
    }
    
    /// 获取重试建议
    static func getRetryAdvice(_ error: Error) -> String? {
        if let travelError = error as? TravelPlanError {
            switch travelError {
            case .networkError:
                return "请检查网络连接后重试"
            case .aiPlanningTimeout:
                return "服务器响应较慢，请稍后重试"
            case .mapLoadingFailed:
                return "地图服务暂时不可用，请稍后重试"
            case .aiPlanningFailed:
                return "规划服务出现问题，请重试"
            default:
                return nil
            }
        }
        return nil
    }
}
