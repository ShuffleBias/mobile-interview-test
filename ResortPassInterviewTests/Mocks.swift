import Foundation
@testable import ResortPassInterview

// MARK: - Mock Search Service

final class MockSearchService: SearchServiceable, @unchecked Sendable {
    var result: Result<[Place], Error> = .success([])
    var callCount = 0
    var lastTerms: String?

    func search(terms: String) async throws -> [Place] {
        callCount += 1
        lastTerms = terms
        return try result.get()
    }
}

// MARK: - Mock Hotel Service

final class MockHotelService: HotelServiceable, @unchecked Sendable {
    var result: Result<HotelPage, Error> = .success(HotelPage(hotels: [], total: 0, offset: 0, currencySymbol: "$"))
    var callCount = 0
    var lastOffset: Int = 0

    func fetchHotels(latitude: Double, longitude: Double, offset: Int) async throws -> HotelPage {
        callCount += 1
        lastOffset = offset
        return try result.get()
    }
}

// MARK: - Fixtures

extension Place {
    static func fixture(
        id: Int = 1,
        name: String = "New York",
        type: String = "city",
        latitude: Double = 40.757,
        longitude: Double = -73.986
    ) -> Place {
        Place(
            id: id,
            name: name,
            type: type,
            detailedType: type,
            url: nil,
            parentId: nil,
            parentType: nil,
            stateCode: "NY",
            countryCode: "US",
            cityName: name,
            latitude: latitude,
            longitude: longitude,
            distanceSearchOnly: false
        )
    }
}

extension Hotel {
    static func fixture(id: Int = 1, name: String = "Test Hotel") -> Hotel {
        Hotel(
            id: id,
            name: name,
            latitude: 40.7,
            longitude: -73.9,
            cityName: "New York",
            state: "New York",
            stateCode: "NY",
            countryCode: "US",
            hotelStar: 4,
            rating: 4.2,
            avgRating: 4.2,
            reviews: 100,
            shortDesc: nil,
            desktopImg: nil,
            image: nil,
            products: [
                HotelProduct(
                    id: 1,
                    name: "Day Pass",
                    price: 75.0,
                    productTypeName: "Day Pass",
                    productTypeId: 1,
                    availability: "available",
                    quantity: 10
                )
            ],
            productName: "Day Pass",
            productCategories: ["Pool"],
            amenities: nil,
            vibes: nil,
            url: "test-hotel",
            distanceMiles: 2.5,
            distanceText: "2.5 mi",
            availability: true,
            canBeCancelled: true,
            closedForSeason: false
        )
    }
}
