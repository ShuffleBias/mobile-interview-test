import Foundation

protocol SearchServiceable: Sendable {
    func search(terms: String) async throws -> [Place]
}

final class LiveSearchService: SearchServiceable {
    private let client: any NetworkClientable

    init(client: any NetworkClientable) {
        self.client = client
    }

    func search(terms: String) async throws -> [Place] {
        let endpoint = Endpoint.get(
            "/api/search/places/autocomplete",
            queryItems: [
                URLQueryItem(name: "terms", value: terms),
                URLQueryItem(name: "limit", value: "10"),
                URLQueryItem(name: "offset", value: "0")
            ]
        )
        return try await client.fetch(endpoint)
    }
}
