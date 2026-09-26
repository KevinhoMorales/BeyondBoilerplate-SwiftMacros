import SwiftSyntax
import SwiftSyntaxMacros

/// Level 2 — MemberMacro.
///
/// `@AutoInit` synthesizes a public memberwise initializer for a struct's stored properties.
/// Teaching goal: MemberMacro inspects the declaration's member block and *emits new members*
/// into the same type — no peer type, no extension.
///
/// Why MemberMacro (not PeerMacro)? The initializer belongs *inside* the annotated type.
/// PeerMacro would emit a sibling declaration at the same scope, which is the wrong shape here.
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

        // Optionals default to `nil` so call sites stay ergonomic without inventing business defaults.
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
