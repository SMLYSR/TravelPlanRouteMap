import Foundation

/// 提示词提供者协议
protocol PromptProvider {
    /// 获取路线优化提示词
    func getRouteOptimizationPrompt(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) -> String
    
    /// 获取住宿推荐提示词
    func getAccommodationRecommendationPrompt(
        route: OptimizedRoute,
        dayCount: Int,
        travelMode: TravelMode?
    ) -> String
    
    /// 获取天数估算提示词
    func getDurationEstimationPrompt(
        attractions: [Attraction],
        totalDistance: Double
    ) -> String
}

/// 提示词模块实现
class PromptModule: PromptProvider {
    
    func getRouteOptimizationPrompt(
        destination: String,
        attractions: [Attraction],
        travelMode: TravelMode?
    ) -> String {
        let attractionsList = attractions.enumerated().map { index, attraction in
            let coordStr = attraction.coordinate.map { "(\($0.latitude), \($0.longitude))" } ?? "未知坐标"
            return "  \(index + 1). \(attraction.name) - 坐标: \(coordStr)"
        }.joined(separator: "\n")
        
        let travelModeStr = travelMode?.displayName ?? "自驾"
        let travelModeHint: String
        switch travelMode {
        case .walking:
            travelModeHint = "考虑步行距离和路线的舒适性"
        case .publicTransport:
            travelModeHint = "考虑公交站点和地铁站的便利性，优化换乘"
        case .driving, .none:
            travelModeHint = "考虑停车便利性和驾驶距离"
        }
        
        return """
        你是一个专业的旅行路线规划助手。请根据以下信息规划最优游览顺序：

        目的地：\(destination)
        景点列表：
        \(attractionsList)
        出行方式：\(travelModeStr)

        规划要求：
        1. 最小化总行程距离
        2. 避免回头路和冤枉路
        3. \(travelModeHint)
        4. 返回景点的最优游览顺序（使用景点ID）

        请以JSON格式返回：
        {
          "ordered_attraction_ids": ["id1", "id2", ...],
          "reasoning": "规划理由"
        }
        """
    }
    
    func getAccommodationRecommendationPrompt(
        route: OptimizedRoute,
        dayCount: Int,
        travelMode: TravelMode?
    ) -> String {
        let attractionsList = route.orderedAttractions.enumerated().map { index, attraction in
            let coordStr = attraction.coordinate.map { "(\($0.latitude), \($0.longitude))" } ?? "未知坐标"
            return "  \(index + 1). \(attraction.name) - 坐标: \(coordStr)"
        }.joined(separator: "\n")
        
        let rangeLimit: String
        switch travelMode {
        case .walking, .publicTransport:
            rangeLimit = "1-3km"
        case .driving, .none:
            rangeLimit = "3-5km"
        }
        
        return """
        请根据以下旅行路线推荐住宿区域：

        路线信息：
        \(attractionsList)
        推荐天数：\(dayCount)
        出行方式：\(travelMode?.displayName ?? "自驾")

        推荐要求：
        1. 每天推荐一个住宿区域（最后一天除外）
        2. 住宿位置应靠近当天最后一个景点或第二天第一个景点
        3. 考虑交通便利性
        4. 推荐范围控制在\(rangeLimit)内

        请以JSON格式返回：
        {
          "accommodations": [
            {
              "day_number": 1,
              "name": "区域名称",
              "center": {"latitude": xx, "longitude": xx},
              "radius": 1000
            }
          ]
        }
        """
    }
    
    func getDurationEstimationPrompt(
        attractions: [Attraction],
        totalDistance: Double
    ) -> String {
        let attractionsList = attractions.map { "  - \($0.name)" }.joined(separator: "\n")
        
        return """
        请根据以下信息估算合理的游玩天数：

        景点列表：
        \(attractionsList)
        总距离：\(String(format: "%.1f", totalDistance)) 公里
        景点数量：\(attractions.count) 个

        估算要求：
        1. 综合考虑景点数量、总距离、单个景点预计游玩时间
        2. 每天游玩时间建议控制在8-10小时
        3. 合理安排每天的行程，不要强行凑天数或凑个数
        4. 考虑景点之间的交通时间

        请以JSON格式返回：
        {
          "recommended_days": 3,
          "reasoning": "估算理由",
          "daily_breakdown": [
            {
              "day": 1,
              "estimated_hours": 8,
              "attractions_count": 3
            }
          ]
        }
        """
    }
}
