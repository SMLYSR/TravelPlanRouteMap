import Foundation
import AMapSearchKit

/// 路径导航服务协议
protocol RouteNavigationServiceProtocol {
    /// 规划导航路线
    /// - Parameters:
    ///   - attractions: 有序的景点列表
    ///   - travelMode: 出行方式
    ///   - citycode: 城市代码（用于公交路线规划,从高德API获取）
    /// - Returns: 导航路径
    func planNavigationRoute(
        attractions: [Attraction],
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> NavigationPath
    
    /// 规划单段路线
    /// - Parameters:
    ///   - origin: 起点坐标
    ///   - destination: 终点坐标
    ///   - travelMode: 出行方式
    ///   - citycode: 城市代码（用于公交路线规划）
    /// - Returns: 路线段
    func planSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> RouteSegment
}

/// 路径导航服务实现
/// 需求: 1.1, 1.2, 1.3, 1.4
class RouteNavigationService: NSObject, RouteNavigationServiceProtocol {
    
    private var searchAPI: AMapSearchAPI?
    
    // 用于异步回调的continuation存储
    private var walkingContinuation: CheckedContinuation<RouteSegment, Error>?
    private var drivingContinuation: CheckedContinuation<RouteSegment, Error>?
    private var transitContinuation: CheckedContinuation<RouteSegment, Error>?
    
    // 当前请求的起终点（用于构建RouteSegment）
    private var currentOrigin: Coordinate?
    private var currentDestination: Coordinate?
    private var currentTravelMode: TravelMode?
    
    // 限流控制：请求之间的最小间隔（毫秒）
    private let requestInterval: UInt64 = 300_000_000  // 300ms = 0.3秒
    private var lastRequestTime: UInt64 = 0
    
    override init() {
        super.init()
        if let api = AMapSearchAPI() {
            self.searchAPI = api
            api.delegate = self
            print("✅ RouteNavigationService: AMapSearchAPI 初始化成功")
        } else {
            print("⚠️ RouteNavigationService: AMapSearchAPI 初始化失败，请检查隐私政策设置和 API Key")
        }
    }
    
    // MARK: - RouteNavigationServiceProtocol
    
    /// 规划完整导航路线
    /// 对于N个景点，规划N-1段相邻景点之间的路线
    /// 需求: 2.1, 2.2, 2.3, 2.4
    func planNavigationRoute(
        attractions: [Attraction],
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> NavigationPath {
        // 过滤出有有效坐标的景点
        let validAttractions = attractions.filter { $0.coordinate != nil }
        
        guard validAttractions.count >= 2 else {
            throw RouteNavigationError.invalidCoordinate
        }
        
        var segments: [RouteSegment] = []
        
        print("📍 开始规划 \(validAttractions.count - 1) 段路线，使用限流策略避免 QPS 超限")
        
        // 按顺序规划每段路线（需求 2.2）
        // 注意：这里是串行执行，避免并发请求导致 QPS 超限
        for i in 0..<(validAttractions.count - 1) {
            let origin = validAttractions[i].coordinate!
            let destination = validAttractions[i + 1].coordinate!
            
            // 限流：确保请求之间有足够的间隔
            await throttleRequest()
            
            do {
                let segment = try await planSegmentWithRetry(
                    from: origin,
                    to: destination,
                    travelMode: travelMode,
                    citycode: citycode,
                    maxRetries: 2
                )
                segments.append(segment)
            } catch {
                // 需求 2.4: 某一段路线规划失败时，使用直线连接作为降级方案
                print("⚠️ 路线段规划失败（已重试），使用降级方案: \(error.localizedDescription)")
                let fallbackSegment = createFallbackSegment(
                    from: origin,
                    to: destination,
                    travelMode: travelMode
                )
                segments.append(fallbackSegment)
            }
        }
        
        return NavigationPath(segments: segments, travelMode: travelMode)
    }
    
    /// 限流：确保请求之间有足够的间隔
    private func throttleRequest() async {
        let now = DispatchTime.now().uptimeNanoseconds
        let elapsed = now - lastRequestTime
        
        if elapsed < requestInterval {
            let waitTime = requestInterval - elapsed
            print("⏱️ 限流等待 \(Double(waitTime) / 1_000_000)ms")
            try? await Task.sleep(nanoseconds: waitTime)
        }
        
        lastRequestTime = DispatchTime.now().uptimeNanoseconds
    }
    
    /// 带重试的路线规划
    private func planSegmentWithRetry(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?,
        maxRetries: Int
    ) async throws -> RouteSegment {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                if attempt > 0 {
                    print("🔄 重试第 \(attempt) 次...")
                    // 重试前等待更长时间
                    try await Task.sleep(nanoseconds: 500_000_000)  // 500ms
                }
                
                return try await planSegment(
                    from: origin,
                    to: destination,
                    travelMode: travelMode,
                    citycode: citycode
                )
            } catch let error as NSError {
                lastError = error
                
                // 如果是 QPS 超限错误，继续重试
                if error.code == 10021 {
                    print("⚠️ QPS 超限，等待后重试...")
                    continue
                } else {
                    // 其他错误直接抛出
                    throw error
                }
            }
        }
        
        // 所有重试都失败，抛出最后一个错误
        throw lastError ?? RouteNavigationError.routePlanningFailed("重试失败")
    }
    
    /// 规划单段路线
    /// 需求: 1.1, 1.2, 1.3, 1.4
    func planSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> RouteSegment {
        guard let searchAPI = searchAPI else {
            throw RouteNavigationError.apiNotInitialized
        }
        
        // 保存当前请求信息
        currentOrigin = origin
        currentDestination = destination
        currentTravelMode = travelMode
        
        // 根据出行方式调用对应的API
        switch travelMode {
        case .walking:
            return try await planWalkingRoute(
                searchAPI: searchAPI,
                origin: origin,
                destination: destination
            )
        case .driving:
            return try await planDrivingRoute(
                searchAPI: searchAPI,
                origin: origin,
                destination: destination
            )
        case .publicTransport:
            return try await planTransitRoute(
                searchAPI: searchAPI,
                origin: origin,
                destination: destination,
                citycode: citycode
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 规划步行路线
    /// 需求: 1.1
    private func planWalkingRoute(
        searchAPI: AMapSearchAPI,
        origin: Coordinate,
        destination: Coordinate
    ) async throws -> RouteSegment {
        return try await withCheckedThrowingContinuation { continuation in
            self.walkingContinuation = continuation
            
            let request = AMapWalkingRouteSearchRequest()
            request.origin = AMapGeoPoint.location(
                withLatitude: CGFloat(origin.latitude),
                longitude: CGFloat(origin.longitude)
            )
            request.destination = AMapGeoPoint.location(
                withLatitude: CGFloat(destination.latitude),
                longitude: CGFloat(destination.longitude)
            )
            
            // 关键：设置返回 polyline 数据
            request.showFieldsType = .polyline
            
            print("🚶 发起步行路线请求:")
            print("   起点: (\(origin.latitude), \(origin.longitude))")
            print("   终点: (\(destination.latitude), \(destination.longitude))")
            print("   showFieldsType: polyline")
            
            searchAPI.aMapWalkingRouteSearch(request)
        }
    }
    
    /// 规划驾车路线
    /// 需求: 1.3
    private func planDrivingRoute(
        searchAPI: AMapSearchAPI,
        origin: Coordinate,
        destination: Coordinate
    ) async throws -> RouteSegment {
        return try await withCheckedThrowingContinuation { continuation in
            self.drivingContinuation = continuation
            
            let request = AMapDrivingCalRouteSearchRequest()
            request.origin = AMapGeoPoint.location(
                withLatitude: CGFloat(origin.latitude),
                longitude: CGFloat(origin.longitude)
            )
            request.destination = AMapGeoPoint.location(
                withLatitude: CGFloat(destination.latitude),
                longitude: CGFloat(destination.longitude)
            )
            request.strategy = 32 // 高德推荐，同高德地图APP默认
            
            // 关键：设置返回 polyline 数据
            request.showFieldType = .polyline
            
            print("🚗 发起驾车路线请求:")
            print("   起点: (\(origin.latitude), \(origin.longitude))")
            print("   终点: (\(destination.latitude), \(destination.longitude))")
            print("   策略: \(request.strategy)")
            print("   showFieldType: polyline")
            
            searchAPI.aMapDrivingV2RouteSearch(request)
        }
    }
    
    /// 规划公交路线
    /// 需求: 1.2
    private func planTransitRoute(
        searchAPI: AMapSearchAPI,
        origin: Coordinate,
        destination: Coordinate,
        citycode: String?
    ) async throws -> RouteSegment {
        return try await withCheckedThrowingContinuation { continuation in
            self.transitContinuation = continuation
            
            let request = AMapTransitRouteSearchRequest()
            request.origin = AMapGeoPoint.location(
                withLatitude: CGFloat(origin.latitude),
                longitude: CGFloat(origin.longitude)
            )
            request.destination = AMapGeoPoint.location(
                withLatitude: CGFloat(destination.latitude),
                longitude: CGFloat(destination.longitude)
            )
            
            // 使用从高德API获取的citycode
            // 如果没有citycode，打印警告并尝试使用（可能会失败）
            if let code = citycode {
                request.city = code
                request.destinationCity = code
            } else {
                print("   ⚠️ 警告: 未提供citycode，公交路线规划可能失败")
                // 不设置city，让高德API返回错误，触发降级方案
            }
            
            // 设置策略 (0-8,包含地铁)
            request.strategy = 0 // 推荐模式,综合权重(包含地铁)
            
            // 关键：设置返回 polyline 数据
            request.showFieldsType = .polyline
            
            // 设置是否包含夜班车
            request.nightflag = false
            
            print("🚌 发起公交路线请求:")
            print("   起点: (\(origin.latitude), \(origin.longitude))")
            print("   终点: (\(destination.latitude), \(destination.longitude))")
            print("   城市代码: \(request.city ?? "未设置")")
            print("   目的地城市代码: \(request.destinationCity ?? "未设置")")
            print("   策略: \(request.strategy) (推荐模式,包含地铁)")
            print("   showFieldsType: polyline")
            
            searchAPI.aMapTransitRouteSearch(request)
        }
    }
    
    /// 根据坐标识别城市名称
    /// 使用简单的经纬度范围判断主要城市
    private func getCityName(from coordinate: Coordinate) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // 主要城市坐标范围判断
        if lat >= 39.4 && lat <= 41.1 && lon >= 115.4 && lon <= 117.5 {
            return "北京"
        } else if lat >= 30.7 && lat <= 31.9 && lon >= 120.9 && lon <= 122.0 {
            return "上海"
        } else if lat >= 29.9 && lat <= 30.6 && lon >= 119.8 && lon <= 120.5 {
            return "杭州"
        } else if lat >= 22.4 && lat <= 23.4 && lon >= 113.1 && lon <= 114.6 {
            return "广州"
        } else if lat >= 22.4 && lat <= 22.9 && lon >= 113.7 && lon <= 114.6 {
            return "深圳"
        } else if lat >= 30.1 && lat <= 31.5 && lon >= 103.6 && lon <= 104.9 {
            return "成都"
        } else if lat >= 33.8 && lat <= 34.5 && lon >= 108.7 && lon <= 109.3 {
            return "西安"
        } else if lat >= 31.8 && lat <= 32.4 && lon >= 118.4 && lon <= 119.3 {
            return "南京"
        } else if lat >= 30.3 && lat <= 31.0 && lon >= 114.0 && lon <= 114.7 {
            return "武汉"
        } else if lat >= 29.3 && lat <= 29.9 && lon >= 106.3 && lon <= 107.0 {
            return "重庆"
        } else {
            // 默认返回杭州(因为测试数据在杭州)
            return "杭州"
        }
    }
    
    /// 创建降级路线段（直线连接）
    /// 需求: 2.4, 5.1, 5.2
    private func createFallbackSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode
    ) -> RouteSegment {
        return RouteSegment.fallback(
            from: origin,
            to: destination,
            travelMode: travelMode
        )
    }
    
    /// 从步行路线响应中提取坐标点
    private func extractCoordinatesFromWalkingPath(_ path: AMapPath) -> [Coordinate] {
        var coordinates: [Coordinate] = []
        
        guard let steps = path.steps else {
            print("   ⚠️ path.steps 为空")
            return coordinates
        }
        
        print("   🔍 开始提取步行路线坐标，共 \(steps.count) 个步骤")
        
        for (index, step) in steps.enumerated() {
            if let polyline = step.polyline, !polyline.isEmpty {
                print("   步骤 \(index): polyline 长度 = \(polyline.count) 字符")
                let points = parsePolyline(polyline)
                print("   步骤 \(index): 解析出 \(points.count) 个坐标点")
                coordinates.append(contentsOf: points)
            } else {
                print("   步骤 \(index): polyline 为空或 nil")
            }
        }
        
        print("   ✅ 总共提取 \(coordinates.count) 个坐标点")
        
        return coordinates
    }
    
    /// 从驾车路线响应中提取坐标点
    private func extractCoordinatesFromDrivingPath(_ path: AMapPath) -> [Coordinate] {
        var coordinates: [Coordinate] = []
        
        guard let steps = path.steps else {
            print("   ⚠️ path.steps 为空")
            return coordinates
        }
        
        print("   🔍 开始提取驾车路线坐标，共 \(steps.count) 个步骤")
        
        for (index, step) in steps.enumerated() {
            if let polyline = step.polyline, !polyline.isEmpty {
                print("   步骤 \(index): polyline 长度 = \(polyline.count) 字符")
                let points = parsePolyline(polyline)
                print("   步骤 \(index): 解析出 \(points.count) 个坐标点")
                coordinates.append(contentsOf: points)
            } else {
                print("   步骤 \(index): polyline 为空或 nil")
            }
        }
        
        print("   ✅ 总共提取 \(coordinates.count) 个坐标点")
        
        return coordinates
    }
    
    /// 从公交路线响应中提取坐标点
    private func extractCoordinatesFromTransitPath(_ transit: AMapTransit) -> [Coordinate] {
        var coordinates: [Coordinate] = []
        
        guard let segments = transit.segments else { return coordinates }
        
        for segment in segments {
            // 步行部分
            if let walking = segment.walking, let steps = walking.steps {
                for step in steps {
                    if let polyline = step.polyline {
                        let points = parsePolyline(polyline)
                        coordinates.append(contentsOf: points)
                    }
                }
            }
            
            // 公交部分
            if let buslines = segment.buslines {
                for busline in buslines {
                    if let polyline = busline.polyline {
                        let points = parsePolyline(polyline)
                        coordinates.append(contentsOf: points)
                    }
                }
            }
            
            // 地铁/轨道交通部分
            if let railway = segment.railway {
                if let viaStops = railway.viaStops {
                    for stop in viaStops {
                        if let location = stop.location {
                            coordinates.append(Coordinate(
                                latitude: Double(location.latitude),
                                longitude: Double(location.longitude)
                            ))
                        }
                    }
                }
            }
        }
        
        return coordinates
    }
    
    /// 解析polyline字符串为坐标点数组
    /// polyline格式: "lng1,lat1;lng2,lat2;..."
    private func parsePolyline(_ polyline: String) -> [Coordinate] {
        var coordinates: [Coordinate] = []
        
        // 打印前100个字符用于调试
        let preview = String(polyline.prefix(100))
        print("      polyline 预览: \(preview)...")
        
        let points = polyline.split(separator: ";")
        print("      分割后点数: \(points.count)")
        
        for (index, point) in points.enumerated() {
            let lngLat = point.split(separator: ",")
            if lngLat.count == 2,
               let lng = Double(lngLat[0]),
               let lat = Double(lngLat[1]) {
                coordinates.append(Coordinate(latitude: lat, longitude: lng))
            } else if index < 3 {
                // 只打印前3个解析失败的点
                print("      ⚠️ 解析失败的点 \(index): \(point)")
            }
        }
        
        return coordinates
    }
}

// MARK: - AMapSearchDelegate

extension RouteNavigationService: AMapSearchDelegate {
    
    /// 步行路线搜索完成回调
    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        // 判断请求类型
        if request is AMapWalkingRouteSearchRequest {
            handleWalkingRouteResponse(response)
        } else if request is AMapDrivingCalRouteSearchRequest {
            handleDrivingRouteResponse(response)
        } else if request is AMapTransitRouteSearchRequest {
            handleTransitRouteResponse(response)
        }
    }
    
    /// 处理步行路线响应
    private func handleWalkingRouteResponse(_ response: AMapRouteSearchResponse?) {
        guard let continuation = walkingContinuation else { return }
        walkingContinuation = nil
        
        print("🚶 收到步行路线响应:")
        
        guard let response = response else {
            print("   ❌ 响应为空 (response is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let route = response.route else {
            print("   ❌ route为空 (response.route is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let paths = route.paths, !paths.isEmpty else {
            print("   ❌ paths为空或无路线 (paths count: \(route.paths?.count ?? 0))")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let firstPath = paths.first else {
            print("   ❌ 无法获取第一条路线")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        print("   ✅ 获取到路线，距离: \(firstPath.distance)米，时间: \(firstPath.duration)秒")
        print("   步骤数: \(firstPath.steps?.count ?? 0)")
        
        let coordinates = extractCoordinatesFromWalkingPath(firstPath)
        print("   提取坐标点数: \(coordinates.count)")
        
        guard let origin = currentOrigin, let destination = currentDestination else {
            continuation.resume(throwing: RouteNavigationError.invalidCoordinate)
            return
        }
        
        // 确保坐标点不为空
        let finalCoordinates = coordinates.isEmpty ? [origin, destination] : coordinates
        let isFallback = coordinates.isEmpty
        
        if isFallback {
            print("   ⚠️ 坐标点为空，使用起终点作为降级方案")
        }
        
        let segment = RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: finalCoordinates,
            travelMode: .walking,
            distance: Int(firstPath.distance),
            duration: Int(firstPath.duration),
            isFallback: isFallback
        )
        
        continuation.resume(returning: segment)
    }
    
    /// 处理驾车路线响应
    private func handleDrivingRouteResponse(_ response: AMapRouteSearchResponse?) {
        guard let continuation = drivingContinuation else { return }
        drivingContinuation = nil
        
        print("🚗 收到驾车路线响应:")
        
        guard let response = response else {
            print("   ❌ 响应为空 (response is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let route = response.route else {
            print("   ❌ route为空 (response.route is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let paths = route.paths, !paths.isEmpty else {
            print("   ❌ paths为空或无路线 (paths count: \(route.paths?.count ?? 0))")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let firstPath = paths.first else {
            print("   ❌ 无法获取第一条路线")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        print("   ✅ 获取到路线，距离: \(firstPath.distance)米，时间: \(firstPath.duration)秒")
        print("   步骤数: \(firstPath.steps?.count ?? 0)")
        
        let coordinates = extractCoordinatesFromDrivingPath(firstPath)
        print("   提取坐标点数: \(coordinates.count)")
        
        guard let origin = currentOrigin, let destination = currentDestination else {
            continuation.resume(throwing: RouteNavigationError.invalidCoordinate)
            return
        }
        
        // 确保坐标点不为空
        let finalCoordinates = coordinates.isEmpty ? [origin, destination] : coordinates
        let isFallback = coordinates.isEmpty
        
        if isFallback {
            print("   ⚠️ 坐标点为空，使用起终点作为降级方案")
        }
        
        let segment = RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: finalCoordinates,
            travelMode: .driving,
            distance: Int(firstPath.distance),
            duration: Int(firstPath.duration),
            isFallback: isFallback
        )
        
        continuation.resume(returning: segment)
    }
    
    /// 处理公交路线响应
    private func handleTransitRouteResponse(_ response: AMapRouteSearchResponse?) {
        guard let continuation = transitContinuation else { return }
        transitContinuation = nil
        
        print("🚌 收到公交路线响应:")
        
        guard let response = response else {
            print("   ❌ 响应为空 (response is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let route = response.route else {
            print("   ❌ route为空 (response.route is nil)")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let transits = route.transits, !transits.isEmpty else {
            print("   ❌ transits为空或无路线 (transits count: \(route.transits?.count ?? 0))")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        guard let firstTransit = transits.first else {
            print("   ❌ 无法获取第一条路线")
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: RouteNavigationError.noRouteAvailable)
            }
            return
        }
        
        print("   ✅ 获取到路线，距离: \(firstTransit.distance)米，时间: \(firstTransit.duration)秒")
        print("   换乘段数: \(firstTransit.segments?.count ?? 0)")
        
        let coordinates = extractCoordinatesFromTransitPath(firstTransit)
        print("   提取坐标点数: \(coordinates.count)")
        
        guard let origin = currentOrigin, let destination = currentDestination else {
            continuation.resume(throwing: RouteNavigationError.invalidCoordinate)
            return
        }
        
        // 确保坐标点不为空
        let finalCoordinates = coordinates.isEmpty ? [origin, destination] : coordinates
        let isFallback = coordinates.isEmpty
        
        if isFallback {
            print("   ⚠️ 坐标点为空，使用起终点作为降级方案")
        }
        
        let segment = RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: finalCoordinates,
            travelMode: .publicTransport,
            distance: Int(firstTransit.distance),
            duration: Int(firstTransit.duration),
            isFallback: isFallback
        )
        
        continuation.resume(returning: segment)
    }
    
    /// 搜索失败回调
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        let nsError = error as NSError
        print("❌ 路径规划搜索失败:")
        print("   错误码: \(nsError.code)")
        print("   错误域: \(nsError.domain)")
        print("   错误描述: \(nsError.localizedDescription)")
        if let userInfo = nsError.userInfo as? [String: Any], !userInfo.isEmpty {
            print("   详细信息: \(userInfo)")
        }
        
        // 打印请求类型
        if request is AMapWalkingRouteSearchRequest {
            print("   请求类型: 步行路线")
        } else if request is AMapDrivingCalRouteSearchRequest {
            print("   请求类型: 驾车路线")
        } else if request is AMapTransitRouteSearchRequest {
            print("   请求类型: 公交路线")
        }
        
        let routeError = RouteNavigationError.routePlanningFailed(error.localizedDescription)
        
        // 处理步行路线错误
        if let continuation = walkingContinuation {
            walkingContinuation = nil
            // 使用降级方案而不是抛出错误
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                print("   🔄 使用降级方案（直线连接）")
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: routeError)
            }
        }
        
        // 处理驾车路线错误
        if let continuation = drivingContinuation {
            drivingContinuation = nil
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                print("   🔄 使用降级方案（直线连接）")
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: routeError)
            }
        }
        
        // 处理公交路线错误
        if let continuation = transitContinuation {
            transitContinuation = nil
            if let origin = currentOrigin, let destination = currentDestination, let mode = currentTravelMode {
                print("   🔄 使用降级方案（直线连接）")
                continuation.resume(returning: createFallbackSegment(from: origin, to: destination, travelMode: mode))
            } else {
                continuation.resume(throwing: routeError)
            }
        }
    }
}
