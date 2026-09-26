import SwiftSyntax
import SwiftSyntaxMacros

/// Núcleo de conferencia — MemberMacro para registro de DI educativa.
///
/// `@AutoRegister` añade `static func register(in:)` que inserta `Self` en
/// el pequeño `DependencyContainer`. Objetivo didáctico: mostrar la *tentación* del registro
/// mágico — y forzar que el README / DemoCLI discutan cuándo el registro manual
/// es más claro para debugging y overrides de test.
public struct AutoRegisterMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isStruct || declaration.isClass else {
            context.diagnose(.autoRegisterOnlyNominalTypes, on: node)
            return []
        }

        guard let typeName = declaration.typeNameToken?.text else {
            context.diagnose(.autoRegisterRequiresTypeName, on: node)
            return []
        }

        // Exigimos un inicializador de cero argumentos en el call site de `register`.
        // Diagnosticar inits faltantes en tiempo de macro se evita a propósito: eso necesita
        // info completa de type-checking que los macros no tienen de forma fiable. Documenta el contrato en su lugar.
        let method: DeclSyntax =
            """
            public static func register(in container: DependencyContainer) {
                container.register(\(raw: typeName).self) {
                    \(raw: typeName)()
                }
            }
            """

        return [method]
    }
}
