import Foundation

/// 地图区域
struct MapRegion: Equatable {
    let center: Coordinate
    let span: MapSpan
    
    init(center: Coordinate, span: MapSpan) {
        self.center = center
        self.span = span
    }
}

/// 地图跨度
struct MapSpan: Equatable {
    let latitudeDelta: Double
    let longitudeDelta: Double
    
    init(latitudeDelta: Double, longitudeDelta: Double) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}
