import DemoSupport
import Foundation

// MARK: - Level 1: Freestanding expression

/// Macro clásico de enseñanza: `#stringify(expr)` → `(expr, "expr")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "StringifyMacro")

// MARK: - Level 2: MemberMacro

/// Sintetiza un `init` memberwise público para las propiedades almacenadas.
@attached(member, names: named(init))
public macro AutoInit() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoInitMacro")

// MARK: - Level 3: PeerMacro

/// Emite un peer hermano `TypeBuilder` con defaults tipo fluent.
@attached(peer, names: suffixed(Builder))
public macro MakeBuilder() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "MakeBuilderMacro")

// MARK: - Level 4: AccessorMacro

/// Añade un logger `didSet` a una propiedad almacenada.
@attached(accessor, names: named(didSet))
public macro Logged() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "LoggedMacro")

/// Acota escrituras de enteros a `[min, max]` usando Peer storage + Accessor get/set.
@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Clamped(min: Int, max: Int) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "ClampedMacro")

// MARK: - Level 5: Extension / Conformance

/// Añade `Equatable` comparando propiedades almacenadas.
/// Consulta las limitaciones del README antes de usar este patrón en producción.
@attached(extension, conformances: Equatable, names: named(==))
@attached(member, names: named(==))
public macro AutoEquatable() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoEquatableMacro")

// MARK: - Production demos

/// Boilerplate de networking endpoint → witnesses de `EndpointProtocol` para `InMemoryHTTPClient`.
@attached(
    member,
    names: named(endpointID), named(method), named(path), named(queryItems), named(requestDescription)
)
@attached(extension, conformances: EndpointProtocol)
public macro Endpoint(method: HTTPMethod, path: String) =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "EndpointMacro")

/// Boilerplate de analytics event → nombre + diccionario de parameters (sin SDK de vendor).
@attached(
    member,
    names: named(eventName), named(parameters), named(payloadDescription)
)
@attached(extension, conformances: AnalyticsEventProtocol)
public macro AnalyticsEvent() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AnalyticsEventMacro")

/// DI educativa: emite `static func register(in: DependencyContainer)`.
@attached(member, names: named(register))
public macro AutoRegister() =
    #externalMacro(module: "BeyondBoilerplateMacros", type: "AutoRegisterMacro")
