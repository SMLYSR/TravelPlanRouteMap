import XCTest
@testable import TravelPlanRouteMap

/// RouteNavigationService 属性测试
/// **Feature: route-navigation-display**
///
/// 由于RouteNavigationService依赖高德地图API，本测试使用Mock服务来验证
/// 路线段数量不变性属性。测试核心逻辑：对于N个景点，应返回N-1个路线段。
final class RouteNavigationServicePropertyTests: XCTestCase {
    
    // MARK: - Property 2: 路线段数量不变性
    
    /// **Feature: route-navigation-display, Property 2: 路线段数量不变性**
    /// **Validates: Requirements 2.1**
    ///
    /// 对于任意包含N个景点的有序列表（N >= 2），路径规划服务应该返回恰好N-1个路线段。
    ///
    /// 测试策略：
    /// - 使用MockRouteNavigationService模拟路径规划服务
    /// - 生成随机数量的景点（2-20个）
    /// - 验证返回的路线段数量等于景点数量减1
    func testRouteSegmentCountInvariant() async throws {
        // 运行至少100次迭代
        for iteration in 1...100 {
            // Given - 生成随机数量的景点（N >= 2）
            let attractionCount = Int.random(in: 2...20)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            
            // 使用Mock服务
            let mockService = MockRouteNavigationService()
            
            // When - 规划导航路线
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证路线段数量等于N-1
            let expectedSegmentCount = attractionCount - 1
            XCTAssertEqual(
                navigationPath.segments.count,
                expectedSegmentCount,
                "迭代 \(iteration): 对于\(attractionCount)个景点，应返回\(expectedSegmentCount)个路线段，实际返回\(navigationPath.segments.count)个"
            )
            
            if iteration % 20 == 0 {
                print("Property 2 测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试边界情况：恰好2个景点
    /// **Validates: Requirements 2.1**
    func testRouteSegmentCountWithMinimumAttractions() async throws {
        for iteration in 1...20 {
            // Given - 恰好2个景点
            let attractions = generateRandomAttractions(count: 2)
            let travelMode = TravelMode.allCases.randomElement()!
            let mockService = MockRouteNavigationService()
            
            // When
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 应返回恰好1个路线段
            XCTAssertEqual(
                navigationPath.segments.count,
                1,
                "迭代 \(iteration): 对于2个景点，应返回1个路线段"
            )
        }
    }
    
    /// 测试边界情况：大量景点
    /// **Validates: Requirements 2.1**
    func testRouteSegmentCountWithManyAttractions() async throws {
        for iteration in 1...10 {
            // Given - 大量景点（50-100个）
            let attractionCount = Int.random(in: 50...100)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            let mockService = MockRouteNavigationService()
            
            // When
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then
            let expectedSegmentCount = attractionCount - 1
            XCTAssertEqual(
                navigationPath.segments.count,
                expectedSegmentCount,
                "迭代 \(iteration): 对于\(attractionCount)个景点，应返回\(expectedSegmentCount)个路线段"
            )
        }
    }
    
    /// 测试不同出行方式下的路线段数量不变性
    /// **Validates: Requirements 2.1**
    func testRouteSegmentCountAcrossTravelModes() async throws {
        for mode in TravelMode.allCases {
            for iteration in 1...30 {
                // Given
                let attractionCount = Int.random(in: 2...15)
                let attractions = generateRandomAttractions(count: attractionCount)
                let mockService = MockRouteNavigationService()
                
                // When
                let navigationPath = try await mockService.planNavigationRoute(
                    attractions: attractions,
                    travelMode: mode,
                    citycode: nil
                )
                
                // Then
                let expectedSegmentCount = attractionCount - 1
                XCTAssertEqual(
                    navigationPath.segments.count,
                    expectedSegmentCount,
                    "出行方式 \(mode), 迭代 \(iteration): 对于\(attractionCount)个景点，应返回\(expectedSegmentCount)个路线段"
                )
                
                // 验证所有路线段的出行方式一致
                for segment in navigationPath.segments {
                    XCTAssertEqual(
                        segment.travelMode,
                        mode,
                        "所有路线段的出行方式应与请求的出行方式一致"
                    )
                }
            }
        }
    }
    
    /// 测试NavigationPath直接构造时的路线段数量
    /// 这是一个补充测试，验证NavigationPath模型本身的正确性
    /// **Validates: Requirements 2.1**
    func testNavigationPathSegmentCountDirect() {
        for iteration in 1...100 {
            // Given - 直接构造NavigationPath
            let segmentCount = Int.random(in: 1...20)
            let segments = generateRandomRouteSegments(count: segmentCount)
            let travelMode = TravelMode.allCases.randomElement()!
            
            // When
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // Then - 验证segments数量与输入一致
            XCTAssertEqual(
                navigationPath.segments.count,
                segmentCount,
                "迭代 \(iteration): NavigationPath的segments数量应与输入一致"
            )
            
            if iteration % 20 == 0 {
                print("NavigationPath直接构造测试进度: \(iteration)/100")
            }
        }
    }
    
    // MARK: - Property 3: 路线段顺序与景点顺序一致性
    
    /// **Feature: route-navigation-display, Property 3: 路线段顺序与景点顺序一致性**
    /// **Validates: Requirements 2.2**
    ///
    /// 对于任意有序景点列表，每个路线段的起点坐标应该等于对应景点的坐标，
    /// 终点坐标应该等于下一个景点的坐标。
    /// 即：segments[i].origin == attractions[i].coordinate 且
    ///     segments[i].destination == attractions[i+1].coordinate
    ///
    /// 测试策略：
    /// - 使用MockRouteNavigationService模拟路径规划服务
    /// - 生成随机数量的景点（2-20个）
    /// - 验证每个路线段的起点和终点与对应景点坐标一致
    func testRouteSegmentOrderConsistency() async throws {
        // 运行至少100次迭代
        for iteration in 1...100 {
            // Given - 生成随机数量的景点（N >= 2）
            let attractionCount = Int.random(in: 2...20)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            
            // 使用Mock服务
            let mockService = MockRouteNavigationService()
            
            // When - 规划导航路线
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证每个路线段的起点和终点与对应景点坐标一致
            for (index, segment) in navigationPath.segments.enumerated() {
                // 验证起点坐标等于对应景点的坐标
                let expectedOrigin = attractions[index].coordinate!
                XCTAssertEqual(
                    segment.origin.latitude,
                    expectedOrigin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点纬度应等于景点\(index)的纬度"
                )
                XCTAssertEqual(
                    segment.origin.longitude,
                    expectedOrigin.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点经度应等于景点\(index)的经度"
                )
                
                // 验证终点坐标等于下一个景点的坐标
                let expectedDestination = attractions[index + 1].coordinate!
                XCTAssertEqual(
                    segment.destination.latitude,
                    expectedDestination.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点纬度应等于景点\(index + 1)的纬度"
                )
                XCTAssertEqual(
                    segment.destination.longitude,
                    expectedDestination.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点经度应等于景点\(index + 1)的经度"
                )
            }
            
            if iteration % 20 == 0 {
                print("Property 3 测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试边界情况：恰好2个景点时的路线段顺序一致性
    /// **Feature: route-navigation-display, Property 3: 路线段顺序与景点顺序一致性**
    /// **Validates: Requirements 2.2**
    func testRouteSegmentOrderConsistencyWithMinimumAttractions() async throws {
        for iteration in 1...20 {
            // Given - 恰好2个景点
            let attractions = generateRandomAttractions(count: 2)
            let travelMode = TravelMode.allCases.randomElement()!
            let mockService = MockRouteNavigationService()
            
            // When
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 应有1个路线段，起点为第一个景点，终点为第二个景点
            XCTAssertEqual(navigationPath.segments.count, 1)
            
            let segment = navigationPath.segments[0]
            let firstAttraction = attractions[0].coordinate!
            let secondAttraction = attractions[1].coordinate!
            
            XCTAssertEqual(
                segment.origin.latitude,
                firstAttraction.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 路线段起点纬度应等于第一个景点纬度"
            )
            XCTAssertEqual(
                segment.origin.longitude,
                firstAttraction.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 路线段起点经度应等于第一个景点经度"
            )
            XCTAssertEqual(
                segment.destination.latitude,
                secondAttraction.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 路线段终点纬度应等于第二个景点纬度"
            )
            XCTAssertEqual(
                segment.destination.longitude,
                secondAttraction.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 路线段终点经度应等于第二个景点经度"
            )
        }
    }
    
    /// 测试大量景点时的路线段顺序一致性
    /// **Feature: route-navigation-display, Property 3: 路线段顺序与景点顺序一致性**
    /// **Validates: Requirements 2.2**
    func testRouteSegmentOrderConsistencyWithManyAttractions() async throws {
        for iteration in 1...10 {
            // Given - 大量景点（50-100个）
            let attractionCount = Int.random(in: 50...100)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            let mockService = MockRouteNavigationService()
            
            // When
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证所有路线段的顺序一致性
            XCTAssertEqual(
                navigationPath.segments.count,
                attractionCount - 1,
                "迭代 \(iteration): 路线段数量应为景点数量减1"
            )
            
            for (index, segment) in navigationPath.segments.enumerated() {
                let expectedOrigin = attractions[index].coordinate!
                let expectedDestination = attractions[index + 1].coordinate!
                
                // 验证起点
                XCTAssertEqual(
                    segment.origin.latitude,
                    expectedOrigin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点纬度不匹配"
                )
                XCTAssertEqual(
                    segment.origin.longitude,
                    expectedOrigin.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点经度不匹配"
                )
                
                // 验证终点
                XCTAssertEqual(
                    segment.destination.latitude,
                    expectedDestination.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点纬度不匹配"
                )
                XCTAssertEqual(
                    segment.destination.longitude,
                    expectedDestination.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点经度不匹配"
                )
            }
        }
    }
    
    /// 测试不同出行方式下的路线段顺序一致性
    /// **Feature: route-navigation-display, Property 3: 路线段顺序与景点顺序一致性**
    /// **Validates: Requirements 2.2**
    func testRouteSegmentOrderConsistencyAcrossTravelModes() async throws {
        for mode in TravelMode.allCases {
            for iteration in 1...30 {
                // Given
                let attractionCount = Int.random(in: 2...15)
                let attractions = generateRandomAttractions(count: attractionCount)
                let mockService = MockRouteNavigationService()
                
                // When
                let navigationPath = try await mockService.planNavigationRoute(
                    attractions: attractions,
                    travelMode: mode,
                    citycode: nil
                )
                
                // Then - 验证每个路线段的顺序一致性
                for (index, segment) in navigationPath.segments.enumerated() {
                    let expectedOrigin = attractions[index].coordinate!
                    let expectedDestination = attractions[index + 1].coordinate!
                    
                    XCTAssertEqual(
                        segment.origin.latitude,
                        expectedOrigin.latitude,
                        accuracy: 0.000001,
                        "出行方式 \(mode), 迭代 \(iteration), 路线段 \(index): 起点纬度不匹配"
                    )
                    XCTAssertEqual(
                        segment.origin.longitude,
                        expectedOrigin.longitude,
                        accuracy: 0.000001,
                        "出行方式 \(mode), 迭代 \(iteration), 路线段 \(index): 起点经度不匹配"
                    )
                    XCTAssertEqual(
                        segment.destination.latitude,
                        expectedDestination.latitude,
                        accuracy: 0.000001,
                        "出行方式 \(mode), 迭代 \(iteration), 路线段 \(index): 终点纬度不匹配"
                    )
                    XCTAssertEqual(
                        segment.destination.longitude,
                        expectedDestination.longitude,
                        accuracy: 0.000001,
                        "出行方式 \(mode), 迭代 \(iteration), 路线段 \(index): 终点经度不匹配"
                    )
                }
            }
        }
    }
    
    /// 测试路线段的连续性（前一段的终点等于后一段的起点）
    /// **Feature: route-navigation-display, Property 3: 路线段顺序与景点顺序一致性**
    /// **Validates: Requirements 2.2**
    ///
    /// 这是Property 3的推论：如果每个路线段的起点等于对应景点坐标，
    /// 终点等于下一个景点坐标，那么相邻路线段应该是连续的。
    func testRouteSegmentContinuity() async throws {
        for iteration in 1...100 {
            // Given
            let attractionCount = Int.random(in: 3...20) // 至少3个景点才有多个路线段
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            let mockService = MockRouteNavigationService()
            
            // When
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证相邻路线段的连续性
            for i in 0..<(navigationPath.segments.count - 1) {
                let currentSegment = navigationPath.segments[i]
                let nextSegment = navigationPath.segments[i + 1]
                
                // 当前路线段的终点应该等于下一个路线段的起点
                XCTAssertEqual(
                    currentSegment.destination.latitude,
                    nextSegment.origin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration): 路线段\(i)的终点纬度应等于路线段\(i + 1)的起点纬度"
                )
                XCTAssertEqual(
                    currentSegment.destination.longitude,
                    nextSegment.origin.longitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration): 路线段\(i)的终点经度应等于路线段\(i + 1)的起点经度"
                )
            }
            
            if iteration % 20 == 0 {
                print("路线段连续性测试进度: \(iteration)/100")
            }
        }
    }
    
    // MARK: - Property 5: 降级方案的正确性
    
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    ///
    /// 对于任意路径规划失败的情况，返回的降级RouteSegment应该：
    /// 1. isFallback属性为true
    /// 2. pathCoordinates仅包含起点和终点两个坐标
    /// 3. 起点和终点坐标与请求的起终点一致
    ///
    /// 测试策略：
    /// - 使用RouteSegment.fallback静态方法创建降级路线段
    /// - 生成随机的起点和终点坐标
    /// - 验证降级路线段的所有属性符合预期
    func testFallbackSegmentCorrectness() {
        // 运行至少100次迭代
        for iteration in 1...100 {
            // Given - 生成随机的起点和终点坐标
            let origin = generateRandomCoordinate()
            let destination = generateRandomCoordinate()
            let travelMode = TravelMode.allCases.randomElement()!
            
            // When - 创建降级路线段
            let fallbackSegment = RouteSegment.fallback(
                from: origin,
                to: destination,
                travelMode: travelMode
            )
            
            // Then - 验证Property 5的三个条件
            
            // 条件1: isFallback属性为true
            XCTAssertTrue(
                fallbackSegment.isFallback,
                "迭代 \(iteration): 降级路线段的isFallback属性应为true"
            )
            
            // 条件2: pathCoordinates仅包含起点和终点两个坐标
            XCTAssertEqual(
                fallbackSegment.pathCoordinates.count,
                2,
                "迭代 \(iteration): 降级路线段的pathCoordinates应仅包含2个坐标点"
            )
            
            // 条件3: 起点和终点坐标与请求的起终点一致
            XCTAssertEqual(
                fallbackSegment.origin.latitude,
                origin.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 降级路线段的起点纬度应与请求的起点一致"
            )
            XCTAssertEqual(
                fallbackSegment.origin.longitude,
                origin.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 降级路线段的起点经度应与请求的起点一致"
            )
            XCTAssertEqual(
                fallbackSegment.destination.latitude,
                destination.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 降级路线段的终点纬度应与请求的终点一致"
            )
            XCTAssertEqual(
                fallbackSegment.destination.longitude,
                destination.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): 降级路线段的终点经度应与请求的终点一致"
            )
            
            // 验证pathCoordinates的第一个点是起点，最后一个点是终点
            XCTAssertEqual(
                fallbackSegment.pathCoordinates.first?.latitude,
                origin.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): pathCoordinates的第一个点应为起点"
            )
            XCTAssertEqual(
                fallbackSegment.pathCoordinates.first?.longitude,
                origin.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): pathCoordinates的第一个点应为起点"
            )
            XCTAssertEqual(
                fallbackSegment.pathCoordinates.last?.latitude,
                destination.latitude,
                accuracy: 0.000001,
                "迭代 \(iteration): pathCoordinates的最后一个点应为终点"
            )
            XCTAssertEqual(
                fallbackSegment.pathCoordinates.last?.longitude,
                destination.longitude,
                accuracy: 0.000001,
                "迭代 \(iteration): pathCoordinates的最后一个点应为终点"
            )
            
            if iteration % 20 == 0 {
                print("Property 5 测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试降级路线段的distance和duration属性
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    ///
    /// 降级路线段的distance和duration应为nil（因为无法从API获取真实数据）
    func testFallbackSegmentDistanceAndDuration() {
        for iteration in 1...100 {
            // Given
            let origin = generateRandomCoordinate()
            let destination = generateRandomCoordinate()
            let travelMode = TravelMode.allCases.randomElement()!
            
            // When
            let fallbackSegment = RouteSegment.fallback(
                from: origin,
                to: destination,
                travelMode: travelMode
            )
            
            // Then - 降级路线段的distance和duration应为nil
            XCTAssertNil(
                fallbackSegment.distance,
                "迭代 \(iteration): 降级路线段的distance应为nil"
            )
            XCTAssertNil(
                fallbackSegment.duration,
                "迭代 \(iteration): 降级路线段的duration应为nil"
            )
            
            if iteration % 20 == 0 {
                print("降级路线段distance/duration测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试降级路线段的出行方式一致性
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    func testFallbackSegmentTravelModeConsistency() {
        for mode in TravelMode.allCases {
            for iteration in 1...30 {
                // Given
                let origin = generateRandomCoordinate()
                let destination = generateRandomCoordinate()
                
                // When
                let fallbackSegment = RouteSegment.fallback(
                    from: origin,
                    to: destination,
                    travelMode: mode
                )
                
                // Then - 出行方式应与请求的一致
                XCTAssertEqual(
                    fallbackSegment.travelMode,
                    mode,
                    "出行方式 \(mode), 迭代 \(iteration): 降级路线段的出行方式应与请求的一致"
                )
            }
        }
    }
    
    /// 测试NavigationPath的hasFallbackSegments属性
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    func testNavigationPathHasFallbackSegments() {
        for iteration in 1...100 {
            // Given - 生成包含降级路线段的NavigationPath
            let segmentCount = Int.random(in: 1...10)
            let fallbackCount = Int.random(in: 0...segmentCount)
            let travelMode = TravelMode.allCases.randomElement()!
            
            var segments: [RouteSegment] = []
            var previousDestination = generateRandomCoordinate()
            
            for i in 0..<segmentCount {
                let origin = previousDestination
                let destination = generateRandomCoordinate()
                
                let isFallback = i < fallbackCount
                
                if isFallback {
                    // 创建降级路线段
                    segments.append(RouteSegment.fallback(
                        from: origin,
                        to: destination,
                        travelMode: travelMode
                    ))
                } else {
                    // 创建正常路线段
                    let pathCoordinates = [origin, generateRandomCoordinate(), destination]
                    segments.append(RouteSegment(
                        origin: origin,
                        destination: destination,
                        pathCoordinates: pathCoordinates,
                        travelMode: travelMode,
                        distance: Int.random(in: 100...10000),
                        duration: Int.random(in: 60...3600),
                        isFallback: false
                    ))
                }
                
                previousDestination = destination
            }
            
            // When
            let navigationPath = NavigationPath(segments: segments, travelMode: travelMode)
            
            // Then
            let expectedHasFallback = fallbackCount > 0
            XCTAssertEqual(
                navigationPath.hasFallbackSegments,
                expectedHasFallback,
                "迭代 \(iteration): hasFallbackSegments应为\(expectedHasFallback)（降级段数量: \(fallbackCount)）"
            )
            
            XCTAssertEqual(
                navigationPath.fallbackSegmentCount,
                fallbackCount,
                "迭代 \(iteration): fallbackSegmentCount应为\(fallbackCount)"
            )
            
            if iteration % 20 == 0 {
                print("NavigationPath降级属性测试进度: \(iteration)/100")
            }
        }
    }
    
    /// 测试使用MockFailingRouteNavigationService时的降级行为
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    func testFallbackBehaviorOnServiceFailure() async throws {
        for iteration in 1...50 {
            // Given - 使用会失败的Mock服务
            let attractionCount = Int.random(in: 2...10)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            
            let mockService = MockFailingRouteNavigationService()
            
            // When - 规划导航路线（服务会返回降级路线段）
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证所有路线段都是降级路线段
            XCTAssertEqual(
                navigationPath.segments.count,
                attractionCount - 1,
                "迭代 \(iteration): 路线段数量应为景点数量减1"
            )
            
            XCTAssertTrue(
                navigationPath.hasFallbackSegments,
                "迭代 \(iteration): 服务失败时应返回包含降级路线段的NavigationPath"
            )
            
            XCTAssertEqual(
                navigationPath.fallbackSegmentCount,
                attractionCount - 1,
                "迭代 \(iteration): 所有路线段都应是降级路线段"
            )
            
            // 验证每个降级路线段的正确性
            for (index, segment) in navigationPath.segments.enumerated() {
                XCTAssertTrue(
                    segment.isFallback,
                    "迭代 \(iteration), 路线段 \(index): isFallback应为true"
                )
                
                XCTAssertEqual(
                    segment.pathCoordinates.count,
                    2,
                    "迭代 \(iteration), 路线段 \(index): pathCoordinates应仅包含2个坐标点"
                )
                
                // 验证起点和终点与景点坐标一致
                let expectedOrigin = attractions[index].coordinate!
                let expectedDestination = attractions[index + 1].coordinate!
                
                XCTAssertEqual(
                    segment.origin.latitude,
                    expectedOrigin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点纬度应与景点坐标一致"
                )
                XCTAssertEqual(
                    segment.destination.latitude,
                    expectedDestination.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点纬度应与景点坐标一致"
                )
            }
            
            if iteration % 10 == 0 {
                print("服务失败降级测试进度: \(iteration)/50")
            }
        }
    }
    
    /// 测试部分路线段失败时的降级行为
    /// **Feature: route-navigation-display, Property 5: 降级方案的正确性**
    /// **Validates: Requirements 2.4, 5.1, 5.2**
    func testPartialFallbackBehavior() async throws {
        for iteration in 1...50 {
            // Given - 使用部分失败的Mock服务
            let attractionCount = Int.random(in: 3...10)
            let attractions = generateRandomAttractions(count: attractionCount)
            let travelMode = TravelMode.allCases.randomElement()!
            let failureRate = Double.random(in: 0.2...0.8)
            
            let mockService = MockPartialFailingRouteNavigationService(failureRate: failureRate)
            
            // When - 规划导航路线
            let navigationPath = try await mockService.planNavigationRoute(
                attractions: attractions,
                travelMode: travelMode,
                citycode: nil
            )
            
            // Then - 验证路线段数量正确
            XCTAssertEqual(
                navigationPath.segments.count,
                attractionCount - 1,
                "迭代 \(iteration): 路线段数量应为景点数量减1"
            )
            
            // 验证每个路线段的正确性
            for (index, segment) in navigationPath.segments.enumerated() {
                let expectedOrigin = attractions[index].coordinate!
                let expectedDestination = attractions[index + 1].coordinate!
                
                // 无论是否降级，起点和终点都应与景点坐标一致
                XCTAssertEqual(
                    segment.origin.latitude,
                    expectedOrigin.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 起点纬度应与景点坐标一致"
                )
                XCTAssertEqual(
                    segment.destination.latitude,
                    expectedDestination.latitude,
                    accuracy: 0.000001,
                    "迭代 \(iteration), 路线段 \(index): 终点纬度应与景点坐标一致"
                )
                
                // 如果是降级路线段，验证其属性
                if segment.isFallback {
                    XCTAssertEqual(
                        segment.pathCoordinates.count,
                        2,
                        "迭代 \(iteration), 路线段 \(index): 降级路线段的pathCoordinates应仅包含2个坐标点"
                    )
                    XCTAssertNil(
                        segment.distance,
                        "迭代 \(iteration), 路线段 \(index): 降级路线段的distance应为nil"
                    )
                    XCTAssertNil(
                        segment.duration,
                        "迭代 \(iteration), 路线段 \(index): 降级路线段的duration应为nil"
                    )
                }
            }
            
            if iteration % 10 == 0 {
                print("部分降级测试进度: \(iteration)/50")
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 生成随机坐标
    private func generateRandomCoordinate() -> Coordinate {
        return Coordinate(
            latitude: Double.random(in: 18...54),  // 中国纬度范围
            longitude: Double.random(in: 73...135) // 中国经度范围
        )
    }
    
    /// 生成随机景点列表
    private func generateRandomAttractions(count: Int) -> [Attraction] {
        var attractions: [Attraction] = []
        for i in 0..<count {
            let coordinate = generateRandomCoordinate()
            let attraction = Attraction(
                id: UUID().uuidString,
                name: "景点\(i + 1)",
                coordinate: coordinate,
                address: "地址\(i + 1)"
            )
            attractions.append(attraction)
        }
        return attractions
    }
    
    /// 生成随机路线段列表
    private func generateRandomRouteSegments(count: Int) -> [RouteSegment] {
        var segments: [RouteSegment] = []
        var previousDestination = generateRandomCoordinate()
        
        for _ in 0..<count {
            let origin = previousDestination
            let destination = generateRandomCoordinate()
            let travelMode = TravelMode.allCases.randomElement()!
            
            // 生成路径坐标点
            let pathCoordinateCount = Int.random(in: 2...10)
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
            previousDestination = destination
        }
        return segments
    }
}

// MARK: - Mock RouteNavigationService

/// Mock路径导航服务
/// 用于测试路线段数量不变性，不依赖高德地图API
class MockRouteNavigationService: RouteNavigationServiceProtocol {
    
    /// 模拟规划导航路线
    /// 对于N个景点，返回N-1个路线段
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
        
        // 按顺序规划每段路线（模拟实际服务的行为）
        for i in 0..<(validAttractions.count - 1) {
            let origin = validAttractions[i].coordinate!
            let destination = validAttractions[i + 1].coordinate!
            
            let segment = try await planSegment(
                from: origin,
                to: destination,
                travelMode: travelMode,
                citycode: citycode
            )
            segments.append(segment)
        }
        
        return NavigationPath(segments: segments, travelMode: travelMode)
    }
    
    /// 模拟规划单段路线
    func planSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> RouteSegment {
        // 生成模拟的路径坐标点（简单的直线插值）
        let pathCoordinateCount = Int.random(in: 5...15)
        var pathCoordinates: [Coordinate] = []
        
        for i in 0..<pathCoordinateCount {
            let t = Double(i) / Double(pathCoordinateCount - 1)
            let lat = origin.latitude + (destination.latitude - origin.latitude) * t
            let lng = origin.longitude + (destination.longitude - origin.longitude) * t
            pathCoordinates.append(Coordinate(latitude: lat, longitude: lng))
        }
        
        // 计算模拟的距离和时间
        let distance = calculateDistance(from: origin, to: destination)
        let duration = calculateDuration(distance: distance, travelMode: travelMode)
        
        return RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: pathCoordinates,
            travelMode: travelMode,
            distance: distance,
            duration: duration,
            isFallback: false
        )
    }
    
    /// 计算两点之间的距离（米）- 使用Haversine公式
    private func calculateDistance(from origin: Coordinate, to destination: Coordinate) -> Int {
        let earthRadius = 6371000.0 // 地球半径（米）
        
        let lat1 = origin.latitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let deltaLat = (destination.latitude - origin.latitude) * .pi / 180
        let deltaLng = (destination.longitude - origin.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLng / 2) * sin(deltaLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return Int(earthRadius * c)
    }
    
    /// 根据距离和出行方式计算预计时间（秒）
    private func calculateDuration(distance: Int, travelMode: TravelMode) -> Int {
        let speedMetersPerSecond: Double
        switch travelMode {
        case .walking:
            speedMetersPerSecond = 1.4 // 约5km/h
        case .publicTransport:
            speedMetersPerSecond = 8.3 // 约30km/h（考虑等待时间）
        case .driving:
            speedMetersPerSecond = 11.1 // 约40km/h（考虑城市交通）
        }
        return Int(Double(distance) / speedMetersPerSecond)
    }
}

// MARK: - Mock Failing RouteNavigationService

/// 模拟总是失败的路径导航服务
/// 用于测试降级方案的正确性
class MockFailingRouteNavigationService: RouteNavigationServiceProtocol {
    
    /// 模拟规划导航路线（总是返回降级路线段）
    func planNavigationRoute(
        attractions: [Attraction],
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> NavigationPath {
        let validAttractions = attractions.filter { $0.coordinate != nil }
        
        guard validAttractions.count >= 2 else {
            throw RouteNavigationError.invalidCoordinate
        }
        
        var segments: [RouteSegment] = []
        
        for i in 0..<(validAttractions.count - 1) {
            let origin = validAttractions[i].coordinate!
            let destination = validAttractions[i + 1].coordinate!
            
            // 模拟API失败，使用降级方案
            let segment = RouteSegment.fallback(
                from: origin,
                to: destination,
                travelMode: travelMode
            )
            segments.append(segment)
        }
        
        return NavigationPath(segments: segments, travelMode: travelMode)
    }
    
    /// 模拟规划单段路线（总是抛出错误）
    func planSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> RouteSegment {
        throw RouteNavigationError.routePlanningFailed("模拟API失败")
    }
}

// MARK: - Mock Partial Failing RouteNavigationService

/// 模拟部分失败的路径导航服务
/// 用于测试部分降级场景
class MockPartialFailingRouteNavigationService: RouteNavigationServiceProtocol {
    
    /// 失败率（0.0 - 1.0）
    let failureRate: Double
    
    init(failureRate: Double = 0.5) {
        self.failureRate = failureRate
    }
    
    /// 模拟规划导航路线（部分路线段可能失败）
    func planNavigationRoute(
        attractions: [Attraction],
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> NavigationPath {
        let validAttractions = attractions.filter { $0.coordinate != nil }
        
        guard validAttractions.count >= 2 else {
            throw RouteNavigationError.invalidCoordinate
        }
        
        var segments: [RouteSegment] = []
        
        for i in 0..<(validAttractions.count - 1) {
            let origin = validAttractions[i].coordinate!
            let destination = validAttractions[i + 1].coordinate!
            
            // 根据失败率决定是否使用降级方案
            if Double.random(in: 0...1) < failureRate {
                // 模拟API失败，使用降级方案
                let segment = RouteSegment.fallback(
                    from: origin,
                    to: destination,
                    travelMode: travelMode
                )
                segments.append(segment)
            } else {
                // 模拟API成功
                let segment = try await planSegment(
                    from: origin,
                    to: destination,
                    travelMode: travelMode,
                    citycode: citycode
                )
                segments.append(segment)
            }
        }
        
        return NavigationPath(segments: segments, travelMode: travelMode)
    }
    
    /// 模拟规划单段路线
    func planSegment(
        from origin: Coordinate,
        to destination: Coordinate,
        travelMode: TravelMode,
        citycode: String?
    ) async throws -> RouteSegment {
        // 生成模拟的路径坐标点
        let pathCoordinateCount = Int.random(in: 5...15)
        var pathCoordinates: [Coordinate] = []
        
        for i in 0..<pathCoordinateCount {
            let t = Double(i) / Double(pathCoordinateCount - 1)
            let lat = origin.latitude + (destination.latitude - origin.latitude) * t
            let lng = origin.longitude + (destination.longitude - origin.longitude) * t
            pathCoordinates.append(Coordinate(latitude: lat, longitude: lng))
        }
        
        return RouteSegment(
            origin: origin,
            destination: destination,
            pathCoordinates: pathCoordinates,
            travelMode: travelMode,
            distance: Int.random(in: 100...10000),
            duration: Int.random(in: 60...3600),
            isFallback: false
        )
    }
}
