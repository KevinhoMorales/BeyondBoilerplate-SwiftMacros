import SwiftSyntax
import SwiftSyntaxMacros

// ES: PeerMacro — declara un tipo *hermano* en el mismo scope.
// EN: PeerMacro — declares a *sibling* type in the same scope.
//
// ES: @MakeBuilder emite TypeBuilder junto a Type.
// EN: @MakeBuilder emits TypeBuilder next to Type.
public struct MakeBuilderMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // ES: Necesitamos un StructDeclSyntax (no enum/class).
        // EN: We need a StructDeclSyntax (not enum/class).
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(.makeBuilderOnlyStructs, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: structDecl)
        guard !properties.isEmpty else {
            context.diagnose(.makeBuilderNoStoredProperties, on: node)
            return []
        }

        // ES: Nombre del peer = NombreDelTipo + "Builder".
        // EN: Peer name = TypeName + "Builder".
        let typeName = structDecl.name.text
        let builderName = "\(typeName)Builder"
        let access = accessPrefix(for: structDecl.modifiers)

        // ES: Campos del builder con defaults seguros.
        // EN: Builder fields with safe defaults.
        let storedFields = properties.map { property in
            "\(access)var \(property.name): \(property.type) = \(property.type.builderDefaultExpression)"
        }.joined(separator: "\n")

        // ES: build() llama al init del tipo original.
        // EN: build() calls the original type's init.
        let buildArgs = properties.map { property in
            "\(property.name): \(property.name)"
        }.joined(separator: ", ")

        let builder: DeclSyntax =
            """
            \(raw: access)struct \(raw: builderName) {
                \(raw: storedFields)

                \(raw: access)init() {}

                \(raw: access)func build() -> \(raw: typeName) {
                    \(raw: typeName)(\(raw: buildArgs))
                }
            }
            """

        return [builder]
    }
}

// ES: Prefijo "public " si el tipo es public; si no, vacío (internal).
// EN: "public " prefix if the type is public; otherwise empty (internal).
func accessPrefix(for modifiers: DeclModifierListSyntax) -> String {
    modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) ? "public " : ""
}
