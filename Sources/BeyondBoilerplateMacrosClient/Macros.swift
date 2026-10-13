import DemoSupport
import Foundation

// MARK: - Basic: Freestanding expression

/// Classic teaching macro: `#stringify(expr)` → `(expr, "expr")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "StringifyMacro")

/// Compile-time validated URL literal: `#URL("https://…")` → `URL(string:)!`.
/// Invalid schemes/hosts fail the build with a diagnostic.
@freestanding(expression)
public macro URL(_ string: StaticString) -> URL =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "URLMacro")

// MARK: - Basic: Attached description

/// Synthesizes `CustomStringConvertible` from stored properties (everyday models).
@attached(extension, conformances: CustomStringConvertible, names: named(description))
@attached(member, names: named(description))
public macro Describable() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "DescribableMacro")

// MARK: - Intermediate: Member / Peer / Accessor

/// Synthesizes a public memberwise `init` for stored properties.
@attached(member, names: named(init))
public macro AutoInit() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoInitMacro")

/// Emits a sibling peer `TypeBuilder` with fluent-style defaults.
@attached(peer, names: suffixed(Builder))
public macro MakeBuilder() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "MakeBuilderMacro")

/// Adds a `didSet` logger to a stored property.
@attached(accessor, names: named(didSet))
public macro Logged() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "LoggedMacro")

/// Clamps integer writes to `[min, max]` using peer storage + accessor get/set.
@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Clamped(min: Int, max: Int) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "ClampedMacro")

/// Adds `Equatable` by comparing stored properties.
/// Check the README limitations before using this pattern in production.
@attached(extension, conformances: Equatable, names: named(==))
@attached(member, names: named(==))
public macro AutoEquatable() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoEquatableMacro")

// MARK: - Advanced: Production demos

/// Networking endpoint boilerplate → `EndpointProtocol` witnesses for `InMemoryHTTPClient`.
@attached(
    member,
    names: named(endpointID), named(method), named(path), named(queryItems), named(requestDescription)
)
@attached(extension, conformances: EndpointProtocol)
public macro Endpoint(method: HTTPMethod, path: String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "EndpointMacro")

/// Analytics event boilerplate → event name + parameters dictionary (no vendor SDK).
@attached(
    member,
    names: named(eventName), named(parameters), named(payloadDescription)
)
@attached(extension, conformances: AnalyticsEventProtocol)
public macro AnalyticsEvent() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AnalyticsEventMacro")

/// Educational DI: emits `static func register(in: DependencyContainer)`.
@attached(member, names: named(register))
public macro AutoRegister() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoRegisterMacro")
