import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// ES: Macro attached (extension) — genera CustomStringConvertible.
// EN: Attached (extension) macro — synthesizes CustomStringConvertible.
public struct DescribableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // ES: Solo structs (como @AutoInit).
        // EN: Structs only (same as @AutoInit).
        guard declaration.isStruct else {
            context.diagnose(.describableOnlyStructs, on: node)
            return []
        }

        // ES: Recoge propiedades almacenadas del tipo anotado.
        // EN: Collect stored properties from the annotated type.
        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.describableNoStoredProperties, on: node)
            return []
        }

        // ES: Nombre del tipo para el string "Dish(…)".
        // EN: Type name for the "Dish(…)" string.
        let typeName = declaration.typeNameToken?.text ?? "Type"

        // ES: Cada propiedad → "name: \(name)" en el description.
        // EN: Each property → "name: \(name)" in description.
        let parts = properties.map { property in
            "\(property.name): \\(\(property.name))"
        }.joined(separator: ", ")

        // ES: Emite la extension con var description.
        // EN: Emit the extension with var description.
        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(type.trimmed): CustomStringConvertible {
                public var description: String {
                    "\(raw: typeName)(\(raw: parts))"
                }
            }
            """
        )
        return [extensionDecl]
    }

    // ES: Rol member vacío — description vive en la extension.
    // EN: Empty member role — description lives in the extension.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
