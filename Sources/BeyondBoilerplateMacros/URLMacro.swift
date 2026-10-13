import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// ES: Macro freestanding que valida un URL en compile-time.
// EN: Freestanding macro that validates a URL at compile time.
//
// ES: #URL("https://…") → URL(string: "https://…")!
// EN: #URL("https://…") → URL(string: "https://…")!
public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // ES: Debe haber un argumento.
        // EN: There must be an argument.
        guard let argument = node.arguments.first?.expression else {
            context.diagnose(.urlMissingArgument, on: node)
            return "URL(string: \"\")!"
        }

        // ES: Solo aceptamos un string literal (no una variable).
        // EN: Only a string literal is accepted (not a variable).
        guard let stringLiteral = argument.as(StringLiteralExprSyntax.self),
              stringLiteral.segments.count == 1,
              let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
        else {
            context.diagnose(.urlRequiresStringLiteral, on: argument)
            return "URL(string: \"\")!"
        }

        // ES: Texto crudo dentro de las comillas.
        // EN: Raw text inside the quotes.
        let raw = segment.content.text

        // ES: Comprueba scheme + host ahora, no en runtime.
        // EN: Check scheme + host now, not at runtime.
        guard let url = Foundation.URL(string: raw),
              url.scheme != nil,
              url.host != nil
        else {
            context.diagnose(.urlInvalidLiteral(raw), on: argument)
            return "URL(string: \"\")!"
        }

        // ES: Emite el Swift final que el compilador insertará.
        // EN: Emit the final Swift the compiler will insert.
        return "URL(string: \(literal: raw))!"
    }
}
