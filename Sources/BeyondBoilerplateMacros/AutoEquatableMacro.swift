import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Level 5 — ExtensionMacro (+ MemberMacro para `==`).
///
/// `@AutoEquatable` añade conformance `Equatable` comparando propiedades almacenadas.
/// Objetivo didáctico: ExtensionMacro es la herramienta correcta cuando necesitas una conformance *fuera*
/// del cuerpo del tipo. MemberMacro solo no puede declarar `extension Foo: Equatable`.
///
/// LIMITACIONES (dílo en el escenario):
/// - No maneja tipos por referencia / igualdad de identidad.
/// - No sintetiza Hashable ni Codable (necesitan algoritmos y modos de fallo distintos).
/// - Omite propiedades computed — solo participa el estado almacenado.
public struct AutoEquatableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.isStruct else {
            context.diagnose(.autoEquatableOnlyStructs, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.autoEquatableNoStoredProperties, on: node)
            return []
        }

        // ExtensionMacro aporta la conformance; MemberMacro aportaría `static func ==`.
        // Cuando ambos roles están presentes, Swift puede pedir a ExtensionMacro que solo declare
        // la conformance y a MemberMacro que añada el witness — emitimos `==` en la extension
        // para una sola expansión legible que los estudiantes puedan Expand Macro.
        let comparisons = properties.map { property in
            "lhs.\(property.name) == rhs.\(property.name)"
        }.joined(separator: " && ")

        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(type.trimmed): Equatable {
                public static func == (lhs: \(type.trimmed), rhs: \(type.trimmed)) -> Bool {
                    \(raw: comparisons)
                }
            }
            """
        )

        return [extensionDecl]
    }

    /// El rol MemberMacro es intencionalmente no-op: `==` vive en la extension generada
    /// para que Expand Macro muestre un bloque cohesivo. Mantener la conformance del protocolo
    /// documenta que los macros multi-role pueden repartir trabajo entre roles cuando hace falta.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
