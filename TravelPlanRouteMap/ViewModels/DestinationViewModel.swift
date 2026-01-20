import Foundation
import Combine

/// 目的地输入 ViewModel
@MainActor
class DestinationViewModel: ObservableObject {
    @Published var destination: String = ""
    @Published var searchResults: [GeocodingResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedDestination: GeocodingResult?
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let geocodingService: GeocodingService
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 500_000_000  // 500ms 防抖延迟
    
    init(geocodingService: GeocodingService = AppDependencies.shared.geocodingService) {
        self.geocodingService = geocodingService
    }
    
    /// 搜索目的地（使用高德地理编码，带防抖）
    func searchDestination() {
        let keyword = destination.trimmingCharacters(in: .whitespaces)
        
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
                let results = try await geocodingService.geocode(address: keyword)
                
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
    
    /// 选择目的地
    func selectDestination(_ result: GeocodingResult) {
        selectedDestination = result
        destination = result.name
        searchResults = []
        validate()
        HapticFeedback.light()
    }
    
    /// 验证输入
    func validate() {
        let trimmed = destination.trimmingCharacters(in: .whitespaces)
        isValid = selectedDestination != nil && !trimmed.isEmpty
        
        if trimmed.isEmpty {
            errorMessage = "请输入目的地"
        } else if selectedDestination == nil {
            errorMessage = "请从搜索结果中选择目的地"
        } else {
            errorMessage = nil
        }
    }
    
    /// 清除选择
    func clearSelection() {
        selectedDestination = nil
        destination = ""
        searchResults = []
        isValid = false
        errorMessage = nil
    }
}
