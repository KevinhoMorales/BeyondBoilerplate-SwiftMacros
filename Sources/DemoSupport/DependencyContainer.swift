import Foundation

/// Contenedor DI educativo diminuto — deliberadamente *no* es un framework.
///
/// Objetivos para la charla:
/// 1. Mostrar en qué se expande `@AutoRegister`.
/// 2. Debatir magia vs registro explícito (overrides de test, claridad del call-site, debugging).
/// 3. Evitar DI de terceros para que el paquete siga totalmente offline y ligero de dependencias.
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
            fatalError("DependencyContainer: no hay registro para \(type). Registra a mano o llama Type.register(in:).")
        }
        singletons[key] = value
        return value
    }

    public func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}

/// Servicio de ejemplo usado por demos de `@AutoRegister`.
public struct GreetingService: Sendable {
    public init() {}

    public func greet(name: String) -> String {
        "Hola, \(name) — resuelto desde DependencyContainer."
    }
}
