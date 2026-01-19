import Foundation

/// 路线规划服务协议
protocol RoutePlanningService {
    /// 规划路线
    func planRoute(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async throws -> TravelPlan
}

/// 默认路线规划服务实现
class DefaultRoutePlanningService: RoutePlanningService {
    private let aiAgent: AIAgent
    private let promptProvider: PromptProvider
    private let geocodingService: GeocodingService
    
    init(
        aiAgent: AIAgent? = nil,
        promptProvider: PromptProvider? = nil,
        geocodingService: GeocodingService? = nil
    ) {
        self.aiAgent = aiAgent ?? AppDependencies.shared.aiAgent
        self.promptProvider = promptProvider ?? PromptModule()
        self.geocodingService = geocodingService ?? AppDependencies.shared.geocodingService
    }
    
    /// 便捷初始化方法（用于测试）
    convenience init(geocodingService: GeocodingService, aiAgent: AIAgent) {
        self.init(aiAgent: aiAgent, promptProvider: nil, geocodingService: geocodingService)
    }
    
    func planRoute(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) async throws -> TravelPlan {
        // 1. 验证输入
        guard !destination.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TravelPlanError.invalidDestination
        }
        
        guard attractions.count >= 2 else {
            throw TravelPlanError.insufficientAttractions
        }
        
        guard attractions.count <= 10 else {
            throw TravelPlanError.tooManyAttractions
        }
        
        // 2. 获取景点地理坐标（如果缺失）
        let geocodedAttractions = try await geocodeAttractions(attractions, destination: destination)
        
        // 3. 生成路线优化提示词
        let routePrompt = promptProvider.getRouteOptimizationPrompt(
            destination: destination,
            attractions: geocodedAttractions,
            travelMode: travelMode
        )
        
        // 4. 调用AI优化路线
        let optimizedRoute = try await aiAgent.optimizeRoute(
            attractions: geocodedAttractions,
            travelMode: travelMode,
            prompt: routePrompt
        )
        
        // 5. 计算总距离
        let totalDistance = calculateTotalDistance(optimizedRoute)
        
        // 6. 估算游玩天数
        let durationPrompt = promptProvider.getDurationEstimationPrompt(
            attractions: geocodedAttractions,
            totalDistance: totalDistance
        )
        let recommendedDays = try await aiAgent.estimateDuration(
            attractions: geocodedAttractions,
            totalDistance: totalDistance,
            prompt: durationPrompt
        )
        
        // 7. 推荐住宿区域
        var accommodations: [AccommodationZone] = []
        if recommendedDays > 1 {
            let accommodationPrompt = promptProvider.getAccommodationRecommendationPrompt(
                route: optimizedRoute,
                dayCount: recommendedDays,
                travelMode: travelMode
            )
            accommodations = try await aiAgent.recommendAccommodations(
                route: optimizedRoute,
                dayCount: recommendedDays,
                prompt: accommodationPrompt
            )
        }
        
        // 8. 构建完整旅行计划
        return TravelPlan(
            destination: destination,
            route: optimizedRoute,
            recommendedDays: recommendedDays,
            accommodations: accommodations,
            totalDistance: totalDistance,
            travelMode: travelMode
        )
    }
    
    private func geocodeAttractions(_ attractions: [Attraction], destination: String) async throws -> [Attraction] {
        var geocoded: [Attraction] = []
        
        for attraction in attractions {
            if attraction.coordinate != nil {
                geocoded.append(attraction)
            } else {
                // 使用高德地图地理编码服务补充坐标
                do {
                    let results = try await geocodingService.searchPOI(keyword: attraction.name, city: destination)
                    if let first = results.first {
                        let updatedAttraction = Attraction(
                            id: attraction.id,
                            name: first.name,
                            coordinate: first.coordinate,
                            address: first.address
                        )
                        geocoded.append(updatedAttraction)
                    } else {
                        throw TravelPlanError.geocodingFailed(attraction.name)
                    }
                } catch {
                    throw TravelPlanError.geocodingFailed(attraction.name)
                }
            }
        }
        
        return geocoded
    }
    
    private func calculateTotalDistance(_ route: OptimizedRoute) -> Double {
        var totalDistance: Double = 0
        let coordinates = route.routePath
        
        for i in 0..<(coordinates.count - 1) {
            let distance = haversineDistance(
                from: coordinates[i],
                to: coordinates[i + 1]
            )
            totalDistance += distance
        }
        
        return totalDistance
    }
    
    /// 使用 Haversine 公式计算两点之间的距离（单位：公里）
    private func haversineDistance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadius: Double = 6371 // 地球半径（公里）
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}
