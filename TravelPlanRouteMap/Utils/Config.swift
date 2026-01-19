import Foundation

/// 应用配置
enum Config {
    /// OpenAI API Key
    /// 注意：在生产环境中，应该使用更安全的方式存储 API Key
    static var openAIKey: String {
        // 优先从环境变量读取
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        // 从 UserDefaults 读取
        if let key = UserDefaults.standard.string(forKey: "openai_api_key") {
            return key
        }
        // 返回空字符串（需要用户配置）
        return ""
    }
    
    /// 设置 OpenAI API Key
    static func setOpenAIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    /// 高德地图 API Key
    static var amapKey: String {
        // 优先从环境变量读取
        if let key = ProcessInfo.processInfo.environment["AMAP_API_KEY"] {
            return key
        }
        // 从 UserDefaults 读取
        if let key = UserDefaults.standard.string(forKey: "amap_api_key") {
            return key
        }
        // 返回空字符串（需要用户配置）
        return ""
    }
    
    /// 设置高德地图 API Key
    static func setAmapKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "amap_api_key")
    }
    
    /// AI 请求超时时间（秒）
    static let aiTimeout: TimeInterval = 30
    
    /// 最大景点数量
    static let maxAttractions = 10
    
    /// 最小景点数量
    static let minAttractions = 2
}
