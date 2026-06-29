import Foundation

// MARK: - Domain value type for a single page of hotel results

struct HotelPage: Sendable {
    let hotels: [Hotel]
    let total: Int
    let offset: Int
    /// Currency symbol from the API response (e.g. "$", "€"). Defaults to "$" when absent.
    let currencySymbol: String
}

// MARK: - Contract

protocol HotelServiceable: Sendable {
    func fetchHotels(latitude: Double, longitude: Double, offset: Int) async throws -> HotelPage
}

// MARK: - Live implementation

final class LiveHotelService: HotelServiceable {
    private let client: any NetworkClientable

    init(client: any NetworkClientable) {
        self.client = client
    }

    func fetchHotels(latitude: Double, longitude: Double, offset: Int) async throws -> HotelPage {
        struct RequestBody: Encodable {
            struct Location: Encodable {
                let latitude: Double
                let longitude: Double
            }
            let location: Location
            let limit: Int
            let offset: Int
        }

        let body = RequestBody(
            location: .init(latitude: latitude, longitude: longitude),
            limit: 30,
            offset: offset
        )
        let endpoint = Endpoint.post("/api/search/algolia_hotels_v7", body: body)
        let response: HotelSearchResponse = try await client.fetch(endpoint)
        return HotelPage(
            hotels: response.hotels,
            total: response.total ?? response.hotels.count,
            offset: offset,
            currencySymbol: response.currency?.symbol ?? "$"
        )
    }
}
