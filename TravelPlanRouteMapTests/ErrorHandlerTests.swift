import XCTest
@testable import TravelPlanRouteMap

/// 错误处理单元测试
final class ErrorHandlerTests: XCTestCase {
    
    // MARK: - 测试网络错误消息
    
    func testNetworkErrorMessage() {
        // Given
        let error = TravelPlanError.networkError
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("网络"))
    }
    
    // MARK: - 测试地图加载错误消息
    
    func testMapLoadingErrorMessage() {
        // Given
        let error = TravelPlanError.mapLoadingFailed
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("地图"))
    }
    
    // MARK: - 测试AI规划超时错误消息
    
    func testAIPlanningTimeoutMessage() {
        // Given
        let error = TravelPlanError.aiPlanningTimeout
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("超时"))
    }
    
    // MARK: - 测试无效输入错误消息
    
    func testInvalidDestinationMessage() {
        // Given
        let error = TravelPlanError.invalidDestination
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertFalse(message!.isEmpty)
    }
    
    func testInvalidAttractionNameMessage() {
        // Given
        let error = TravelPlanError.invalidAttractionName
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("景点"))
    }
    
    func testInsufficientAttractionsMessage() {
        // Given
        let error = TravelPlanError.insufficientAttractions
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("2"))
    }
    
    func testTooManyAttractionsMessage() {
        // Given
        let error = TravelPlanError.tooManyAttractions
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("10"))
    }
    
    // MARK: - 测试地理编码失败错误消息
    
    func testGeocodingFailedMessage() {
        // Given
        let attractionName = "未知景点"
        let error = TravelPlanError.geocodingFailed(attractionName)
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains(attractionName))
    }
    
    // MARK: - 测试AI规划失败错误消息
    
    func testAIPlanningFailedMessage() {
        // Given
        let reason = "API返回错误"
        let error = TravelPlanError.aiPlanningFailed(reason)
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains(reason))
    }
    
    // MARK: - 测试持久化错误消息
    
    func testPersistenceErrorMessage() {
        // Given
        let reason = "存储空间不足"
        let error = TravelPlanError.persistenceError(reason)
        
        // When
        let message = error.errorDescription
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains(reason))
    }
    
    // MARK: - 测试所有错误都有非空消息（属性16验证）
    
    func testAllErrorsHaveNonEmptyMessages() {
        // Given
        let errors: [TravelPlanError] = [
            .invalidDestination,
            .invalidAttractionName,
            .insufficientAttractions,
            .tooManyAttractions,
            .networkError,
            .geocodingFailed("测试"),
            .aiPlanningFailed("测试"),
            .aiPlanningTimeout,
            .mapLoadingFailed,
            .persistenceError("测试")
        ]
        
        // When/Then
        for error in errors {
            let message = error.errorDescription
            XCTAssertNotNil(message, "错误 \(error) 应该有错误消息")
            XCTAssertFalse(message!.isEmpty, "错误 \(error) 的消息不应为空")
        }
    }
}
