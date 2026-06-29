import SwiftUI

/// One case per navigable screen. The compiler enforces exhaustiveness in the
/// navigationDestination switch, so a missing handler is a build error rather than
/// a runtime no-op. Deep links would decode into these cases rather than pushing
/// raw string routes.
enum AppDestination: Hashable {
    case hotelList(Place)
}

/// Owns the NavigationPath and wires dependencies into each destination's ViewModel.
///
/// ViewModels are constructed here, not inside their views. The nav layer already
/// holds AppDependencies and knows which screen is being shown — that makes it the
/// natural place to do the wiring. Views stay passive: they receive a configured
/// ViewModel and have no awareness of where their services came from.
struct AppRouter: View {
    @State private var path = NavigationPath()

    @Environment(NetworkMonitor.self) private var networkMonitor

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack(path: $path) {
            SearchView(
                viewModel: SearchViewModel(searchService: dependencies.searchService),
                onSelectPlace: { place in
                    path.append(AppDestination.hotelList(place))
                }
            )
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .hotelList(let place):
                    HotelListView(
                        viewModel: HotelListViewModel(
                            place: place,
                            hotelService: dependencies.hotelService
                        ),
                        title: place.name
                    )
                }
            }
        }
        .overlay(alignment: .bottom) {
            if !networkMonitor.isConnected {
                OfflineBannerView()
                    .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .environment(\.appDependencies, dependencies)
    }
}
