import Testing
import Foundation
@testable import ResortPassInterview

@MainActor
struct SearchViewModelTests {
    private func makeViewModel(service: MockSearchService = MockSearchService()) -> (SearchViewModel, MockSearchService) {
        let svc = service
        let vm = SearchViewModel(searchService: svc)
        return (vm, svc)
    }

    @Test("Empty text transitions state to idle without calling service")
    func emptyTextGoesIdle() async throws {
        let (vm, svc) = makeViewModel()
        vm.onSearchTextChanged("")
        #expect(svc.callCount == 0)
        guard case .idle = vm.state else {
            Issue.record("Expected .idle state, got \(vm.state)")
            return
        }
    }

    @Test("Whitespace-only text transitions state to idle without calling service")
    func whitespaceGoesIdle() async throws {
        let (vm, svc) = makeViewModel()
        vm.onSearchTextChanged("   ")
        #expect(svc.callCount == 0)
        guard case .idle = vm.state else {
            Issue.record("Expected .idle state")
            return
        }
    }

    @Test("Non-empty text sets loading state immediately")
    func nonEmptyTextSetsLoadingImmediately() async throws {
        let (vm, _) = makeViewModel()
        vm.onSearchTextChanged("Miami")
        guard case .loading = vm.state else {
            Issue.record("Expected .loading immediately after onSearchTextChanged")
            return
        }
    }

    @Test("Successful search with results yields success state")
    func successfulSearchYieldsSuccess() async throws {
        let svc = MockSearchService()
        svc.result = .success([.fixture(name: "Miami Beach")])
        let (vm, _) = makeViewModel(service: svc)

        // Bypass the 500 ms debounce by calling performSearch directly via a workaround:
        // we call onSearchTextChanged and then wait long enough for debounce + network.
        vm.onSearchTextChanged("Miami")
        try await Task.sleep(for: .milliseconds(700))

        guard case .success(let places) = vm.state else {
            Issue.record("Expected .success, got \(vm.state)")
            return
        }
        #expect(places.count == 1)
        #expect(places[0].name == "Miami Beach")
    }

    @Test("Empty results from service yields empty state")
    func emptyResultsYieldsEmptyState() async throws {
        let svc = MockSearchService()
        svc.result = .success([])
        let (vm, _) = makeViewModel(service: svc)

        vm.onSearchTextChanged("xyzzy")
        try await Task.sleep(for: .milliseconds(700))

        guard case .empty = vm.state else {
            Issue.record("Expected .empty, got \(vm.state)")
            return
        }
    }

    @Test("Service error yields error state")
    func serviceErrorYieldsErrorState() async throws {
        struct TestError: Error {}
        let svc = MockSearchService()
        svc.result = .failure(TestError())
        let (vm, _) = makeViewModel(service: svc)

        vm.onSearchTextChanged("fail")
        try await Task.sleep(for: .milliseconds(700))

        guard case .error = vm.state else {
            Issue.record("Expected .error, got \(vm.state)")
            return
        }
    }

    @Test("Rapid input changes cancel previous tasks and only call service once")
    func rapidInputCancelsDebounce() async throws {
        let svc = MockSearchService()
        svc.result = .success([.fixture()])
        let (vm, _) = makeViewModel(service: svc)

        // Fire 5 changes within 100 ms windows — well within the 500 ms debounce.
        vm.onSearchTextChanged("a")
        try await Task.sleep(for: .milliseconds(50))
        vm.onSearchTextChanged("ab")
        try await Task.sleep(for: .milliseconds(50))
        vm.onSearchTextChanged("abc")
        try await Task.sleep(for: .milliseconds(50))
        vm.onSearchTextChanged("abcd")
        try await Task.sleep(for: .milliseconds(50))
        vm.onSearchTextChanged("abcde")

        // Wait for debounce + service call to complete
        try await Task.sleep(for: .milliseconds(700))

        // Only the last query should have reached the service.
        #expect(svc.callCount == 1)
        #expect(svc.lastTerms == "abcde")
    }

    @Test("Retry re-triggers the last search")
    func retryReTriggersLastSearch() async throws {
        struct TestError: Error {}
        let svc = MockSearchService()
        svc.result = .failure(TestError())
        let (vm, _) = makeViewModel(service: svc)

        vm.onSearchTextChanged("NYC")
        try await Task.sleep(for: .milliseconds(700))

        // Now fix the service and retry
        svc.result = .success([.fixture(name: "New York City")])
        vm.retry()
        try await Task.sleep(for: .milliseconds(700))

        guard case .success = vm.state else {
            Issue.record("Expected .success after retry")
            return
        }
    }
}
