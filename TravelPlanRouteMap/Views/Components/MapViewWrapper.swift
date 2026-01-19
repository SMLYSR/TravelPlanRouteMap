import SwiftUI
import UIKit
// 注意：实际使用时需要导入高德地图 SDK
// import MAMapKit

/// 地图视图包装器（UIViewRepresentable）
/// 用于在 SwiftUI 中使用高德地图
struct MapViewWrapper: UIViewRepresentable {
    
    // MARK: - Properties
    
    let mapService: MapService
    let region: MapRegion
    let attractions: [Attraction]
    let route: [Coordinate]
    let accommodationZones: [AccommodationZone]
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(hex: "F3F4F6")
        
        // 显示地图
        mapService.displayMap(in: containerView, region: region)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 清除现有标注
        mapService.clearAllAnnotations()
        
        // 添加景点标记（按顺序编号）
        if !attractions.isEmpty {
            mapService.addAttractionMarkers(attractions, ordered: true)
        }
        
        // 绘制路线
        if !route.isEmpty {
            mapService.drawRoute(route)
        }
        
        // 添加住宿区域
        if !accommodationZones.isEmpty {
            mapService.addAccommodationZones(accommodationZones)
        }
        
        // 调整视野以显示所有元素
        mapService.fitMapToShowAllElements()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var parent: MapViewWrapper
        
        init(_ parent: MapViewWrapper) {
            self.parent = parent
        }
        
        // 实际实现时，这里会处理 MAMapViewDelegate 回调
        // 例如：标记点击、地图移动等事件
    }
}

// MARK: - Preview

#if DEBUG
struct MapViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        MapViewWrapper(
            mapService: MockMapService(),
            region: MapRegion(
                center: Coordinate(latitude: 39.9042, longitude: 116.4074),
                span: MapSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ),
            attractions: [
                Attraction(
                    id: UUID(),
                    name: "故宫",
                    coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
                    address: "北京市东城区景山前街4号"
                ),
                Attraction(
                    id: UUID(),
                    name: "天安门",
                    coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975),
                    address: "北京市东城区东长安街"
                )
            ],
            route: [
                Coordinate(latitude: 39.9163, longitude: 116.3972),
                Coordinate(latitude: 39.9087, longitude: 116.3975)
            ],
            accommodationZones: [
                AccommodationZone(
                    id: UUID(),
                    name: "王府井商圈",
                    center: Coordinate(latitude: 39.9142, longitude: 116.4103),
                    radius: 1000,
                    description: "交通便利，购物方便"
                )
            ]
        )
        .frame(height: 400)
    }
}
#endif
