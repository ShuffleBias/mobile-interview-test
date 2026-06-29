import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let body: (any Encodable)?

    private static let baseURL = "https://staging-app.resortpass.com"

    static func get(_ path: String, queryItems: [URLQueryItem] = []) -> Endpoint {
        Endpoint(path: path, method: .get, queryItems: queryItems, body: nil)
    }

    static func post<B: Encodable>(_ path: String, body: B) -> Endpoint {
        Endpoint(path: path, method: .post, queryItems: [], body: body)
    }

    func urlRequest() throws -> URLRequest {
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw NetworkError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}
