import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, data: Data)
    case decodingError(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is malformed."
        case .httpError(let code, _):
            return "Server returned an error (HTTP \(code))."
        case .decodingError:
            return "The server response could not be parsed."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
