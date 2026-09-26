import Foundation

/// HTTP verbs used by `@Endpoint` expansions and the offline client.
public enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Minimal protocol that `@Endpoint` conformances satisfy.
///
/// Keep this intentionally small: production apps often add headers, body encoding,
/// auth hooks, and response decoding — those belong in real networking layers,
/// not in a conference macro demo.
public protocol EndpointProtocol: Sendable {
    static var endpointID: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var requestDescription: String { get }
}

extension EndpointProtocol {
    /// Builds a URLRequest against an in-memory base URL (never hits the network).
    public func makeURLRequest(baseURL: URL = URL(string: "https://demo.local")!) -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path.trimmingPrefix("/")), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url ?? baseURL)
        request.httpMethod = method.rawValue
        return request
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }
        return self
    }
}
