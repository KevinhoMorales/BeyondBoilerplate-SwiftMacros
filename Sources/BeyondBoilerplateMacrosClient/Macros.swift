import DemoSupport
import Foundation

// MARK: - Level 1: Freestanding expression

/// Classic teaching macro: `#stringify(expr)` → `(expr, "expr")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "StringifyMacro")

// MARK: - Level 2: MemberMacro

/// Synthesizes a public memberwise `init` for stored properties.
@attached(member, names: named(init))
public macro AutoInit() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoInitMacro")

// MARK: - Level 3: PeerMacro

/// Emits a sibling `TypeBuilder` peer with fluent-ish defaults.
@attached(peer, names: suffixed(Builder))
public macro MakeBuilder() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "MakeBuilderMacro")

// MARK: - Level 4: AccessorMacro

/// Adds a `didSet` logger to a stored property.
@attached(accessor, names: named(didSet))
public macro Logged() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "LoggedMacro")

/// Clamps integer writes into `[min, max]` using Peer storage + Accessor get/set.
@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Clamped(min: Int, max: Int) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "ClampedMacro")

// MARK: - Level 5: Extension / Conformance

/// Adds `Equatable` by comparing stored properties.
/// See README limitations before using this pattern in production.
@attached(extension, conformances: Equatable, names: named(==))
@attached(member, names: named(==))
public macro AutoEquatable() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoEquatableMacro")

// MARK: - Production demos

/// Networking endpoint boilerplate → `EndpointProtocol` witnesses for `InMemoryHTTPClient`.
@attached(
    member,
    names: named(endpointID), named(method), named(path), named(queryItems), named(requestDescription)
)
@attached(extension, conformances: EndpointProtocol)
public macro Endpoint(method: HTTPMethod, path: String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "EndpointMacro")

/// Analytics event boilerplate → name + parameter dictionary (no vendor SDK).
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
