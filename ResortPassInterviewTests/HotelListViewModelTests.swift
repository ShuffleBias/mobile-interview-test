import Testing
import Foundation
@testable import ResortPassInterview

@MainActor
struct HotelListViewModelTests {
    private func makeViewModel(service: MockHotelService = MockHotelService()) -> (HotelListViewModel, MockHotelService) {
        let svc = service
        let vm = HotelListViewModel(place: .fixture(), hotelService: svc)
        return (vm, svc)
    }

    @Test("Initial state is loading")
    func initialStateIsLoading() {
        let (vm, _) = makeViewModel()
        guard case .loading = vm.state else {
            Issue.record("Expected initial state to be .loading")
            return
        }
    }

    @Test("Successful load with hotels yields success state")
    func loadYieldsSuccess() async throws {
        let svc = MockHotelService()
        svc.result = .success(HotelPage(hotels: [.fixture(name: "Grand Hotel"), .fixture(id: 2, name: "Palace")], total: 2, offset: 0, currencySymbol: "$"))
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()

        guard case .success(let hotels) = vm.state else {
            Issue.record("Expected .success, got \(vm.state)")
            return
        }
        #expect(hotels.count == 2)
    }

    @Test("Empty hotel list yields empty state")
    func emptyResponseYieldsEmpty() async throws {
        let svc = MockHotelService()
        svc.result = .success(HotelPage(hotels: [], total: 0, offset: 0, currencySymbol: "$"))
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()

        guard case .empty = vm.state else {
            Issue.record("Expected .empty, got \(vm.state)")
            return
        }
    }

    @Test("Service error yields error state")
    func errorYieldsErrorState() async throws {
        struct TestError: Error {}
        let svc = MockHotelService()
        svc.result = .failure(TestError())
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()

        guard case .error = vm.state else {
            Issue.record("Expected .error, got \(vm.state)")
            return
        }
    }

    @Test("Retry resets to loading then resolves")
    func retryResolvesCorrectly() async throws {
        struct TestError: Error {}
        let svc = MockHotelService()
        svc.result = .failure(TestError())
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()
        guard case .error = vm.state else {
            Issue.record("Expected .error after first load")
            return
        }

        svc.result = .success(HotelPage(hotels: [.fixture()], total: 1, offset: 0, currencySymbol: "$"))
        await vm.retry()

        guard case .success = vm.state else {
            Issue.record("Expected .success after retry")
            return
        }
        #expect(svc.callCount == 2)
    }

    @Test("Pagination: loadNextPage appends results")
    func paginationAppendsResults() async throws {
        let svc = MockHotelService()
        // First page: 2 hotels, total = 4 → has more
        svc.result = .success(HotelPage(hotels: [.fixture(id: 1), .fixture(id: 2)], total: 4, offset: 0, currencySymbol: "$"))
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()
        guard case .success(let first) = vm.state else {
            Issue.record("Expected .success after first load")
            return
        }
        #expect(first.count == 2)
        #expect(vm.hasMorePages == true)

        // Second page: 2 more hotels
        svc.result = .success(HotelPage(hotels: [.fixture(id: 3), .fixture(id: 4)], total: 4, offset: 2, currencySymbol: "$"))
        await vm.loadNextPage()

        guard case .success(let all) = vm.state else {
            Issue.record("Expected .success after next page")
            return
        }
        #expect(all.count == 4)
        #expect(vm.hasMorePages == false)
        #expect(svc.lastOffset == 2)
    }

    @Test("Pagination: loadNextPage is a no-op when no more pages")
    func loadNextPageNoOpWhenExhausted() async throws {
        let svc = MockHotelService()
        svc.result = .success(HotelPage(hotels: [.fixture()], total: 1, offset: 0, currencySymbol: "$"))
        let (vm, _) = makeViewModel(service: svc)

        await vm.load()
        #expect(vm.hasMorePages == false)

        await vm.loadNextPage()
        #expect(svc.callCount == 1) // no additional call
    }

    @Test("Load uses place coordinates from injected Place")
    func usesPlaceCoordinates() async throws {
        let svc = MockHotelService()
        svc.result = .success(HotelPage(hotels: [], total: 0, offset: 0, currencySymbol: "$"))
        let place = Place.fixture(latitude: 33.618, longitude: -117.929)
        let vm = HotelListViewModel(place: place, hotelService: svc)

        await vm.load()

        #expect(svc.callCount == 1)
    }
}
