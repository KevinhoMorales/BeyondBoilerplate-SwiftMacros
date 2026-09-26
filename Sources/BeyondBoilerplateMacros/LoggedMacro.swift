import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Level 4 — AccessorMacro.
///
/// `@Logged` adds a `didSet` observer that prints updates.
/// Teaching goal: AccessorMacro attaches accessors to an existing stored property
/// without replacing its storage (unlike get/set computed conversions that need a PeerMacro backing store).
///
/// We intentionally use `didSet` (not get/set) so the property remains stored —
/// fewer moving parts for a live conference explanation.
public struct LoggedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(.loggedOnlyVariables, on: node)
            return []
        }

        let name = pattern.identifier.text
        let accessor = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.didSet),
            body: CodeBlockSyntax {
                """
                print("[Logged] \(raw: name) changed to \\(String(describing: \(raw: name)))")
                """
            }
        )
        return [accessor]
    }
}
