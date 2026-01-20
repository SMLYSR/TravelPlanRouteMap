import Foundation
import Combine

/// 景点输入 ViewModel
@MainActor
class AttractionViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var currentInput: String = ""
    @Published var searchResults: [POIResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var travelMode: TravelMode = .driving
    
    private let geocodingService: GeocodingService
    private let destination: String
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 500_000_000  // 500ms 防抖延迟
    
    let maxAttractions = Config.maxAttractions
    let minAttractions = Config.minAttractions
    
    init(geocodingService: GeocodingService = AppDependencies.shared.geocodingService, destination: String) {
        self.geocodingService = geocodingService
        self.destination = destination
    }
    
    /// 模糊搜索景点（使用高德POI搜索，带防抖）
    func searchAttractions() {
        let keyword = currentInput.trimmingCharacters(in: .whitespaces)
        
        guard !keyword.isEmpty else {
            searchResults = []
            return
        }
        
        // 取消之前的搜索任务
        searchTask?.cancel()
        
        searchTask = Task {
            // 防抖：等待 500ms，如果期间有新输入则取消
            try? await Task.sleep(nanoseconds: debounceDelay)
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            errorMessage = nil
            
            do {
                let results = try await geocodingService.searchPOI(
                    keyword: keyword,
                    city: destination
                )
                
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                if !Task.isCancelled {
                    // 优化错误提示
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("EXCEEDED_THE_LIMIT") || errorMsg.contains("QPS") {
                        errorMessage = "搜索太频繁，请稍后再试"
                    } else {
                        errorMessage = "搜索失败：\(errorMsg)"
                    }
                    searchResults = []
                }
            }
            
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
    
    /// 从搜索结果中选择景点
    func selectAttraction(_ result: POIResult) {
        guard attractions.count < maxAttractions else {
            errorMessage = "最多支持\(maxAttractions)个景点"
            HapticFeedback.error()
            return
        }
        
        // 检查是否已添加
        if attractions.contains(where: { $0.name == result.name }) {
            errorMessage = "该景点已添加"
            HapticFeedback.warning()
            return
        }
        
        let attraction = Attraction(
            name: result.name,
            coordinate: result.coordinate,
            address: result.address
        )
        attractions.append(attraction)
        currentInput = ""
        searchResults = []
        errorMessage = nil
        HapticFeedback.light()
    }
    
    /// 删除景点
    func removeAttraction(at index: Int) {
        guard index >= 0 && index < attractions.count else { return }
        attractions.remove(at: index)
        errorMessage = nil
        HapticFeedback.light()
    }
    
    /// 删除指定景点
    func removeAttraction(_ attraction: Attraction) {
        attractions.removeAll { $0.id == attraction.id }
        errorMessage = nil
        HapticFeedback.light()
    }
    
    /// 设置出行方式
    func setTravelMode(_ mode: TravelMode) {
        travelMode = mode
        HapticFeedback.light()
    }
    
    /// 检查是否可以继续
    func canProceed() -> Bool {
        return attractions.count >= minAttractions
    }
    
    /// 验证并返回错误消息
    func validateAndGetError() -> String? {
        if attractions.count < minAttractions {
            return "至少需要\(minAttractions)个景点才能规划路线"
        }
        return nil
    }
    
    /// 清除所有景点
    func clearAll() {
        attractions = []
        currentInput = ""
        searchResults = []
        errorMessage = nil
    }
}
