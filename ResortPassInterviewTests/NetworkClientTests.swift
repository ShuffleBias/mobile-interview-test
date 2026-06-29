import Testing
import Foundation
@testable import ResortPassInterview

// MARK: - URLProtocol stub

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

// Serialized because MockURLProtocol uses a shared static handler.
@Suite(.serialized)
struct NetworkClientTests {
    private func makeClient() -> URLSessionNetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSessionNetworkClient(session: URLSession(configuration: config))
    }

    private func makeResponse(statusCode: Int, url: URL = URL(string: "https://staging-app.resortpass.com/test")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    @Test("Decodes valid JSON response into expected type")
    func decodesValidJSON() async throws {
        struct TestResponse: Decodable, Sendable, Equatable {
            let id: Int
            let name: String
        }

        MockURLProtocol.requestHandler = { _ in
            let data = #"{"id": 42, "name": "Test"}"#.data(using: .utf8)!
            return (self.makeResponse(statusCode: 200), data)
        }

        let client = makeClient()
        let endpoint = Endpoint.get("/test")
        let result: TestResponse = try await client.fetch(endpoint)

        #expect(result.id == 42)
        #expect(result.name == "Test")
    }

    @Test("Throws httpError on non-2xx status")
    func throwsHTTPError() async throws {
        MockURLProtocol.requestHandler = { _ in
            let data = Data()
            return (self.makeResponse(statusCode: 404), data)
        }

        let client = makeClient()
        let endpoint = Endpoint.get("/missing")

        await #expect(throws: NetworkError.self) {
            let _: [Place] = try await client.fetch(endpoint)
        }
    }

    @Test("Throws decodingError on malformed JSON")
    func throwsDecodingError() async throws {
        MockURLProtocol.requestHandler = { _ in
            let data = "not-json".data(using: .utf8)!
            return (self.makeResponse(statusCode: 200), data)
        }

        let client = makeClient()
        let endpoint = Endpoint.get("/bad-json")

        await #expect(throws: NetworkError.self) {
            let _: [Place] = try await client.fetch(endpoint)
        }
    }

    @Test("Applies snake_case decoding strategy")
    func snakeCaseDecoding() async throws {
        MockURLProtocol.requestHandler = { _ in
            let data = #"""
            [{"id": 1, "name": "Newport Beach, California", "type": "city",
              "latitude": 33.618, "longitude": -117.929,
              "city_name": "Newport Beach", "state_code": "CA", "country_code": "US"}]
            """#.data(using: .utf8)!
            return (self.makeResponse(statusCode: 200), data)
        }

        let client = makeClient()
        let endpoint = Endpoint.get("/places")
        let places: [Place] = try await client.fetch(endpoint)

        #expect(places.count == 1)
        #expect(places[0].cityName == "Newport Beach")
        #expect(places[0].stateCode == "CA")
    }
}
