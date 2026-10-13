import Foundation

/// Tiny educational DI container — deliberately *not* a framework.
///
/// Talk goals:
/// 1. Show what `@AutoRegister` expands into.
/// 2. Debate magic vs explicit registration (test overrides, call-site clarity, debugging).
/// 3. Avoid third-party DI so the package stays fully offline and light on dependencies.
public final class DependencyContainer: @unchecked Sendable {
    public typealias Factory = () -> Any

    private var factories: [ObjectIdentifier: Factory] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]

    public init() {}

    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }

    public func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let existing = singletons[key] as? T {
            return existing
        }
        guard let factory = factories[key], let value = factory() as? T else {
            fatalError("DependencyContainer: no registration for \(type). Register by hand or call Type.register(in:).")
        }
        singletons[key] = value
        return value
    }

    public func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}

/// Example service used by `@AutoRegister` demos.
public struct GreetingService: Sendable {
    public init() {}

    public func greet(name: String) -> String {
        "Hello, \(name) — resolved from DependencyContainer."
    }
}
