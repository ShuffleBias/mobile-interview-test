import SwiftUI

/// App-wide service dependencies, constructed once at the App entry point.
///
/// The strategy is two-level: the environment carries the container down the view tree
/// so we don't have to thread it through every initializer, but ViewModels pull their
/// services via constructor injection rather than reading from the environment directly.
/// That separation keeps ViewModels decoupled from SwiftUI — a plain MockSearchService
/// is enough to test SearchViewModel with no view scaffolding required.
struct AppDependencies: Sendable {
    let searchService: any SearchServiceable
    let hotelService: any HotelServiceable
}

// MARK: - Environment key

private struct AppDependenciesKey: EnvironmentKey {
    // SwiftUI requires a concrete default value. This resolves to live services,
    // so any Xcode Preview that doesn't explicitly inject AppDependencies will
    // hit the real staging API. Previews should always provide mock dependencies.
    static let defaultValue = AppDependencies(
        searchService: LiveSearchService(client: URLSessionNetworkClient()),
        hotelService: LiveHotelService(client: URLSessionNetworkClient())
    )
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
