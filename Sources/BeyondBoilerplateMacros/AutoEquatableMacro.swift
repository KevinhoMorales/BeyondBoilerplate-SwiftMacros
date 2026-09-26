import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Level 5 — ExtensionMacro (+ MemberMacro for `==`).
///
/// `@AutoEquatable` adds `Equatable` conformance by comparing stored properties.
/// Teaching goal: ExtensionMacro is the right tool when you need a conformance *outside*
/// the type body. MemberMacro alone cannot declare `extension Foo: Equatable`.
///
/// LIMITATIONS (say this on stage):
/// - Does not handle reference types / identity equality.
/// - Does not synthesize Hashable or Codable (those need different algorithms and failure modes).
/// - Skips computed properties — only stored state participates.
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

        // ExtensionMacro supplies the conformance; MemberMacro supplies `static func ==`.
        // When both roles are present, Swift may ask ExtensionMacro to only declare
        // the conformance and MemberMacro to add the witness — we emit `==` in the extension
        // for a single readable expansion students can Expand Macro on.
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

    /// MemberMacro role is intentionally a no-op: `==` lives in the generated extension
    /// so Expand Macro shows one cohesive block. Keeping the protocol conformance
    /// documents that multi-role macros can split work across roles when needed.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
