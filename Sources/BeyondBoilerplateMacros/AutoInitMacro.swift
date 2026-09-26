import SwiftSyntax
import SwiftSyntaxMacros

/// Level 2 — MemberMacro.
///
/// `@AutoInit` sintetiza un inicializador memberwise público para las propiedades almacenadas de un struct.
/// Objetivo didáctico: MemberMacro inspecciona el member block de la declaración y *emite nuevos members*
/// dentro del mismo tipo — sin peer type, sin extension.
///
/// ¿Por qué MemberMacro (no PeerMacro)? El inicializador pertenece *dentro* del tipo anotado.
/// PeerMacro emitiría una declaración hermana en el mismo scope, que es la forma incorrecta aquí.
public struct AutoInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isStruct else {
            context.diagnose(.autoInitOnlyStructs, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.autoInitNoStoredProperties, on: node)
            return []
        }

        let access = accessPrefix(for: declaration.modifiers)

        // Los optionals default a `nil` para que los call sites sigan ergonómicos sin inventar defaults de negocio.
        let parameterList = properties.map { property in
            if property.isOptional {
                return "\(property.name): \(property.type) = nil"
            }
            return "\(property.name): \(property.type)"
        }.joined(separator: ", ")

        let assignments = properties.map { property in
            "self.\(property.name) = \(property.name)"
        }.joined(separator: "\n")

        let initializer: DeclSyntax =
            """
            \(raw: access)init(\(raw: parameterList)) {
                \(raw: assignments)
            }
            """

        return [initializer]
    }
}
