import Foundation
import Observation

@Observable
@MainActor
final class SearchViewModel {
    private(set) var state: ViewState<[Place]> = .idle
    var searchText: String = ""

    private let searchService: any SearchServiceable
    private var searchTask: Task<Void, Never>?
    private var lastQuery: String = ""

    init(searchService: any SearchServiceable) {
        self.searchService = searchService
    }

    // MARK: - Public interface

    func onSearchTextChanged(_ text: String) {
        // Cancel any in-flight debounce + network task before starting a new one.
        searchTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            state = .idle
            lastQuery = ""
            return
        }

        state = .loading
        lastQuery = text

        searchTask = Task {
            // 500 ms debounce — if this task is cancelled before the sleep finishes,
            // the try? silently swallows CancellationError and the guard below prevents
            // the stale request from proceeding.
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch(query: text)
        }
    }

    func retry() {
        guard !lastQuery.isEmpty else { return }
        onSearchTextChanged(lastQuery)
    }

    // MARK: - Private

    private func performSearch(query: String) async {
        do {
            let places = try await searchService.search(terms: query)
            guard !Task.isCancelled else { return }
            state = places.isEmpty ? .empty : .success(places)
        } catch is CancellationError {
            // A newer request superseded this one; leave state as-is.
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error)
        }
    }
}
