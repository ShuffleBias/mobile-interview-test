import Foundation
import Observation

@Observable
@MainActor
final class SearchHistoryStore {
    private(set) var queries: [String] = []

    private let defaults: UserDefaults
    private let key = "rp.searchHistory"
    private let maxCount = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        queries = defaults.stringArray(forKey: key) ?? []
    }

    // MARK: - Mutations

    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Deduplicate: remove existing occurrence so the new one moves to front
        var updated = queries.filter { $0.localizedCaseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        queries = Array(updated.prefix(maxCount))
        persist()
    }

    func remove(at offsets: IndexSet) {
        queries.remove(atOffsets: offsets)
        persist()
    }

    func clear() {
        queries = []
        persist()
    }

    // MARK: - Private

    private func persist() {
        defaults.set(queries, forKey: key)
    }
}
