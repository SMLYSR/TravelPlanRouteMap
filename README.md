# 旅行路线规划 iOS 应用

基于 AI 的智能旅行路线规划应用，帮助用户快速规划最优旅行路线。

## 功能特性

- 🗺️ **AI 智能规划**：优化景点游览顺序，减少路程
- 🏨 **住宿推荐**：根据出行方式推荐合适的住宿区域
- 📅 **天数估算**：智能估算推荐游玩天数
- 🚗 **多种出行方式**：步行、公共交通、自驾
- 📍 **地图可视化**：高德地图展示完整路线
- 💾 **历史记录**：保存和管理规划记录

## 快速开始

### 前置要求

- iOS 15.0+
- Xcode 15.0+
- CocoaPods

### 安装依赖

```bash
pod install
```

### 配置 API

1. **高德地图**：在 `Info.plist` 中配置
   ```xml
   <key>AMapApiKey</key>
   <string>YOUR_AMAP_API_KEY</string>
   ```

2. **OpenAI API**：在 `Config.swift` 中配置
   ```swift
   static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
   ```

### 运行应用

```bash
open TravelPlanRouteMap.xcworkspace
# 在 Xcode 中选择目标设备并运行
```

## 项目结构

```
TravelPlanRouteMap/
├── Models/          # 数据模型
├── Views/           # UI 视图
├── ViewModels/      # 视图逻辑
├── Services/        # 业务服务
└── Utils/           # 工具类
```

## 核心服务

| 服务 | 功能 |
|------|------|
| `RoutePlanningService` | 路线规划协调 |
| `AIAgent` | AI 交互（OpenAI） |
| `AMapService` | 地图集成 |
| `GeocodingService` | 地址编码 |
| `TravelPlanRepository` | 数据持久化 |

## 使用流程

1. 输入目的地城市
2. 选择出行方式
3. 添加景点（2-10个）
4. 查看 AI 规划结果

## 常见问题

**Q: 地图显示为占位视图？**  
A: 需要配置有效的高德地图 API Key

**Q: AI 规划超时？**  
A: 检查网络连接，默认超时 30 秒

**Q: 最多支持多少景点？**  
A: 最多 10 个，最少 2 个

## 许可证

MIT License
