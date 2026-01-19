import Foundation
import UIKit

/// 地图服务协议
protocol MapService {
    /// 在指定视图中显示地图
    func displayMap(in view: UIView, region: MapRegion)
    
    /// 添加景点标记
    func addAttractionMarkers(_ attractions: [Attraction], ordered: Bool)
    
    /// 绘制路线
    func drawRoute(_ route: [Coordinate])
    
    /// 添加住宿区域标注
    func addAccommodationZones(_ zones: [AccommodationZone])
    
    /// 调整地图视野以显示所有元素
    func fitMapToShowAllElements()
    
    /// 清除所有标注
    func clearAllAnnotations()
}

/// 模拟地图服务（用于开发和测试）
class MockMapService: MapService {
    private var currentRegion: MapRegion?
    private var attractions: [Attraction] = []
    private var routePath: [Coordinate] = []
    private var accommodationZones: [AccommodationZone] = []
    
    func displayMap(in view: UIView, region: MapRegion) {
        currentRegion = region
        // 在实际实现中，这里会初始化高德地图视图
    }
    
    func addAttractionMarkers(_ attractions: [Attraction], ordered: Bool) {
        self.attractions = attractions
        // 在实际实现中，这里会添加地图标记
    }
    
    func drawRoute(_ route: [Coordinate]) {
        self.routePath = route
        // 在实际实现中，这里会绘制路线
    }
    
    func addAccommodationZones(_ zones: [AccommodationZone]) {
        self.accommodationZones = zones
        // 在实际实现中，这里会添加住宿区域标注
    }
    
    func fitMapToShowAllElements() {
        // 在实际实现中，这里会调整地图视野
    }
    
    func clearAllAnnotations() {
        attractions = []
        routePath = []
        accommodationZones = []
    }
}
