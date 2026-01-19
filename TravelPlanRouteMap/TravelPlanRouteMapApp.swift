import SwiftUI
// 注意：实际使用时需要导入高德地图 SDK
// import AMapFoundationKit

@main
struct TravelPlanRouteMapApp: App {
    
    init() {
        // 初始化应用配置
        setupAppearance()
        
        // 初始化高德地图服务
        setupAMapServices()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
    
    /// 配置高德地图服务
    private func setupAMapServices() {
        // 实际实现：
        // AMapServices.shared().apiKey = Config.amapKey
        // AMapServices.shared().enableHTTPS = true
        
        // 从 Info.plist 读取 API Key
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String,
           apiKey != "YOUR_AMAP_API_KEY_HERE" {
            print("高德地图 API Key 已配置")
            // AMapServices.shared().apiKey = apiKey
        } else {
            print("警告：请在 Info.plist 中配置有效的高德地图 API Key")
        }
    }
    
    /// 配置应用外观
    private func setupAppearance() {
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: AppColors.textUI]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // 配置 TabBar 外观
        UITabBar.appearance().backgroundColor = .white
    }
}
