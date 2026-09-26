import SwiftSyntax
import SwiftSyntaxMacros

/// Level 1 — Freestanding expression macro.
///
/// `#stringify(expr)` expands to a tuple `(expr, "expr")`.
/// Teaching goal: show the *input AST expression* becoming both a runtime value
/// and a compile-time string captured from source text — the classic "macros see source" demo.
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            context.diagnose(.stringifyMissingArgument, on: node)
            return "()"
        }

        // `argument.description` preserves source text (operators, trivia-ish spacing).
        // That is the educational punchline: the compiler already parsed this; we reuse the text.
        return "(\(argument), \(literal: argument.description))"
    }
}
