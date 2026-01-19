import Foundation

/// AI Agent 协议
protocol AIAgent {
    /// 优化路线
    func optimizeRoute(
        attractions: [Attraction],
        travelMode: TravelMode?,
        prompt: String
    ) async throws -> OptimizedRoute
    
    /// 推荐住宿区域
    func recommendAccommodations(
        route: OptimizedRoute,
        dayCount: Int,
        prompt: String
    ) async throws -> [AccommodationZone]
    
    /// 估算游玩天数
    func estimateDuration(
        attractions: [Attraction],
        totalDistance: Double,
        prompt: String
    ) async throws -> Int
}

/// OpenAI API 请求模型
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

/// OpenAI 消息模型
struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

/// OpenAI API 响应模型
struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

/// OpenAI 选择模型
struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

/// OpenAI Agent 实现
class OpenAIAgent: AIAgent {
    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let timeout: TimeInterval
    
    init(
        apiKey: String,
        model: String = "gpt-4",
        baseURL: String = "https://api.openai.com/v1",
        timeout: TimeInterval = 30
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.timeout = timeout
    }
    
    func optimizeRoute(
        attractions: [Attraction],
        travelMode: TravelMode?,
        prompt: String
    ) async throws -> OptimizedRoute {
        let response = try await callOpenAI(prompt: prompt)
        
        // 解析响应
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let orderedIds = json["ordered_attraction_ids"] as? [String] else {
            throw TravelPlanError.aiPlanningFailed("无法解析路线规划结果")
        }
        
        // 按照返回的顺序重新排列景点
        var orderedAttractions: [Attraction] = []
        for id in orderedIds {
            if let attraction = attractions.first(where: { $0.id == id }) {
                orderedAttractions.append(attraction)
            }
        }
        
        // 如果解析失败，使用原始顺序
        if orderedAttractions.isEmpty {
            orderedAttractions = attractions
        }
        
        // 生成路线路径
        let routePath = orderedAttractions.compactMap { $0.coordinate }
        
        return OptimizedRoute(orderedAttractions: orderedAttractions, routePath: routePath)
    }
    
    func recommendAccommodations(
        route: OptimizedRoute,
        dayCount: Int,
        prompt: String
    ) async throws -> [AccommodationZone] {
        let response = try await callOpenAI(prompt: prompt)
        
        // 解析响应
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accommodationsData = json["accommodations"] as? [[String: Any]] else {
            throw TravelPlanError.aiPlanningFailed("无法解析住宿推荐结果")
        }
        
        var accommodations: [AccommodationZone] = []
        for accData in accommodationsData {
            guard let dayNumber = accData["day_number"] as? Int,
                  let name = accData["name"] as? String,
                  let centerData = accData["center"] as? [String: Double],
                  let latitude = centerData["latitude"],
                  let longitude = centerData["longitude"],
                  let radius = accData["radius"] as? Double else {
                continue
            }
            
            let zone = AccommodationZone(
                name: name,
                center: Coordinate(latitude: latitude, longitude: longitude),
                radius: radius,
                dayNumber: dayNumber
            )
            accommodations.append(zone)
        }
        
        return accommodations
    }
    
    func estimateDuration(
        attractions: [Attraction],
        totalDistance: Double,
        prompt: String
    ) async throws -> Int {
        let response = try await callOpenAI(prompt: prompt)
        
        // 解析响应
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let recommendedDays = json["recommended_days"] as? Int else {
            throw TravelPlanError.aiPlanningFailed("无法解析天数估算结果")
        }
        
        return max(1, recommendedDays)
    }
    
    private func callOpenAI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw TravelPlanError.aiPlanningFailed("无效的API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        let openAIRequest = OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(role: "system", content: "你是一个专业的旅行路线规划助手，请以JSON格式返回结果。"),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(openAIRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TravelPlanError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TravelPlanError.aiPlanningFailed("API返回错误: \(httpResponse.statusCode)")
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw TravelPlanError.aiPlanningFailed("API返回空内容")
        }
        
        return content
    }
}

/// 模拟 AI Agent（用于开发和测试）
class MockAIAgent: AIAgent {
    func optimizeRoute(
        attractions: [Attraction],
        travelMode: TravelMode?,
        prompt: String
    ) async throws -> OptimizedRoute {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 简单的距离优化：按纬度排序
        let sorted = attractions.sorted { a, b in
            guard let coordA = a.coordinate, let coordB = b.coordinate else {
                return false
            }
            return coordA.latitude < coordB.latitude
        }
        
        let routePath = sorted.compactMap { $0.coordinate }
        
        return OptimizedRoute(orderedAttractions: sorted, routePath: routePath)
    }
    
    func recommendAccommodations(
        route: OptimizedRoute,
        dayCount: Int,
        prompt: String
    ) async throws -> [AccommodationZone] {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var accommodations: [AccommodationZone] = []
        let attractionsPerDay = max(1, route.orderedAttractions.count / dayCount)
        
        for day in 1..<dayCount {
            let lastAttractionIndex = min(day * attractionsPerDay - 1, route.orderedAttractions.count - 1)
            if let coord = route.orderedAttractions[lastAttractionIndex].coordinate {
                let zone = AccommodationZone(
                    name: "第\(day)天住宿区域",
                    center: Coordinate(
                        latitude: coord.latitude + 0.01,
                        longitude: coord.longitude + 0.01
                    ),
                    radius: 2000,
                    dayNumber: day
                )
                accommodations.append(zone)
            }
        }
        
        return accommodations
    }
    
    func estimateDuration(
        attractions: [Attraction],
        totalDistance: Double,
        prompt: String
    ) async throws -> Int {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 简单估算：每天游览3-4个景点
        let count = attractions.count
        if count <= 2 {
            return 1
        } else if count <= 5 {
            return 2
        } else if count <= 7 {
            return 3
        } else {
            return max(3, count / 3)
        }
    }
}
