import Foundation
import UIKit
import MAMapKit
import AMapFoundationKit

/// 高德地图服务实现
class AMapService: NSObject, MapService {
    
    private var mapView: MAMapView?
    private var currentRegion: MapRegion?
    private var attractions: [Attraction] = []
    private var routePath: [Coordinate] = []
    private var accommodationZones: [AccommodationZone] = []
    
    // MARK: - MapService Protocol
    
    func displayMap(in view: UIView, region: MapRegion) {
        currentRegion = region
        
        let map = MAMapView(frame: view.bounds)
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        map.delegate = self
        
        // 配置地图样式
        configureMapStyle(map)
        
        // 设置中心点和缩放级别
        map.centerCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        map.zoomLevel = 12
        
        view.addSubview(map)
        self.mapView = map
    }
    
    func addAttractionMarkers(_ attractions: [Attraction], ordered: Bool) {
        self.attractions = attractions
        
        guard let mapView = mapView else { return }
        
        for (index, attraction) in attractions.enumerated() {
            guard let coordinate = attraction.coordinate else { continue }
            
            let annotation = MAPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            annotation.title = ordered ? "\(index + 1). \(attraction.name)" : attraction.name
            annotation.subtitle = attraction.address
            mapView.addAnnotation(annotation)
        }
    }
    
    func drawRoute(_ route: [Coordinate]) {
        self.routePath = route
        
        guard let mapView = mapView, route.count >= 2 else { return }
        
        var coordinates = route.map { coord in
            CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        
        let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
        mapView.add(polyline)
    }
    
    func addAccommodationZones(_ zones: [AccommodationZone]) {
        self.accommodationZones = zones
        
        guard let mapView = mapView else { return }
        
        for zone in zones {
            let circle = MACircle(
                center: CLLocationCoordinate2D(
                    latitude: zone.center.latitude,
                    longitude: zone.center.longitude
                ),
                radius: zone.radius
            )
            mapView.add(circle)
        }
    }
    
    func fitMapToShowAllElements() {
        guard let mapView = mapView else { return }
        
        if let annotations = mapView.annotations, !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    func clearAllAnnotations() {
        attractions = []
        routePath = []
        accommodationZones = []
        
        guard let mapView = mapView else { return }
        
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        if let overlays = mapView.overlays {
            mapView.removeOverlays(overlays)
        }
    }
    
    // MARK: - Private Methods
    
    /// 配置地图样式（基于 UI/UX 指南 5.1）
    private func configureMapStyle(_ map: MAMapView) {
        map.mapType = .standard
        map.isShowsBuildings = true
        map.showsCompass = true
        map.showsScale = true
        map.isRotateEnabled = false
        map.isRotateCameraEnabled = false
    }
}

// MARK: - MAMapViewDelegate

extension AMapService: MAMapViewDelegate {
    
    /// 自定义景点标记视图（基于 UI/UX 指南 5.2）
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        guard annotation is MAPointAnnotation else { return nil }
        
        let identifier = "AttractionAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        
        // 创建自定义标记视图
        let customView = createCustomAnnotationView(for: annotation)
        annotationView?.image = customView.asImage()
        annotationView?.centerOffset = CGPoint(x: 0, y: -20)
        
        return annotationView
    }
    
    /// 自定义路线和区域样式（基于 UI/UX 指南 5.3, 5.4）
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if let polyline = overlay as? MAPolyline {
            let renderer = MAPolylineRenderer(polyline: polyline)
            renderer?.lineWidth = 6
            renderer?.strokeColor = UIColor(hex: "06B6D4")  // 主色（天空蓝）
            renderer?.lineJoinType = kMALineJoinRound
            renderer?.lineCapType = kMALineCapRound
            return renderer
        }
        
        if let circle = overlay as? MACircle {
            let renderer = MACircleRenderer(circle: circle)
            renderer?.fillColor = UIColor(hex: "EC4899").withAlphaComponent(0.15)  // 粉红色，15% 透明度
            renderer?.strokeColor = UIColor(hex: "EC4899")  // 粉红色边框
            renderer?.lineWidth = 2
            return renderer
        }
        
        return nil
    }
    
    /// 创建自定义标注视图
    private func createCustomAnnotationView(for annotation: MAAnnotation) -> UIView {
        let size: CGFloat = 40
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        
        // 渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = size / 2
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 序号标签
        let label = UILabel(frame: view.bounds)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        
        // 从标题中提取序号
        if let title = annotation.title, let firstChar = title?.first, firstChar.isNumber {
            label.text = String(firstChar)
        } else {
            label.text = "•"
        }
        view.addSubview(label)
        
        // 阴影
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.cornerRadius = size / 2
        
        return view
    }
}

// MARK: - UIView Extension

private extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
