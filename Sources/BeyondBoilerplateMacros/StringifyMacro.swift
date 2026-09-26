import SwiftSyntax
import SwiftSyntaxMacros

/// Level 1 — Macro freestanding de expresión.
///
/// `#stringify(expr)` se expande a una tupla `(expr, "expr")`.
/// Objetivo didáctico: mostrar la *expresión AST de entrada* convirtiéndose en un valor
/// en runtime y en un string capturado del texto fuente en compile-time — la demo clásica
/// de "los macros ven el código fuente".
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            context.diagnose(.stringifyMissingArgument, on: node)
            return "()"
        }

        // `argument.description` preserva el texto fuente (operadores, spacing tipo trivia).
        // Esa es la punchline educativa: el compilador ya parseó esto; reutilizamos el texto.
        return "(\(argument), \(literal: argument.description))"
    }
}
