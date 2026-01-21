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
    @StateObject private var historyViewModel = HistoryViewModel()
    
    var body: some View {
        ZStack {
            switch navigationState {
            case .home:
                HistoryView(
                    onSelectPlan: { plan in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .planDetail(plan)
                        }
                    },
                    onNewPlan: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            startNewPlan()
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(navigationState.zIndex == 0 ? 1 : 0)
                
            case .destination:
                DestinationInputView(
                    selectedDestination: $selectedDestination,
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .travelMode
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .zIndex(navigationState.zIndex == 1 ? 1 : 0)
                
            case .travelMode:
                TravelModeSelectionView(
                    selectedMode: $selectedTravelMode,
                    onNext: {
                        initAttractionViewModel()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .attractions
                        }
                    },
                    onSkip: {
                        selectedTravelMode = .driving
                        initAttractionViewModel()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .attractions
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .destination
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .zIndex(navigationState.zIndex == 2 ? 1 : 0)
                
            case .attractions:
                if let vm = attractionViewModel {
                    AttractionInputView(
                        viewModel: vm,
                        onNext: {
                            resultViewModel.clear()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                navigationState = .result
                            }
                        },
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                navigationState = .travelMode
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .zIndex(navigationState.zIndex == 3 ? 1 : 0)
                }
                
            case .result:
                if let vm = attractionViewModel, let dest = selectedDestination {
                    ResultView(
                        viewModel: resultViewModel,
                        destination: dest.name,
                        attractions: vm.attractions,
                        travelMode: selectedTravelMode,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                navigationState = .attractions
                            }
                        },
                        onNewPlan: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                startNewPlan()
                            }
                        }
                    )
                    .onAppear {
                        resultViewModel.clear()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .zIndex(navigationState.zIndex == 4 ? 1 : 0)
                }
                
            case .planDetail(let plan):
                PlanDetailView(
                    plan: plan,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            navigationState = .home
                        }
                    },
                    onNewPlan: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            startNewPlan()
                        }
                    },
                    onDelete: {
                        deletePlanAndGoBack(plan)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .zIndex(navigationState.zIndex == 5 ? 1 : 0)
            }
        }
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
    
    private func deletePlanAndGoBack(_ plan: TravelPlan) {
        historyViewModel.deletePlan(plan)
        navigationState = .home
    }
}

// 为 NavigationState 添加 description 和 zIndex 以支持动画
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
    
    var zIndex: Int {
        switch self {
        case .home: return 0
        case .destination: return 1
        case .travelMode: return 2
        case .attractions: return 3
        case .result: return 4
        case .planDetail: return 5
        }
    }
}

#Preview {
    MainView()
}
