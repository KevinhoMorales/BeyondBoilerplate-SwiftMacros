import SwiftSyntax
import SwiftSyntaxMacros

/// Level 3 — PeerMacro.
///
/// `@MakeBuilder` emits a sibling `*Builder` type next to the annotated struct.
/// Teaching goal: PeerMacro creates *related declarations at the same scope*,
/// not members inside the type (MemberMacro) and not extensions (ExtensionMacro).
///
/// Access level of the peer matches the annotated type so we never emit
/// `public func build() -> InternalType` (a common macro footgun).
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

/// Returns `"public "` when the declaration is public; otherwise `""` (internal).
func accessPrefix(for modifiers: DeclModifierListSyntax) -> String {
    modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) ? "public " : ""
}
