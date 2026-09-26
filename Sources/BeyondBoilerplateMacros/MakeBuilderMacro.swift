import SwiftSyntax
import SwiftSyntaxMacros

/// Level 3 — PeerMacro.
///
/// `@MakeBuilder` emite un tipo hermano `*Builder` junto al struct anotado.
/// Objetivo didáctico: PeerMacro crea *declaraciones relacionadas en el mismo scope*,
/// no members dentro del tipo (MemberMacro) ni extensions (ExtensionMacro).
///
/// El access level del peer coincide con el del tipo anotado para nunca emitir
/// `public func build() -> InternalType` (un footgun habitual de macros).
public struct MakeBuilderMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(.makeBuilderOnlyStructs, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: structDecl)
        guard !properties.isEmpty else {
            context.diagnose(.makeBuilderNoStoredProperties, on: node)
            return []
        }

        let typeName = structDecl.name.text
        let builderName = "\(typeName)Builder"
        let access = accessPrefix(for: structDecl.modifiers)

        let storedFields = properties.map { property in
            "\(access)var \(property.name): \(property.type) = \(property.type.builderDefaultExpression)"
        }.joined(separator: "\n")

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

/// Devuelve `"public "` cuando la declaración es public; de lo contrario `""` (internal).
func accessPrefix(for modifiers: DeclModifierListSyntax) -> String {
    modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) ? "public " : ""
}
