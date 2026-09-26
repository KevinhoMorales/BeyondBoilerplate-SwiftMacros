import Foundation

/// Protocol satisfied by `@AnalyticsEvent` expansions.
public protocol AnalyticsEventProtocol: Sendable {
    static var eventName: String { get }
    var parameters: [String: String] { get }
    var payloadDescription: String { get }
}

/// Offline analytics sink — prints / records events instead of talking to a vendor SDK.
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
