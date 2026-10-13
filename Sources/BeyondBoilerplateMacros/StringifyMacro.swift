import SwiftSyntax
import SwiftSyntaxMacros

// ES: Macro freestanding de expresión (#stringify).
// EN: Freestanding expression macro (#stringify).
//
// ES: Expande #stringify(expr) a la tupla (expr, "expr").
// EN: Expands #stringify(expr) to the tuple (expr, "expr").
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // ES: Lee el primer argumento de la llamada al macro.
        // EN: Read the first argument of the macro call.
        guard let argument = node.arguments.first?.expression else {
            // ES: Sin argumento → diagnóstico de error en compile-time.
            // EN: No argument → compile-time error diagnostic.
            context.diagnose(.stringifyMissingArgument, on: node)
            return "()"
        }

        // ES: argument es el AST; argument.description es el texto fuente.
        // EN: argument is the AST; argument.description is the source text.
        // ES: Devolvemos código Swift: (valor, "texto").
        // EN: We return Swift code: (value, "text").
        return "(\(argument), \(literal: argument.description))"
    }
}
