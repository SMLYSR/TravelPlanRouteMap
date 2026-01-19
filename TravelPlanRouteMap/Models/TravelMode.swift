import Foundation

/// 出行方式枚举
enum TravelMode: String, Codable, CaseIterable {
    case walking = "步行"
    case publicTransport = "公共交通"
    case driving = "自驾"
    
    var displayName: String {
        return rawValue
    }
    
    var iconName: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .publicTransport:
            return "bus.fill"
        case .driving:
            return "car.fill"
        }
    }
}
