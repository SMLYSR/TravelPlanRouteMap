import SwiftUI

/// 导航状态
enum NavigationState {
    case home
    case destination
    case travelMode
    case attractions
    case result
    case planDetail(TravelPlan)
}

/// 主视图 - 管理导航流程
@MainActor
struct MainView: View {
    @State private var navigationState: NavigationState = .home
    @State private var selectedDestination: GeocodingResult?
    @State private var selectedTravelMode: TravelMode = .driving
    @State private var attractionViewModel: AttractionViewModel?
    @StateObject private var resultViewModel = ResultViewModel()
    
    var body: some View {
        ZStack {
            switch navigationState {
            case .home:
                HistoryView(
                    onSelectPlan: { plan in
                        navigationState = .planDetail(plan)
                    },
                    onNewPlan: {
                        startNewPlan()
                    }
                )
                .transition(.opacity)
                
            case .destination:
                DestinationInputView(
                    selectedDestination: $selectedDestination,
                    onNext: {
                        navigationState = .travelMode
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .travelMode:
                TravelModeSelectionView(
                    selectedMode: $selectedTravelMode,
                    onNext: {
                        initAttractionViewModel()
                        navigationState = .attractions
                    },
                    onSkip: {
                        selectedTravelMode = .driving
                        initAttractionViewModel()
                        navigationState = .attractions
                    },
                    onBack: {
                        navigationState = .destination
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .attractions:
                if let vm = attractionViewModel {
                    AttractionInputView(
                        viewModel: vm,
                        onNext: {
                            resultViewModel.clear()
                            navigationState = .result
                        },
                        onBack: {
                            navigationState = .travelMode
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }
                
            case .result:
                if let vm = attractionViewModel, let dest = selectedDestination {
                    ResultView(
                        viewModel: resultViewModel,
                        destination: dest.name,
                        attractions: vm.attractions,
                        travelMode: selectedTravelMode,
                        onBack: {
                            navigationState = .attractions
                        },
                        onNewPlan: {
                            startNewPlan()
                        }
                    )
                    .onAppear {
                        resultViewModel.clear()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }
                
            case .planDetail(let plan):
                PlanDetailView(
                    plan: plan,
                    onBack: {
                        navigationState = .home
                    },
                    onNewPlan: {
                        startNewPlan()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.pageTransitionIn), value: navigationState.description)
    }
    
    private func startNewPlan() {
        selectedDestination = nil
        selectedTravelMode = .driving
        attractionViewModel = nil
        resultViewModel.clear()
        navigationState = .destination
    }
    
    private func initAttractionViewModel() {
        if let dest = selectedDestination {
            attractionViewModel = AttractionViewModel(destination: dest.name)
            attractionViewModel?.travelMode = selectedTravelMode
        }
    }
}

// 为 NavigationState 添加 description 以支持动画
extension NavigationState {
    var description: String {
        switch self {
        case .home: return "home"
        case .destination: return "destination"
        case .travelMode: return "travelMode"
        case .attractions: return "attractions"
        case .result: return "result"
        case .planDetail: return "planDetail"
        }
    }
}

#Preview {
    MainView()
}
