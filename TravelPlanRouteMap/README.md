# AI 旅行路线规划应用

一款基于 AI 的智能旅行路线规划 iOS 应用，帮助用户快速规划最优旅行路线。

## 功能特性

- 🗺️ **智能路线规划**：基于 AI 优化景点游览顺序，减少路程
- 🏨 **住宿区域推荐**：根据出行方式推荐合适的住宿区域
- 📅 **天数估算**：智能估算推荐游玩天数
- 🚗 **多种出行方式**：支持步行、公共交通、自驾三种出行方式
- 📍 **地图可视化**：在高德地图上展示规划结果
- 💾 **历史记录**：保存和管理历史规划记录

## 技术架构

### MVVM 架构

```
TravelPlanRouteMap/
├── Models/          # 数据模型
├── Views/           # 视图层
│   └── Components/  # 可复用组件
├── ViewModels/      # 视图模型
├── Services/        # 服务层
└── Utils/           # 工具类
```

### 核心组件

| 组件 | 说明 |
|------|------|
| `RoutePlanningService` | 路线规划服务，协调各模块完成规划 |
| `AIAgent` | AI 交互层，调用 OpenAI API |
| `MapService` | 地图服务，封装高德地图 SDK |
| `GeocodingService` | 地理编码服务，地址转坐标 |
| `TravelPlanRepository` | 数据持久化，管理历史记录 |

## 使用说明

### 1. 输入目的地

在首页点击「创建计划」，输入您想去的城市或地区。

### 2. 选择出行方式

选择您的出行方式：
- **步行**：适合城市内短距离游览
- **公共交通**：适合城市间或城市内中等距离
- **自驾**：适合长距离或郊区景点

### 3. 添加景点

搜索并添加您想去的景点（2-10个）。

### 4. 查看规划结果

AI 将为您：
- 优化景点游览顺序
- 估算推荐游玩天数
- 推荐住宿区域
- 在地图上展示完整路线

## 配置说明

### 高德地图 SDK

1. 在 [高德开放平台](https://lbs.amap.com/) 注册并创建应用
2. 获取 iOS SDK Key
3. 在 `Info.plist` 中配置：

```xml
<key>AMapApiKey</key>
<string>您的高德地图 API Key</string>
```

### OpenAI API

1. 在 [OpenAI](https://platform.openai.com/) 获取 API Key
2. 在 `Config.swift` 中配置：

```swift
static let openAIAPIKey = "您的 OpenAI API Key"
```

## 常见问题

### Q: 为什么地图显示为占位视图？

A: 需要集成高德地图 SDK 并配置有效的 API Key。当前版本使用 Mock 实现进行开发。

### Q: AI 规划超时怎么办？

A: 请检查网络连接，或稍后重试。AI 规划默认超时时间为 30 秒。

### Q: 最多可以添加多少个景点？

A: 最多支持 10 个景点，最少需要 2 个景点才能进行规划。

### Q: 如何删除历史记录？

A: 在历史记录列表中，长按某条记录可以删除。

## 开发说明

### 运行测试

```bash
# 单元测试
xcodebuild test -scheme TravelPlanRouteMap -destination 'platform=iOS Simulator,name=iPhone 15'

# UI 测试
xcodebuild test -scheme TravelPlanRouteMapUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 代码规范

- 使用 SwiftLint 进行代码检查
- 遵循 MVVM 架构模式
- 所有公共接口需要添加文档注释
- 新功能需要编写单元测试和属性测试

## 许可证

MIT License
