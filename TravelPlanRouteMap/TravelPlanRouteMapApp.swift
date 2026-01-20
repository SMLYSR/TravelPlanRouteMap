import SwiftUI
import AMapFoundationKit
import MAMapKit
import AMapSearchKit

@main
struct TravelPlanRouteMapApp: App {
    @State private var isReady = false
    
    init() {
        // 只做轻量级初始化
        setupAppearance()
        
        // 同步设置隐私政策（必须在 SDK 使用前完成，但很快）
        setupPrivacyPolicy()
    }
    
    var body: some Scene {
        WindowGroup {
            if isReady {
                MainView()
                    .transition(.opacity)
            } else {
                LaunchScreenView()
                    .onAppear {
                        // 异步初始化高德 SDK
                        Task {
                            await setupAMapServicesAsync()
                            await MainActor.run {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isReady = true
                                }
                            }
                        }
                    }
            }
        }
    }
    
    /// 设置隐私政策（同步，但很快）
    private func setupPrivacyPolicy() {
        MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        MAMapView.updatePrivacyAgree(.didAgree)
        AMapSearchAPI.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
    }
    
    /// 异步配置高德地图服务
    private func setupAMapServicesAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 从 Info.plist 读取 API Key
                if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String,
                   !apiKey.isEmpty && apiKey != "YOUR_AMAP_API_KEY_HERE" {
                    DispatchQueue.main.async {
                        AMapServices.shared().apiKey = apiKey
                        AMapServices.shared().enableHTTPS = true
                        print("✅ 高德地图 API Key 已配置: \(apiKey.prefix(8))...")
                    }
                } else {
                    print("⚠️ 警告：请在 Info.plist 中配置有效的高德地图 API Key")
                }
                continuation.resume()
            }
        }
    }
    
    /// 配置应用外观
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: AppColors.textUI]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().backgroundColor = .white
    }
}

/// 启动屏视图
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("旅行路线规划")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppColors.text)
                
                ProgressView()
                    .tint(AppColors.primary)
            }
        }
    }
}
