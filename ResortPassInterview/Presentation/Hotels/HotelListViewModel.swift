import Foundation
import Observation

@Observable
@MainActor
final class HotelListViewModel {
    private(set) var state: ViewState<[Hotel]> = .loading
    private(set) var isLoadingMore: Bool = false
    private(set) var hasMorePages: Bool = false
    private(set) var currencySymbol: String = "$"

    private let place: Place
    private let hotelService: any HotelServiceable
    private var currentOffset: Int = 0
    private let pageSize = 30

    init(place: Place, hotelService: any HotelServiceable) {
        self.place = place
        self.hotelService = hotelService
    }

    // MARK: - Public interface

    func load() async {
        currentOffset = 0
        hasMorePages = false
        state = .loading
        await fetchPage(appending: false)
    }

    func retry() async {
        await load()
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await fetchPage(appending: true)
    }

    // MARK: - Private

    private func fetchPage(appending: Bool) async {
        do {
            let page = try await hotelService.fetchHotels(
                latitude: place.latitude,
                longitude: place.longitude,
                offset: currentOffset
            )

            let allHotels: [Hotel]
            if appending, case .success(let existing) = state {
                allHotels = existing + page.hotels
            } else {
                allHotels = page.hotels
            }

            currentOffset += page.hotels.count
            hasMorePages = currentOffset < page.total
            if !appending { currencySymbol = page.currencySymbol }

            state = allHotels.isEmpty ? .empty : .success(allHotels)
        } catch is CancellationError {
            // View disappeared mid-request; leave state unchanged.
        } catch {
            if !appending {
                state = .error(error)
            }
            // On a pagination failure, keep showing existing results;
            // the user can scroll back up and try again.
        }
    }
}
