import SwiftUI

@main
struct ResortPassInterviewApp: App {
    private let dependencies: AppDependencies = {
        let client = URLSessionNetworkClient()
        return AppDependencies(
            searchService: LiveSearchService(client: client),
            hotelService: LiveHotelService(client: client)
        )
    }()

    @State private var networkMonitor = NetworkMonitor()
    @State private var searchHistory = SearchHistoryStore()

    var body: some Scene {
        WindowGroup {
            AppRouter(dependencies: dependencies)
                .environment(networkMonitor)
                .environment(searchHistory)
        }
    }
}
