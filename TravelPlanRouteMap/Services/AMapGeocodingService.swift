import Foundation
import AMapSearchKit

/// 高德地图地理编码服务实现
class AMapGeocodingService: NSObject, GeocodingService {
    
    private var searchAPI: AMapSearchAPI?
    private var geocodeContinuation: CheckedContinuation<[GeocodingResult], Error>?
    private var poiContinuation: CheckedContinuation<[POIResult], Error>?
    
    override init() {
        super.init()
        // AMapSearchAPI() 可能返回 nil（如果隐私政策未设置或 API Key 无效）
        if let api = AMapSearchAPI() {
            self.searchAPI = api
            api.delegate = self
            print("✅ AMapSearchAPI 初始化成功")
        } else {
            print("⚠️ AMapSearchAPI 初始化失败，请检查隐私政策设置和 API Key")
        }
    }
    
    // MARK: - GeocodingService Protocol
    
    func geocode(address: String) async throws -> [GeocodingResult] {
        guard let searchAPI = searchAPI else {
            throw TravelPlanError.geocodingFailed("搜索服务未初始化，请检查高德地图配置")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.geocodeContinuation = continuation
            
            let request = AMapGeocodeSearchRequest()
            request.address = address
            searchAPI.aMapGeocodeSearch(request)
        }
    }
    
    func searchPOI(keyword: String, city: String?) async throws -> [POIResult] {
        guard let searchAPI = searchAPI else {
            throw TravelPlanError.geocodingFailed("搜索服务未初始化，请检查高德地图配置")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.poiContinuation = continuation
            
            let request = AMapPOIKeywordsSearchRequest()
            request.keywords = keyword
            // 不限制城市范围，允许全国搜索
            request.cityLimit = false
            request.offset = 20  // 每页返回数量
            searchAPI.aMapPOIKeywordsSearch(request)
        }
    }
}

// MARK: - AMapSearchDelegate

extension AMapGeocodingService: AMapSearchDelegate {
    
    /// 地理编码搜索完成回调
    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        guard let continuation = geocodeContinuation else { return }
        geocodeContinuation = nil
        
        guard let geocodes = response?.geocodes, !geocodes.isEmpty else {
            continuation.resume(returning: [])
            return
        }
        
        let results = geocodes.compactMap { geocode -> GeocodingResult? in
            guard let location = geocode.location else { return nil }
            
            return GeocodingResult(
                name: geocode.formattedAddress ?? "",
                address: geocode.formattedAddress ?? "",
                coordinate: Coordinate(
                    latitude: Double(location.latitude),
                    longitude: Double(location.longitude)
                ),
                city: geocode.city ?? ""
            )
        }
        
        continuation.resume(returning: results)
    }
    
    /// POI 搜索完成回调
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let continuation = poiContinuation else { return }
        poiContinuation = nil
        
        guard let pois = response?.pois, !pois.isEmpty else {
            continuation.resume(returning: [])
            return
        }
        
        let results = pois.compactMap { poi -> POIResult? in
            guard let location = poi.location else { return nil }
            
            return POIResult(
                name: poi.name ?? "",
                address: poi.address ?? "",
                coordinate: Coordinate(
                    latitude: Double(location.latitude),
                    longitude: Double(location.longitude)
                ),
                type: poi.type ?? ""
            )
        }
        
        continuation.resume(returning: results)
    }
    
    /// 搜索失败回调
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        print("高德地图搜索失败: \(error.localizedDescription)")
        
        // 处理地理编码错误
        if let continuation = geocodeContinuation {
            geocodeContinuation = nil
            continuation.resume(throwing: TravelPlanError.geocodingFailed(error.localizedDescription))
        }
        
        // 处理 POI 搜索错误
        if let continuation = poiContinuation {
            poiContinuation = nil
            continuation.resume(throwing: TravelPlanError.geocodingFailed(error.localizedDescription))
        }
    }
}
