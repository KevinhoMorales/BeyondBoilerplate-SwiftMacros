import Foundation

/// Verbos HTTP usados por las expansiones de `@Endpoint` y el cliente offline.
public enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Protocolo mínimo que satisfacen las conformances de `@Endpoint`.
///
/// Mantén esto intencionalmente pequeño: las apps de producción suelen añadir headers, encoding de body,
/// hooks de auth y decoding de respuesta — eso pertenece a capas reales de networking,
/// no a una demo de macro de conferencia.
public protocol EndpointProtocol: Sendable {
    static var endpointID: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var requestDescription: String { get }
}

extension EndpointProtocol {
    /// Construye un URLRequest contra una base URL en memoria (nunca toca la red).
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
