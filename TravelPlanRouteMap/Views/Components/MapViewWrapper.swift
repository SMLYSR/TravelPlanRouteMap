import SwiftUI
import UIKit
import MAMapKit

/// 地图视图包装器（UIViewRepresentable）
/// 用于在 SwiftUI 中使用高德地图
struct MapViewWrapper: UIViewRepresentable {
    
    // MARK: - Properties
    
    let region: MapRegion
    let attractions: [Attraction]
    let route: [Coordinate]
    let accommodationZones: [AccommodationZone]
    var selectedAttraction: Attraction? = nil  // 选中的景点
    var selectedAccommodationZone: AccommodationZone? = nil  // 选中的住宿区域
    
    /// 导航路径（可选）- 优先使用此属性绘制路线
    /// 当navigationPath不为nil时，使用其allCoordinates绘制实际道路路线
    /// 当为nil时，回退到route参数绘制简单直线
    /// 需求: 3.1, 3.2, 3.3
    var navigationPath: NavigationPath? = nil
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MAMapView {
        let mapView = MAMapView(frame: .zero)
        mapView.delegate = context.coordinator
        
        // 配置地图
        mapView.mapType = .standard
        mapView.isShowsBuildings = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isRotateEnabled = false
        mapView.isRotateCameraEnabled = false
        
        // 性能优化配置
        mapView.isShowTraffic = false  // 关闭实时路况
        mapView.isShowsLabels = true
        
        // 设置初始区域
        mapView.centerCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        mapView.zoomLevel = 12
        
        // 初始化时添加标注和覆盖物
        context.coordinator.updateMapContent(
            mapView: mapView,
            attractions: attractions,
            route: route,
            accommodationZones: accommodationZones,
            navigationPath: navigationPath
        )
        
        return mapView
    }
    
    func updateUIView(_ mapView: MAMapView, context: Context) {
        // 优先处理住宿区域选中
        if let selectedZone = selectedAccommodationZone {
            // 检查是否需要更新选中状态
            if context.coordinator.lastSelectedAccommodationZoneId != selectedZone.id {
                context.coordinator.lastSelectedAccommodationZoneId = selectedZone.id
                context.coordinator.lastSelectedAttractionId = nil  // 清除景点选中
                
                let center = CLLocationCoordinate2D(
                    latitude: selectedZone.center.latitude,
                    longitude: selectedZone.center.longitude
                )
                mapView.setCenter(center, animated: true)
                
                // 根据半径计算合适的缩放级别
                let zoomLevel = calculateZoomLevel(for: selectedZone.radius)
                mapView.setZoomLevel(zoomLevel, animated: true)
            }
            return
        } else {
            context.coordinator.lastSelectedAccommodationZoneId = nil
        }
        
        // 处理景点选中
        if let selected = selectedAttraction, let coordinate = selected.coordinate {
            // 检查是否需要更新选中状态
            if context.coordinator.lastSelectedAttractionId != selected.id {
                context.coordinator.lastSelectedAttractionId = selected.id
                let center = CLLocationCoordinate2D(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                mapView.setCenter(center, animated: true)
                mapView.setZoomLevel(15, animated: true)
            }
            return
        } else {
            context.coordinator.lastSelectedAttractionId = nil
        }
        
        // 检查数据是否真的变化了
        let needsUpdate = context.coordinator.needsUpdate(
            attractions: attractions,
            route: route,
            accommodationZones: accommodationZones,
            navigationPath: navigationPath
        )
        
        if needsUpdate {
            context.coordinator.updateMapContent(
                mapView: mapView,
                attractions: attractions,
                route: route,
                accommodationZones: accommodationZones,
                navigationPath: navigationPath
            )
        }
    }
    
    /// 根据半径计算合适的缩放级别
    private func calculateZoomLevel(for radius: Double) -> CGFloat {
        // 半径越大，缩放级别越小（显示范围越大）
        // 半径单位：米
        if radius > 5000 {
            return 11
        } else if radius > 3000 {
            return 12
        } else if radius > 2000 {
            return 13
        } else if radius > 1000 {
            return 14
        } else {
            return 15
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MAMapViewDelegate {
        
        // 缓存上次的数据，避免重复更新
        private var lastAttractionsCount: Int = 0
        private var lastRouteCount: Int = 0
        private var lastAccommodationZonesCount: Int = 0
        private var lastNavigationPathCount: Int = 0
        var lastSelectedAttractionId: String? = nil
        var lastSelectedAccommodationZoneId: String? = nil
        
        // 缓存标注视图，避免重复创建
        private var annotationImageCache: [String: UIImage] = [:]
        
        /// 检查是否需要更新地图内容
        func needsUpdate(
            attractions: [Attraction],
            route: [Coordinate],
            accommodationZones: [AccommodationZone],
            navigationPath: NavigationPath?
        ) -> Bool {
            let attractionsChanged = attractions.count != lastAttractionsCount
            let routeChanged = route.count != lastRouteCount
            let zonesChanged = accommodationZones.count != lastAccommodationZonesCount
            let navPathChanged = (navigationPath?.allCoordinates.count ?? 0) != lastNavigationPathCount
            
            return attractionsChanged || routeChanged || zonesChanged || navPathChanged
        }
        
        /// 更新地图内容（标注、路线、区域）
        func updateMapContent(
            mapView: MAMapView,
            attractions: [Attraction],
            route: [Coordinate],
            accommodationZones: [AccommodationZone],
            navigationPath: NavigationPath?
        ) {
            // 清除现有标注和覆盖物
            if let annotations = mapView.annotations {
                mapView.removeAnnotations(annotations)
            }
            if let overlays = mapView.overlays {
                mapView.removeOverlays(overlays)
            }
            
            // 添加景点标记
            for (index, attraction) in attractions.enumerated() {
                guard let coordinate = attraction.coordinate else { continue }
                
                let annotation = MAPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                annotation.title = "\(index + 1). \(attraction.name)"
                annotation.subtitle = attraction.address
                mapView.addAnnotation(annotation)
            }
            
            // 绘制路线 - 优先使用navigationPath
            if let navPath = navigationPath {
                let coordinates = navPath.allCoordinates
                if coordinates.count >= 2 {
                    var clCoordinates = coordinates.map { coord in
                        CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                    }
                    let polyline = MAPolyline(coordinates: &clCoordinates, count: UInt(clCoordinates.count))
                    mapView.add(polyline)
                }
            } else if route.count >= 2 {
                var coordinates = route.map { coord in
                    CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                }
                let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
                mapView.add(polyline)
            }
            
            // 添加住宿区域
            for zone in accommodationZones {
                let circle = MACircle(
                    center: CLLocationCoordinate2D(
                        latitude: zone.center.latitude,
                        longitude: zone.center.longitude
                    ),
                    radius: zone.radius
                )
                mapView.add(circle)
            }
            
            // 调整视野（只在初始化时执行）
            if lastAttractionsCount == 0 && !attractions.isEmpty {
                if let annotations = mapView.annotations, !annotations.isEmpty {
                    mapView.showAnnotations(annotations, animated: false)
                }
            }
            
            // 更新缓存
            lastAttractionsCount = attractions.count
            lastRouteCount = route.count
            lastAccommodationZonesCount = accommodationZones.count
            lastNavigationPathCount = navigationPath?.allCoordinates.count ?? 0
        }
        
        /// 自定义标注视图（带缓存优化）
        func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
            guard annotation is MAPointAnnotation else { return nil }
            
            let identifier = "AttractionAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.centerOffset = CGPoint(x: 0, y: -20)
            } else {
                annotationView?.annotation = annotation
            }
            
            // 使用缓存的图片或创建新图片
            if let title = annotation.title, let cacheKey = title {
                if let cachedImage = annotationImageCache[cacheKey] {
                    annotationView?.image = cachedImage
                } else {
                    let customView = createCustomAnnotationView(for: annotation)
                    let image = customView.asImage()
                    annotationImageCache[cacheKey] = image
                    annotationView?.image = image
                }
            }
            
            return annotationView
        }
        
        /// 自定义覆盖物渲染（优化渲染性能）
        func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
            if let polyline = overlay as? MAPolyline {
                let renderer = MAPolylineRenderer(polyline: polyline)
                renderer?.lineWidth = 6
                renderer?.strokeColor = UIColor(hex: "06B6D4")
                renderer?.lineJoinType = kMALineJoinRound
                renderer?.lineCapType = kMALineCapRound
                // 性能优化：减少抗锯齿
                renderer?.lineDashType = kMALineDashTypeNone
                return renderer
            }
            
            if let circle = overlay as? MACircle {
                let renderer = MACircleRenderer(circle: circle)
                renderer?.fillColor = UIColor(hex: "EC4899").withAlphaComponent(0.15)
                renderer?.strokeColor = UIColor(hex: "EC4899")
                renderer?.lineWidth = 2
                return renderer
            }
            
            return nil
        }
        
        private func createCustomAnnotationView(for annotation: MAAnnotation) -> UIView {
            let size: CGFloat = 40
            let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            
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
            
            let label = UILabel(frame: view.bounds)
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16, weight: .bold)
            label.textColor = .white
            
            if let title = annotation.title, let firstChar = title?.first, firstChar.isNumber {
                label.text = String(firstChar)
            } else {
                label.text = "•"
            }
            view.addSubview(label)
            
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.2
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowRadius = 4
            view.layer.cornerRadius = size / 2
            
            return view
        }
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

// MARK: - Preview

#if DEBUG
struct MapViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        MapViewWrapper(
            region: MapRegion(
                center: Coordinate(latitude: 39.9042, longitude: 116.4074),
                span: MapSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ),
            attractions: [],
            route: [],
            accommodationZones: []
        )
        .frame(height: 400)
    }
}
#endif
