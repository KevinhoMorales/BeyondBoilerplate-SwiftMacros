import Foundation

/// Protocolo que satisfacen las expansiones de `@AnalyticsEvent`.
public protocol AnalyticsEventProtocol: Sendable {
    static var eventName: String { get }
    var parameters: [String: String] { get }
    var payloadDescription: String { get }
}

/// Sink de analytics offline — imprime / registra eventos en lugar de hablar con un SDK de vendor.
public final class InMemoryAnalytics: @unchecked Sendable {
    private(set) public var events: [(name: String, parameters: [String: String])] = []

    public init() {}

    public func track(_ event: some AnalyticsEventProtocol) {
        events.append((name: type(of: event).eventName, parameters: event.parameters))
    }

    public func reset() {
        events.removeAll()
    }
}
