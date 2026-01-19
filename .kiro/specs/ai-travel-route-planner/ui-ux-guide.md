# UI/UX 设计指南：AI旅行路线规划应用

## 概述

本文档为 AI旅行路线规划应用提供全面的 UI/UX 设计指南，基于专业设计系统分析和 iOS 平台最佳实践。

---

## 1. 设计系统

### 1.1 视觉风格

**风格名称：** Aurora UI（极光界面）

**核心特征：**
- 流动的渐变效果，营造北极光般的氛围感
- 柔和的色彩过渡，提升视觉舒适度
- 现代感强，适合旅行类应用的探索氛围

**适用场景：**
- Hero 区域（首屏）
- 地图背景渐变
- 加载动画
- 按钮和卡片的微妙渐变

**性能考虑：**
- ⚠️ 渐变效果需要优化性能
- 使用 CAGradientLayer 而非实时渲染
- 限制同时显示的渐变数量

**无障碍考虑：**
- ⚠️ 确保文本对比度达标（4.5:1）
- 渐变背景上的文字需要添加半透明遮罩

### 1.2 配色方案

基于旅行/旅游行业特性，结合浅蓝色主题需求：


#### 主配色方案（推荐）

| 颜色角色 | 色值 | 用途 | SwiftUI 代码 |
|---------|------|------|-------------|
| **主色** | `#06B6D4` | 主要按钮、强调元素 | `Color(hex: "06B6D4")` |
| **次要色** | `#0EA5E9` | 次要按钮、链接 | `Color(hex: "0EA5E9")` |
| **强调色（CTA）** | `#EC4899` | 行动号召按钮 | `Color(hex: "EC4899")` |
| **背景色** | `#FDF2F8` | 主背景 | `Color(hex: "FDF2F8")` |
| **文本色** | `#1E293B` | 主要文本 | `Color(hex: "1E293B")` |
| **边框色** | `#E2E8F0` | 分隔线、边框 | `Color(hex: "E2E8F0")` |

**配色说明：**
- 主色采用天空蓝（Sky Blue），符合旅行主题
- 强调色使用粉红色，增加活力和吸引力
- 背景色为柔和的粉白色，营造温馨氛围
- 文本色使用深灰蓝，确保可读性

#### 备选配色方案

如需更专业的商务风格，可使用：

| 颜色角色 | 色值 | 说明 |
|---------|------|------|
| 主色 | `#2563EB` | 信任蓝 |
| 次要色 | `#3B82F6` | 浅蓝 |
| CTA | `#F97316` | 橙色 |
| 背景 | `#F8FAFC` | 浅灰白 |

### 1.3 字体系统

**字体选择：** SF Pro（iOS 系统字体）

**字体层级：**


```swift
// 标题层级
.font(.largeTitle)      // 34pt - 页面主标题
.font(.title)           // 28pt - 区块标题
.font(.title2)          // 22pt - 次级标题
.font(.title3)          // 20pt - 卡片标题

// 正文层级
.font(.body)            // 17pt - 正文
.font(.callout)         // 16pt - 说明文字
.font(.subheadline)     // 15pt - 次要信息
.font(.footnote)        // 13pt - 脚注
.font(.caption)         // 12pt - 图注
```

**字重使用：**
- `.bold` - 标题、重要信息
- `.semibold` - 次级标题、按钮文字
- `.regular` - 正文
- `.light` - 辅助信息

**情感定位：** 启发性 + 吸引力

---

## 2. 组件设计规范

### 2.1 按钮设计

#### 主要按钮（Primary Button）

```swift
Button("开始规划") {
    // Action
}
.buttonStyle(PrimaryButtonStyle())

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
```


**设计要点：**
- 圆角半径：12pt（圆角扁平风格）
- 垂直内边距：16pt
- 按压反馈：缩放至 98%
- 动画时长：200ms（流畅响应）
- 渐变方向：从左到右

#### 次要按钮（Secondary Button）

```swift
Button("取消") {
    // Action
}
.buttonStyle(SecondaryButtonStyle())

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(Color(hex: "06B6D4"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "06B6D4"), lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
```

### 2.2 输入框设计

```swift
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "06B6D4"))
                .frame(width: 24, height: 24)
            
            TextField(placeholder, text: $text)
                .font(.body)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
        )
    }
}
```


**设计要点：**
- 左侧图标：使用 SF Symbols
- 内边距：16pt
- 边框：1pt，浅灰色
- 圆角：12pt
- 占位符颜色：`Color.secondary`

### 2.3 卡片设计

```swift
struct AttractionCard: View {
    let attraction: Attraction
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // 序号标记
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(attraction.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "1E293B"))
                
                Text(attraction.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
```


**设计要点：**
- 阴影：轻微阴影（透明度 5%，模糊半径 8pt）
- 内边距：16pt
- 序号标记：渐变圆形，40pt 直径
- 右侧箭头：表示可点击

### 2.4 加载动画

```swift
struct LoadingView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "E2E8F0"), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        reduceMotion ? .none : .linear(duration: 1).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text("正在规划路线...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
```


**设计要点：**
- 使用圆形进度指示器
- 渐变描边，营造动感
- 旋转动画：1秒完成一圈
- **重要：** 检查 `accessibilityReduceMotion` 环境变量
- 如果用户启用了减少动画，则禁用旋转效果

---

## 3. 页面布局规范

### 3.1 导航栏设计

```swift
struct CustomNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(Color(hex: "06B6D4"))
                }
            }
            
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(Color(hex: "1E293B"))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
```

**设计要点：**
- 高度：约 60pt（含内边距）
- 背景：白色，带轻微阴影
- 返回按钮：使用 SF Symbols 的 chevron.left
- 标题：粗体，左对齐


### 3.2 页面间距规范

```swift
// 标准间距系统
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// 使用示例
VStack(spacing: Spacing.md) {
    // 内容
}
.padding(.horizontal, Spacing.lg)
```

**间距使用指南：**
- `xs (4pt)` - 紧密相关的元素（如图标和文字）
- `sm (8pt)` - 同组内的元素
- `md (16pt)` - 标准间距，最常用
- `lg (24pt)` - 区块之间的间距
- `xl (32pt)` - 大区块间距
- `xxl (48pt)` - 页面顶部/底部留白

### 3.3 响应式布局

```swift
struct ResponsiveLayout: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columns: [GridItem] {
        sizeClass == .compact 
            ? [GridItem(.flexible())]  // iPhone 竖屏：单列
            : [GridItem(.flexible()), GridItem(.flexible())]  // iPad/横屏：双列
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                // 内容
            }
            .padding(Spacing.lg)
        }
    }
}
```


---

## 4. 动画与交互规范

### 4.1 动画时长标准

| 动画类型 | 时长 | 缓动函数 | 用途 |
|---------|------|---------|------|
| 微交互 | 150-200ms | `.easeInOut` | 按钮按压、开关切换 |
| 页面过渡 | 300ms | `.easeOut` | 页面进入 |
| 页面退出 | 250ms | `.easeIn` | 页面退出 |
| 加载动画 | 1000ms | `.linear` | 旋转加载器 |
| 列表项出现 | 200ms | `.spring()` | 列表项动画 |

**重要原则：**
- ❌ 避免超过 500ms 的 UI 动画（会感觉迟缓）
- ✅ 使用 150-300ms 的微交互动画
- ✅ 进入动画使用 `ease-out`，退出动画使用 `ease-in`
- ❌ 避免使用 `linear` 缓动（除了加载动画）

### 4.2 触觉反馈

```swift
import UIKit

enum HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
```


**使用场景：**
- `light()` - 按钮点击、选择项
- `medium()` - 重要操作确认
- `success()` - 路线规划完成
- `error()` - 输入错误、操作失败

**注意事项：**
- ❌ 不要过度使用触觉反馈（每次点击都震动会很烦人）
- ✅ 仅在重要操作和确认时使用
- ✅ 用于增强用户对操作结果的感知

### 4.3 页面过渡动画

```swift
// 推入动画（默认）
NavigationLink(destination: DetailView()) {
    Text("查看详情")
}

// 自定义过渡
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))

// 模态弹出
.sheet(isPresented: $showSheet) {
    SheetView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

### 4.4 列表动画

```swift
ForEach(attractions.indices, id: \.self) { index in
    AttractionCard(attraction: attractions[index], index: index + 1)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
}
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: attractions)
```


---

## 5. 地图可视化设计

### 5.1 地图样式配置

```swift
import AMapLightweightKit

class MapStyleManager {
    static func configureMapStyle(_ mapView: MAMapView) {
        // 设置地图类型
        mapView.mapType = .standard
        
        // 启用 3D 建筑
        mapView.showsBuildings = true
        
        // 显示指南针
        mapView.showsCompass = true
        
        // 显示比例尺
        mapView.showsScale = true
        
        // 自定义地图配色（可选）
        let styleOptions = MAMapCustomStyleOptions()
        styleOptions.styleDataPath = "style.data"  // 自定义样式文件
        mapView.setCustomMapStyleOptions(styleOptions)
    }
}
```

### 5.2 景点标记设计

```swift
// 自定义标记视图
class AttractionAnnotationView: MAAnnotationView {
    let indexLabel = UILabel()
    
    override init(annotation: MAAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    private func setupUI() {
        // 背景圆形
        let size: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        // 渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = size / 2
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 序号标签
        indexLabel.frame = bounds
        indexLabel.textAlignment = .center
        indexLabel.font = .systemFont(ofSize: 18, weight: .bold)
        indexLabel.textColor = .white
        addSubview(indexLabel)
        
        // 阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }
}
```


### 5.3 路线绘制

```swift
func drawRoute(coordinates: [CLLocationCoordinate2D]) {
    // 创建折线
    let polyline = MAPolyline(coordinates: coordinates, count: UInt(coordinates.count))
    mapView.add(polyline)
}

// 自定义折线样式
func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
    if overlay is MAPolyline {
        let renderer = MAPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 6
        renderer.strokeColor = UIColor(hex: "06B6D4")
        renderer.lineJoinType = .round
        renderer.lineCapType = .round
        return renderer
    }
    return nil
}
```

**设计要点：**
- 线宽：6pt（清晰可见但不过粗）
- 颜色：主色（天空蓝）
- 线条端点：圆角
- 连接处：圆角

### 5.4 住宿区域标注

```swift
func drawAccommodationZone(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
    // 创建圆形区域
    let circle = MACircle(center: center, radius: radius)
    mapView.add(circle)
}

// 自定义圆形样式
func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
    if overlay is MACircle {
        let renderer = MACircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor(hex: "EC4899").withAlphaComponent(0.15)
        renderer.strokeColor = UIColor(hex: "EC4899")
        renderer.lineWidth = 2
        return renderer
    }
    return nil
}
```

**设计要点：**
- 填充色：粉红色，透明度 15%
- 边框色：粉红色，不透明
- 边框宽度：2pt
- 半径：根据区域大小动态调整（建议 500-2000 米）


---

## 6. 无障碍设计（Accessibility）

### 6.1 动画减弱支持

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    view
        .animation(reduceMotion ? .none : .spring(), value: state)
}
```

**关键原则：**
- 始终检查 `accessibilityReduceMotion` 环境变量
- 当用户启用减弱动画时，禁用所有装饰性动画
- 保留必要的状态变化反馈

### 6.2 颜色对比度

**文本对比度要求：**
- 正文文本：至少 4.5:1
- 大号文本（18pt+）：至少 3:1
- 图标和重要元素：至少 3:1

**推荐组合：**
- ✅ `#1E293B` 文本 + `#FFFFFF` 背景 = 15.8:1
- ✅ `#06B6D4` 主色 + `#FFFFFF` 背景 = 3.2:1
- ⚠️ 渐变背景上的文字需要添加半透明遮罩

### 6.3 触摸目标尺寸

**最小触摸区域：**
- 按钮：44pt × 44pt（Apple HIG 标准）
- 列表项：最小高度 44pt
- 图标按钮：48pt × 48pt（包含内边距）

```swift
Button("操作") {
    // Action
}
.frame(minWidth: 44, minHeight: 44)
```


---

## 7. 性能优化指南

### 7.1 渐变性能优化

```swift
// ✅ 推荐：使用 CAGradientLayer
class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// ❌ 避免：实时渲染大量渐变
```

### 7.2 地图性能优化

```swift
// 限制同时显示的标注数量
func optimizeAnnotations() {
    let visibleAnnotations = mapView.annotations(in: mapView.visibleMapRect)
    
    // 只显示可见区域内的标注
    if visibleAnnotations.count > 50 {
        // 聚合显示
        clusterAnnotations(visibleAnnotations)
    }
}

// 使用注解复用
func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
    let identifier = "AttractionAnnotation"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    
    if annotationView == nil {
        annotationView = AttractionAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    }
    
    return annotationView
}
```

### 7.3 列表性能优化

```swift
// 使用 LazyVStack 而非 VStack
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(attractions) { attraction in
            AttractionCard(attraction: attraction)
        }
    }
}
```


---

## 8. 错误状态设计

### 8.1 错误提示样式

```swift
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "F97316"))
            
            Text(message)
                .font(.body)
                .foregroundColor(Color(hex: "1E293B"))
                .multilineTextAlignment(.center)
            
            Button("重试") {
                HapticFeedback.light()
                onRetry()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 200)
        }
        .padding(32)
    }
}
```

### 8.2 空状态设计

```swift
struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "06B6D4").opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color(hex: "1E293B"))
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(actionTitle) {
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 200)
        }
        .padding(48)
    }
}
```


---

## 9. SwiftUI 最佳实践

### 9.1 状态管理

```swift
// ✅ 使用 @State 管理视图本地状态
@State private var destination: String = ""

// ✅ 使用 @EnvironmentObject 管理全局状态
@EnvironmentObject var plannerState: PlannerState

// ✅ 使用 @Binding 传递可变状态给子视图
struct ChildView: View {
    @Binding var isExpanded: Bool
}
```

### 9.2 导航管理

```swift
// ✅ 使用 NavigationStack（iOS 16+）
NavigationStack {
    ContentView()
        .navigationDestination(for: Attraction.self) { attraction in
            AttractionDetailView(attraction: attraction)
        }
}

// ✅ 使用 @Environment(\.dismiss) 关闭视图
@Environment(\.dismiss) var dismiss

Button("返回") {
    dismiss()
}
```

### 9.3 动画最佳实践

```swift
// ✅ 使用 withAnimation 包裹状态变化
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
    isExpanded.toggle()
}

// ✅ 检查减弱动画设置
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? .none : .spring()
}
```


---

## 10. 交付前检查清单

### 10.1 视觉质量
- [ ] 所有图标使用 SF Symbols（不使用 emoji）
- [ ] 图标尺寸一致（24×24pt）
- [ ] 渐变效果使用 CAGradientLayer 优化
- [ ] 阴影效果轻微且一致（透明度 5%，半径 8pt）
- [ ] 圆角半径统一为 12pt

### 10.2 交互体验
- [ ] 所有可点击元素有明确的视觉反馈
- [ ] 按钮按压有缩放或透明度变化
- [ ] 触摸目标至少 44×44pt
- [ ] 加载状态有明确的进度指示
- [ ] 错误状态提供重试选项

### 10.3 动画效果
- [ ] 微交互动画时长 150-300ms
- [ ] 检查 `accessibilityReduceMotion` 环境变量
- [ ] 避免超过 500ms 的 UI 动画
- [ ] 使用 `ease-out` 进入，`ease-in` 退出
- [ ] 装饰性动画可被禁用

### 10.4 无障碍
- [ ] 文本对比度至少 4.5:1
- [ ] 所有交互元素支持 VoiceOver
- [ ] 触摸目标符合最小尺寸要求
- [ ] 支持动态字体大小
- [ ] 颜色不是唯一的信息传达方式

### 10.5 性能
- [ ] 使用 LazyVStack/LazyHStack 优化列表
- [ ] 地图标注使用复用机制
- [ ] 渐变使用 CAGradientLayer
- [ ] 限制同时显示的动画数量
- [ ] 图片使用适当的压缩和缓存

### 10.6 响应式
- [ ] iPhone SE (375pt) 正常显示
- [ ] iPhone 标准尺寸 (390pt-430pt) 正常显示
- [ ] iPad 竖屏/横屏适配
- [ ] 横屏模式布局合理
- [ ] 安全区域正确处理


---

## 11. 常见问题与解决方案

### 11.1 渐变背景上的文字对比度不足

**问题：** Aurora UI 风格的渐变背景可能导致文字难以阅读。

**解决方案：**
```swift
Text("标题文字")
    .font(.title.weight(.bold))
    .foregroundColor(.white)
    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    .padding()
    .background(
        Color.black.opacity(0.2)
            .blur(radius: 10)
    )
```

### 11.2 地图标注重叠

**问题：** 景点密集时标注会重叠。

**解决方案：**
```swift
// 使用聚合显示
func clusterAnnotations(_ annotations: [MAAnnotation]) {
    // 实现聚合逻辑
    let clusters = groupNearbyAnnotations(annotations, distance: 100)
    
    for cluster in clusters {
        if cluster.count > 1 {
            let clusterAnnotation = MAClusterAnnotation()
            clusterAnnotation.coordinate = cluster.center
            clusterAnnotation.count = cluster.count
            mapView.addAnnotation(clusterAnnotation)
        }
    }
}
```

### 11.3 动画卡顿

**问题：** 复杂动画导致界面卡顿。

**解决方案：**
```swift
// 使用 transform 和 opacity 而非 frame 动画
view
    .scaleEffect(isExpanded ? 1.0 : 0.8)
    .opacity(isExpanded ? 1.0 : 0.0)
    .animation(.easeInOut(duration: 0.2), value: isExpanded)

// 避免
view
    .frame(width: isExpanded ? 300 : 100)  // ❌ 会触发布局重计算
```


---

## 12. 设计资源

### 12.1 颜色扩展工具类

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
```

### 12.2 主题颜色定义

```swift
enum AppColors {
    static let primary = Color(hex: "06B6D4")
    static let secondary = Color(hex: "0EA5E9")
    static let accent = Color(hex: "EC4899")
    static let background = Color(hex: "FDF2F8")
    static let text = Color(hex: "1E293B")
    static let border = Color(hex: "E2E8F0")
}
```

---

## 13. 参考资源

### 13.1 官方文档
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [高德地图 iOS SDK](https://lbs.amap.com/api/lightweight-ios-sdk/guide/create-map/show-map)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

### 13.2 设计工具
- Figma - UI 设计和原型
- SF Symbols App - 图标浏览
- ColorSlurp - 颜色选择器
- Contrast - 对比度检查工具

### 13.3 灵感来源
- [Dribbble - Travel App Designs](https://dribbble.com/tags/travel-app)
- [Mobbin - iOS Design Patterns](https://mobbin.com/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

---

**文档版本：** 1.0  
**最后更新：** 2026-01-17  
**维护者：** AI Travel Route Planner Team
