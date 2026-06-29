// In production this file (along with Endpoint.swift and NetworkError.swift) would live in a
// shared Swift package — any ResortPass client app hitting the same APIs should not be
// duplicating this layer. Kept local here since this is a single-app interview project.

import Foundation

protocol NetworkClientable: Sendable {
    func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
}

final class URLSessionNetworkClient: NetworkClientable {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let request: URLRequest
        do {
            request = try endpoint.urlRequest()
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(underlying: error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.unknown(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(underlying: error)
        }
    }
}
