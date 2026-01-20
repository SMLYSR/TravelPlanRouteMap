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
        
        // 设置初始区域
        mapView.centerCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        mapView.zoomLevel = 12
        
        return mapView
    }
    
    func updateUIView(_ mapView: MAMapView, context: Context) {
        // 清除现有标注
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
        
        // 绘制路线
        if route.count >= 2 {
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
        
        // 调整视野
        if let annotations = mapView.annotations, !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MAMapViewDelegate {
        
        /// 自定义标注视图
        func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
            guard annotation is MAPointAnnotation else { return nil }
            
            let identifier = "AttractionAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            // 创建自定义标记
            let customView = createCustomAnnotationView(for: annotation)
            annotationView?.image = customView.asImage()
            annotationView?.centerOffset = CGPoint(x: 0, y: -20)
            
            return annotationView
        }
        
        /// 自定义覆盖物渲染
        func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
            if let polyline = overlay as? MAPolyline {
                let renderer = MAPolylineRenderer(polyline: polyline)
                renderer?.lineWidth = 6
                renderer?.strokeColor = UIColor(hex: "06B6D4")
                renderer?.lineJoinType = kMALineJoinRound
                renderer?.lineCapType = kMALineCapRound
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
