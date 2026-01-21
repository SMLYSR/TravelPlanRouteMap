import XCTest
@testable import TravelPlanRouteMap

/// NavigationPath 属性测试
/// **Feature: route-navigation-display**
final class NavigationPathPropertyTests: XCTestCase {
    
    // MARK: - Property 4: 坐标点合并的正确性
    
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    ///
    /// 对于任意NavigationPath，allCoordinates属性返回的坐标点序列应该：
    /// 1. 以第一个路线段的起点开始
    /// 2. 以最后一个路线段的终点结束
    /// 3. 不包含重复的相邻坐标点（相邻路线段的连接点只出现一次）
    ///
    /// 测试策略：
    /// - 生成随机的NavigationPath
    /// - 验证allCoordinates的首尾坐标
    /// - 验证相邻路线段连接点不重复
    func testAllCoordinatesMergeCorrectness() {
        // 运行至少100次迭代
        for iteration in 1...100 {
            // Given - 生成随机的NavigationPath（至少2个路线段以测试合并）
            let segmentCount = Int.random(in: 2...10)
            let travelMode = TravelMode.allCases.randomElement()!
            let segments = generateConnectedRouteSegments(count: segmentCount, travelMode: travelMode)
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // When - 获取合并后的坐标点
            let allCoordinates = navigationPath.allCoordinates
            
            // Then - 验证Property 4的三个条件
            
            // 条件1: 以第一个路线段的起点开始
            let firstSegmentFirstCoord = segments[0].pathCoordinates.first!
            XCTAssertEqual(
                allCoordinates.first?.latitude,
                firstSegmentFirstCoord.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): allCoordinates应以第一个路线段的起点开始（纬度）"
            )
            XCTAssertEqual(
                allCoordinates.first?.longitude,
                firstSegmentFirstCoord.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): allCoordinates应以第一个路线段的起点开始（经度）"
            )
            
            // 条件2: 以最后一个路线段的终点结束
            let lastSegmentLastCoord = segments.last!.pathCoordinates.last!
            XCTAssertEqual(
                allCoordinates.last?.latitude,
                lastSegmentLastCoord.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): allCoordinates应以最后一个路线段的终点结束（纬度）"
            )
            XCTAssertEqual(
                allCoordinates.last?.longitude,
                lastSegmentLastCoord.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): allCoordinates应以最后一个路线段的终点结束（经度）"
            )
            
            // 条件3: 验证坐标点数量正确（不包含重复的连接点）
            // 预期数量 = 所有路线段的坐标点总数 - (路线段数量 - 1)
            // 因为每个连接点只应出现一次
            let totalPathCoordinates = segments.reduce(0) { $0 + $1.pathCoordinates.count }
            let expectedCoordinateCount = totalPathCoordinates - (segmentCount - 1)
            XCTAssertEqual(
                allCoordinates.count,
                expectedCoordinateCount,
                "迭代 \(iteration): allCoordinates数量应为\(expectedCoordinateCount)（总坐标点\(totalPathCoordinates) - 重复连接点\(segmentCount - 1)）"
            )
            
            if iteration % 20 == 0 {
                print("Property 4 测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试单个路线段的allCoordinates
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    func testAllCoordinatesWithSingleSegment() {
        for iteration in 1...50 {
            // Given - 单个路线段
            let segment = generateRandomRouteSegment()
            let navigationPath = NavigationPath(segments: [segment], travelMode: segment.travelMode)
            
            // When
            let allCoordinates = navigationPath.allCoordinates
            
            // Then - 单个路线段时，allCoordinates应与pathCoordinates完全相同
            XCTAssertEqual(
                allCoordinates.count,
                segment.pathCoordinates.count,
                "迭代 \(iteration): 单个路线段时，allCoordinates数量应与pathCoordinates相同"
            )
            
            for (index, coord) in segment.pathCoordinates.enumerated() {
                XCTAssertEqual(
                    allCoordinates[index].latitude,
                    coord.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 坐标 \(index): 纬度应相同"
                )
                XCTAssertEqual(
                    allCoordinates[index].longitude,
                    coord.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 坐标 \(index): 经度应相同"
                )
            }
        }
    }
    
    /// 测试空路线段数组的allCoordinates
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    func testAllCoordinatesWithEmptySegments() {
        // Given - 空路线段数组
        let navigationPath = NavigationPath(segments: [], travelMode: .walking)
        
        // When
        let allCoordinates = navigationPath.allCoordinates
        
        // Then - 应返回空数组
        XCTAssertTrue(allCoordinates.isEmpty, "空路线段数组时，allCoordinates应为空")
    }
    
    /// 测试连续路线段的连接点不重复
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    func testNoAdjacentDuplicateCoordinates() {
        for iteration in 1...100 {
            // Given - 生成连续的路线段
            let segmentCount = Int.random(in: 2...10)
            let travelMode = TravelMode.allCases.randomElement()!
            let segments = generateConnectedRouteSegments(count: segmentCount, travelMode: travelMode)
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // When
            let allCoordinates = navigationPath.allCoordinates
            
            // Then - 验证没有相邻的重复坐标点
            for i in 0..<(allCoordinates.count - 1) {
                let current = allCoordinates[i]
                let next = allCoordinates[i + 1]
                
                // 相邻坐标点不应完全相同（允许非常小的差异）
                let isSameLatitude = abs(current.latitude - next.latitude) < 0.0000001
                let isSameLongitude = abs(current.longitude - next.longitude) < 0.0000001
                let isDuplicate = isSameLatitude && isSameLongitude
                
                XCTAssertFalse(
                    isDuplicate,
                    "迭代 \(iteration): 坐标点\(i)和\(i+1)不应重复"
                )
            }
            
            if iteration % 20 == 0 {
                print("无重复坐标点测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试降级路线段的allCoordinates合并
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    func testAllCoordinatesWithFallbackSegments() {
        for iteration in 1...50 {
            // Given - 生成包含降级路线段的NavigationPath
            let segmentCount = Int.random(in: 2...5)
            let travelMode = TravelMode.allCases.randomElement()!
            var segments: [RouteSegment] = []
            var previousDestination = generateRandomCoordinate()
            
            for _ in 0..<segmentCount {
                let origin = previousDestination
                let destination = generateRandomCoordinate()
                
                // 创建降级路线段（只有2个坐标点）
                let segment = RouteSegment.fallback(
                    from: origin,
                    to: destination,
                    travelMode: travelMode
                )
                segments.append(segment)
                previousDestination = destination
            }
            
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // When
            let allCoordinates = navigationPath.allCoordinates
            
            // Then - 降级路线段每个只有2个坐标点
            // 预期数量 = 2 * segmentCount - (segmentCount - 1) = segmentCount + 1
            let expectedCount = segmentCount + 1
            XCTAssertEqual(
                allCoordinates.count,
                expectedCount,
                "迭代 \(iteration): 降级路线段的allCoordinates数量应为\(expectedCount)"
            )
            
            // 验证首尾坐标
            XCTAssertEqual(
                allCoordinates.first?.latitude,
                segments[0].origin.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 首坐标应为第一个路线段的起点"
            )
            XCTAssertEqual(
                allCoordinates.last?.latitude,
                segments.last!.destination.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 尾坐标应为最后一个路线段的终点"
            )
        }
    }
    
    /// 测试混合路线段（正常+降级）的allCoordinates合并
    /// **Feature: route-navigation-display, Property 4: 坐标点合并的正确性**
    /// **Validates: Requirements 2.3**
    func testAllCoordinatesWithMixedSegments() {
        for iteration in 1...50 {
            // Given - 生成混合路线段
            let segmentCount = Int.random(in: 3...6)
            let travelMode = TravelMode.allCases.randomElement()!
            var segments: [RouteSegment] = []
            var previousDestination = generateRandomCoordinate()
            var totalPathCoordinates = 0
            
            for i in 0..<segmentCount {
                let origin = previousDestination
                let destination = generateRandomCoordinate()
                
                // 交替创建正常和降级路线段
                if i % 2 == 0 {
                    // 正常路线段
                    let pathCoordinateCount = Int.random(in: 3...8)
                    var pathCoordinates: [Coordinate] = [origin]
                    for _ in 1..<(pathCoordinateCount - 1) {
                        pathCoordinates.append(generateRandomCoordinate())
                    }
                    pathCoordinates.append(destination)
                    
                    let segment = RouteSegment(
                        origin: origin,
                        destination: destination,
                        pathCoordinates: pathCoordinates,
                        travelMode: travelMode,
                        distance: Int.random(in: 100...10000),
                        duration: Int.random(in: 60...3600),
                        isFallback: false
                    )
                    segments.append(segment)
                    totalPathCoordinates += pathCoordinates.count
                } else {
                    // 降级路线段
                    let segment = RouteSegment.fallback(
                        from: origin,
                        to: destination,
                        travelMode: travelMode
                    )
                    segments.append(segment)
                    totalPathCoordinates += 2
                }
                
                previousDestination = destination
            }
            
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // When
            let allCoordinates = navigationPath.allCoordinates
            
            // Then - 验证坐标点数量
            let expectedCount = totalPathCoordinates - (segmentCount - 1)
            XCTAssertEqual(
                allCoordinates.count,
                expectedCount,
                "迭代 \(iteration): 混合路线段的allCoordinates数量应为\(expectedCount)"
            )
            
            // 验证首尾坐标
            XCTAssertEqual(
                allCoordinates.first?.latitude,
                segments[0].pathCoordinates.first?.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 首坐标应正确"
            )
            XCTAssertEqual(
                allCoordinates.last?.latitude,
                segments.last!.pathCoordinates.last?.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 尾坐标应正确"
            )
        }
    }
    
    // MARK: - Property 6: NavigationPath序列化往返一致性
    /// **Feature: route-navigation-display, Property 6: NavigationPath序列化往返一致性**
    /// **Validates: Requirements 4.4**
    ///
    /// 对于任意有效的NavigationPath对象，将其编码为JSON后再解码，
    /// 应该得到与原对象等价的NavigationPath。
    func testNavigationPathSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // 运行至少100次迭代
        for iteration in 1...100 {
            // Given - 生成随机的NavigationPath
            let navigationPath = generateRandomNavigationPath()
            
            // When - 编码为JSON
            let jsonData = try encoder.encode(navigationPath)
            
            // Then - 解码后应与原对象等价
            let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
            
            // 验证segments数组长度相同
            XCTAssertEqual(
                decodedPath.segments.count,
                navigationPath.segments.count,
                "迭代 \(iteration): 解码后的segments数量应与原对象相同"
            )
            
            // 验证travelMode相同
            XCTAssertEqual(
                decodedPath.travelMode,
                navigationPath.travelMode,
                "迭代 \(iteration): 解码后的travelMode应与原对象相同"
            )
            
            // 验证每个segment的详细内容
            for (index, segment) in navigationPath.segments.enumerated() {
                let decodedSegment = decodedPath.segments[index]
                
                // 验证origin坐标
                XCTAssertEqual(
                    decodedSegment.origin.latitude,
                    segment.origin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), segment \(index): origin.latitude应相同"
                )
                XCTAssertEqual(
                    decodedSegment.origin.longitude,
                    segment.origin.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), segment \(index): origin.longitude应相同"
                )
                
                // 验证destination坐标
                XCTAssertEqual(
                    decodedSegment.destination.latitude,
                    segment.destination.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), segment \(index): destination.latitude应相同"
                )
                XCTAssertEqual(
                    decodedSegment.destination.longitude,
                    segment.destination.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), segment \(index): destination.longitude应相同"
                )
                
                // 验证pathCoordinates数量
                XCTAssertEqual(
                    decodedSegment.pathCoordinates.count,
                    segment.pathCoordinates.count,
                    "迭代 \(iteration), segment \(index): pathCoordinates数量应相同"
                )
                
                // 验证pathCoordinates内容
                for (coordIndex, coord) in segment.pathCoordinates.enumerated() {
                    let decodedCoord = decodedSegment.pathCoordinates[coordIndex]
                    XCTAssertEqual(
                        decodedCoord.latitude,
                        coord.latitude,
                        accuracy: 0.000001,
                        "迭代 \(iteration), segment \(index), coord \(coordIndex): latitude应相同"
                    )
                    XCTAssertEqual(
                        decodedCoord.longitude,
                        coord.longitude,
                        accuracy: 0.000001,
                        "迭代 \(iteration), segment \(index), coord \(coordIndex): longitude应相同"
                    )
                }
                
                // 验证travelMode
                XCTAssertEqual(
                    decodedSegment.travelMode,
                    segment.travelMode,
                    "迭代 \(iteration), segment \(index): travelMode应相同"
                )
                
                // 验证distance
                XCTAssertEqual(
                    decodedSegment.distance,
                    segment.distance,
                    "迭代 \(iteration), segment \(index): distance应相同"
                )
                
                // 验证duration
                XCTAssertEqual(
                    decodedSegment.duration,
                    segment.duration,
                    "迭代 \(iteration), segment \(index): duration应相同"
                )
                
                // 验证isFallback
                XCTAssertEqual(
                    decodedSegment.isFallback,
                    segment.isFallback,
                    "迭代 \(iteration), segment \(index): isFallback应相同"
                )
            }
            
            // 验证计算属性也一致
            XCTAssertEqual(
                decodedPath.totalDistance,
                navigationPath.totalDistance,
                "迭代 \(iteration): totalDistance应相同"
            )
            XCTAssertEqual(
                decodedPath.totalDuration,
                navigationPath.totalDuration,
                "迭代 \(iteration): totalDuration应相同"
            )
            XCTAssertEqual(
                decodedPath.hasFallbackSegments,
                navigationPath.hasFallbackSegments,
                "迭代 \(iteration): hasFallbackSegments应相同"
            )
            XCTAssertEqual(
                decodedPath.fallbackSegmentCount,
                navigationPath.fallbackSegmentCount,
                "迭代 \(iteration): fallbackSegmentCount应相同"
            )
            
            // 验证allCoordinates计算属性
            let originalCoords = navigationPath.allCoordinates
            let decodedCoords = decodedPath.allCoordinates
            XCTAssertEqual(
                decodedCoords.count,
                originalCoords.count,
                "迭代 \(iteration): allCoordinates数量应相同"
            )
            
            // 使用Equatable验证整体相等性
            XCTAssertEqual(
                decodedPath,
                navigationPath,
                "迭代 \(iteration): 解码后的NavigationPath应与原对象完全相等"
            )
            
            if iteration % 20 == 0 {
                print("Property 6 测试进度: \(iteration)/100")
            }
        }
    }
    
    // MARK: - 边界情况测试
    
    /// 测试空segments数组的序列化往返
    func testEmptySegmentsSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Given - 空segments的NavigationPath
        let emptyPath = NavigationPath(segments: [], travelMode: .walking)
        
        // When
        let jsonData = try encoder.encode(emptyPath)
        let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedPath, emptyPath, "空segments的NavigationPath序列化往返应一致")
        XCTAssertTrue(decodedPath.segments.isEmpty, "解码后segments应为空")
        XCTAssertEqual(decodedPath.travelMode, .walking, "travelMode应保持一致")
    }
    
    /// 测试单个segment的序列化往返
    func testSingleSegmentSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for mode in TravelMode.allCases {
            // Given
            let segment = generateRandomRouteSegment(travelMode: mode)
            let path = NavigationPath(segments: [segment], travelMode: mode)
            
            // When
            let jsonData = try encoder.encode(path)
            let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedPath, path, "单segment的NavigationPath序列化往返应一致 (mode: \(mode))")
        }
    }
    
    /// 测试包含降级路线段的序列化往返
    func testFallbackSegmentsSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for _ in 1...20 {
            // Given - 生成包含降级路线段的NavigationPath
            let segmentCount = Int.random(in: 2...5)
            var segments: [RouteSegment] = []
            
            for _ in 0..<segmentCount {
                let origin = generateRandomCoordinate()
                let destination = generateRandomCoordinate()
                let mode = TravelMode.allCases.randomElement()!
                
                // 随机决定是否为降级路线段
                if Bool.random() {
                    segments.append(RouteSegment.fallback(from: origin, to: destination, travelMode: mode))
                } else {
                    segments.append(generateRandomRouteSegment(travelMode: mode))
                }
            }
            
            let path = NavigationPath(segments: segments, travelMode: TravelMode.allCases.randomElement()!)
            
            // When
            let jsonData = try encoder.encode(path)
            let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedPath, path, "包含降级路线段的NavigationPath序列化往返应一致")
            XCTAssertEqual(decodedPath.hasFallbackSegments, path.hasFallbackSegments)
            XCTAssertEqual(decodedPath.fallbackSegmentCount, path.fallbackSegmentCount)
        }
    }
    
    /// 测试极端坐标值的序列化往返
    func testExtremeCoordinatesSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // 测试边界坐标值
        let extremeCoordinates = [
            Coordinate(latitude: 90.0, longitude: 180.0),      // 最大值
            Coordinate(latitude: -90.0, longitude: -180.0),    // 最小值
            Coordinate(latitude: 0.0, longitude: 0.0),         // 零点
            Coordinate(latitude: 39.9042, longitude: 116.4074) // 北京坐标（典型值）
        ]
        
        for (index, coord) in extremeCoordinates.enumerated() {
            // Given
            let segment = RouteSegment(
                origin: coord,
                destination: extremeCoordinates[(index + 1) % extremeCoordinates.count],
                pathCoordinates: [coord, extremeCoordinates[(index + 1) % extremeCoordinates.count]],
                travelMode: .driving,
                distance: 1000,
                duration: 600,
                isFallback: false
            )
            let path = NavigationPath(segments: [segment], travelMode: .driving)
            
            // When
            let jsonData = try encoder.encode(path)
            let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedPath, path, "极端坐标值的NavigationPath序列化往返应一致")
        }
    }
    
    /// 测试大量路径坐标点的序列化往返
    func testLargePathCoordinatesSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Given - 生成包含大量坐标点的路线段
        let pathCoordinateCount = 500
        var pathCoordinates: [Coordinate] = []
        for i in 0..<pathCoordinateCount {
            pathCoordinates.append(Coordinate(
                latitude: 39.9 + Double(i) * 0.001,
                longitude: 116.4 + Double(i) * 0.001
            ))
        }
        
        let segment = RouteSegment(
            origin: pathCoordinates.first!,
            destination: pathCoordinates.last!,
            pathCoordinates: pathCoordinates,
            travelMode: .driving,
            distance: 50000,
            duration: 3600,
            isFallback: false
        )
        let path = NavigationPath(segments: [segment], travelMode: .driving)
        
        // When
        let jsonData = try encoder.encode(path)
        let decodedPath = try decoder.decode(NavigationPath.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedPath, path, "大量坐标点的NavigationPath序列化往返应一致")
        XCTAssertEqual(decodedPath.segments[0].pathCoordinates.count, pathCoordinateCount)
    }
    
    // MARK: - 辅助方法
    
    /// 生成随机坐标
    private func generateRandomCoordinate() -> Coordinate {
        return Coordinate(
            latitude: Double.random(in: -90...90),
            longitude: Double.random(in: -180...180)
        )
    }
    
    /// 生成随机路线段
    private func generateRandomRouteSegment(travelMode: TravelMode? = nil) -> RouteSegment {
        let mode = travelMode ?? TravelMode.allCases.randomElement()!
        let origin = generateRandomCoordinate()
        let destination = generateRandomCoordinate()
        
        // 生成随机数量的路径坐标点（2-20个）
        let pathCoordinateCount = Int.random(in: 2...20)
        var pathCoordinates: [Coordinate] = [origin]
        
        for _ in 1..<(pathCoordinateCount - 1) {
            pathCoordinates.append(generateRandomCoordinate())
        }
        pathCoordinates.append(destination)
        
        // 随机决定是否有distance和duration
        let hasDistance = Bool.random()
        let hasDuration = Bool.random()
        
        return RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: pathCoordinates,
            travelMode: mode,
            distance: hasDistance ? Int.random(in: 100...100000) : nil,
            duration: hasDuration ? Int.random(in: 60...36000) : nil,
            isFallback: false
        )
    }
    
    /// 生成随机NavigationPath
    private func generateRandomNavigationPath() -> NavigationPath {
        let travelMode = TravelMode.allCases.randomElement()!
        
        // 生成随机数量的路线段（1-10个）
        let segmentCount = Int.random(in: 1...10)
        var segments: [RouteSegment] = []
        
        for _ in 0..<segmentCount {
            // 随机决定是否为降级路线段（20%概率）
            if Int.random(in: 1...5) == 1 {
                let origin = generateRandomCoordinate()
                let destination = generateRandomCoordinate()
                segments.append(RouteSegment.fallback(from: origin, to: destination, travelMode: travelMode))
            } else {
                segments.append(generateRandomRouteSegment(travelMode: travelMode))
            }
        }
        
        return NavigationPath(segments: segments, travelMode: travelMode)
    }
    
    /// 生成连续的路线段（前一段的终点等于后一段的起点）
    /// 用于测试坐标点合并的正确性
    private func generateConnectedRouteSegments(count: Int, travelMode: TravelMode) -> [RouteSegment] {
        var segments: [RouteSegment] = []
        var previousDestination = generateRandomCoordinate()
        
        for _ in 0..<count {
            let origin = previousDestination
            let destination = generateRandomCoordinate()
            
            // 生成路径坐标点（确保首尾与origin/destination一致）
            let pathCoordinateCount = Int.random(in: 3...10)
            var pathCoordinates: [Coordinate] = [origin]
            
            for _ in 1..<(pathCoordinateCount - 1) {
                pathCoordinates.append(generateRandomCoordinate())
            }
            pathCoordinates.append(destination)
            
            let segment = RouteSegment(
                origin: origin,
                destination: destination,
                pathCoordinates: pathCoordinates,
                travelMode: travelMode,
                distance: Int.random(in: 100...10000),
                duration: Int.random(in: 60...3600),
                isFallback: false
            )
            segments.append(segment)
            
            // 下一段的起点是当前段的终点
            previousDestination = destination
        }
        
        return segments
    }
}
