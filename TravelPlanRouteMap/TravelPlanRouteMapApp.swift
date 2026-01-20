import SwiftUI
import AMapFoundationKit
import MAMapKit
import AMapSearchKit

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
        // ⚠️ 重要：必须先设置隐私政策合规，否则 SDK 功能无法使用
        // 参考：https://lbs.amap.com/news/sdkhgsy
        // 注意：这些是类方法，需要在各个 SDK 类上分别调用
        MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        MAMapView.updatePrivacyAgree(.didAgree)
        AMapSearchAPI.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
        
        // 从 Info.plist 读取 API Key
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String,
           !apiKey.isEmpty && apiKey != "YOUR_AMAP_API_KEY_HERE" {
            AMapServices.shared().apiKey = apiKey
            AMapServices.shared().enableHTTPS = true
            print("✅ 高德地图 API Key 已配置: \(apiKey.prefix(8))...")
        } else {
            print("⚠️ 警告：请在 Info.plist 中配置有效的高德地图 API Key")
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
