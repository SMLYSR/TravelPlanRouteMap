import Foundation

/// 旅行计划错误类型
enum TravelPlanError: Error, LocalizedError {
    case invalidDestination
    case invalidAttractionName
    case insufficientAttractions
    case tooManyAttractions
    case networkError
    case geocodingFailed(String)
    case aiPlanningFailed(String)
    case aiPlanningTimeout
    case mapLoadingFailed
    case persistenceError(String)
    
    // 新增错误类型（任务 1.4）
    case aiServiceError
    case amapServiceError(code: Int, message: String)
    case planNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidDestination:
            return "请输入有效的目的地"
        case .invalidAttractionName:
            return "景点名称不能为空"
        case .insufficientAttractions:
            return "至少需要2个景点才能规划路线"
        case .tooManyAttractions:
            return "最多支持10个景点"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .geocodingFailed(let attraction):
            return "无法识别景点：\(attraction)"
        case .aiPlanningFailed(let reason):
            return "规划失败：\(reason)"
        case .aiPlanningTimeout:
            return "规划超时，请重试"
        case .mapLoadingFailed:
            return "地图加载失败，请稍后重试"
        case .persistenceError(let reason):
            return "数据保存失败：\(reason)"
        case .aiServiceError:
            return "AI服务暂时不可用，请稍后重试"
        case .amapServiceError(let code, let message):
            return "地图服务错误 (\(code)): \(message)"
        case .planNotFound:
            return "未找到指定的旅行计划"
        case .invalidData:
            return "数据格式错误"
        }
    }
}
