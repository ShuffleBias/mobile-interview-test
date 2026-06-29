import Foundation

// MARK: - Top-level response

struct HotelSearchResponse: Decodable, Sendable {
    let total: Int?
    let hotels: [Hotel]
    let currency: Currency?
}

// MARK: - Hotel

struct Hotel: Decodable, Hashable, Sendable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double?
    let longitude: Double?
    let cityName: String?
    let state: String?
    let stateCode: String?
    let countryCode: String?
    let hotelStar: Int?
    let rating: Double?
    let avgRating: Double?
    let reviews: Int?
    let shortDesc: String?
    let desktopImg: String?
    let image: [HotelImageWrapper]?
    let products: [HotelProduct]?
    let productName: String?
    let productCategories: [String]?
    let amenities: [HotelAmenity]?
    let vibes: HotelVibes?
    let url: String?
    let distanceMiles: Double?
    let distanceText: String?
    let availability: Bool?
    let canBeCancelled: Bool?
    let closedForSeason: Bool?

    // Derived helpers

    /// The best available image URL from the images array, falling back to desktopImg.
    /// NOTE: results.url is already absolute; picture.url is a relative path needing the base prefix.
    var primaryImageURL: URL? {
        if let str = image?.first?.picture?.results?.url, let url = URL(string: str) {
            return url
        }
        if let path = image?.first?.picture?.url {
            return URL(string: "https://assets-staging.resortpass.dev\(path)")
        }
        if let desktop = desktopImg {
            return URL(string: desktop)
        }
        return nil
    }

    /// Picks the first available product with a price, falling back to the product name field.
    var featuredProduct: HotelProduct? {
        products?.first(where: { $0.price != nil })
    }
}

// MARK: - Nested types

struct HotelImageWrapper: Decodable, Hashable, Sendable {
    let picture: HotelPicture?
}

struct HotelPicture: Decodable, Hashable, Sendable {
    let url: String?
    let results: HotelPictureVariant?
    let details: HotelPictureVariant?
}

struct HotelPictureVariant: Decodable, Hashable, Sendable {
    let url: String?
}

struct HotelProduct: Decodable, Hashable, Sendable, Identifiable {
    let id: Int
    let name: String?
    let price: Double?
    let productTypeName: String?
    let productTypeId: Int?
    let availability: String?
    let quantity: Int?
}

struct HotelAmenity: Decodable, Hashable, Sendable {
    let name: String?
    let description: String?
    let iconText: String?
}

struct HotelVibes: Decodable, Hashable, Sendable {
    let primary: String?
    let secondary: String?
}

struct Currency: Decodable, Sendable {
    let symbol: String?
    let isoCode: String?
    let name: String?
}
