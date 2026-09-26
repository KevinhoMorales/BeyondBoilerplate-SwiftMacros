import Foundation

/// Sustituto offline de URLSession.
///
/// Restricción de conferencia: las demos no deben requerir acceso a red.
/// Las respuestas se buscan por endpoint ID / path para que Kevin pueda mostrar un ciclo
/// completo de petición sin depender de la lotería del Wi-Fi del escenario.
public final class InMemoryHTTPClient: @unchecked Sendable {
    public struct StubResponse: Sendable {
        public let statusCode: Int
        public let body: Data

        public init(statusCode: Int = 200, jsonObject: Any) throws {
            self.statusCode = statusCode
            self.body = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        }

        public init(statusCode: Int = 200, body: Data) {
            self.statusCode = statusCode
            self.body = body
        }
    }

    private var stubs: [String: StubResponse]
    private(set) public var recordedDescriptions: [String] = []

    public init(stubs: [String: StubResponse] = [:]) {
        self.stubs = stubs
    }

    public func stub(_ endpointID: String, response: StubResponse) {
        stubs[endpointID] = response
    }

    public func send<E: EndpointProtocol>(_ endpoint: E) throws -> StubResponse {
        let description = endpoint.requestDescription
        recordedDescriptions.append(description)

        if let response = stubs[E.endpointID] ?? stubs[endpoint.path] {
            return response
        }

        // Default amigable para que las demos sigan avanzando aunque se haya olvidado un stub.
        return try StubResponse(
            statusCode: 200,
            jsonObject: [
                "endpoint": E.endpointID,
                "path": endpoint.path,
                "method": endpoint.method.rawValue,
                "query": Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value ?? "") }),
                "note": "No hay stub registrado — devolviendo payload eco.",
            ]
        )
    }
}
