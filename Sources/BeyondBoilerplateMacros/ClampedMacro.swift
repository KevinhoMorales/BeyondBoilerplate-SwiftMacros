import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Level 4b — Composición AccessorMacro + PeerMacro (demo clásica estilo WWDC).
///
/// `@Clamped(min:max:)` mantiene una propiedad numérica dentro de unos límites.
/// - PeerMacro emite storage privado `_name`
/// - AccessorMacro emite get/set que acotan al escribir
///
/// Objetivo didáctico: muchos macros útiles de propiedades son *multi-role* —
/// un atributo, varios protocolos Macro.
public struct ClampedMacro: AccessorMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(.clampedOnlyVariables, on: node)
            return []
        }

        guard let min = node.integerLiteralArgument(labeled: "min"),
              let max = node.integerLiteralArgument(labeled: "max")
        else {
            context.diagnose(.clampedMissingBounds, on: node)
            return []
        }

        let name = pattern.identifier.text
        let storage = "_\(name)"

        let getter = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.get),
            body: CodeBlockSyntax {
                "return \(raw: storage)"
            }
        )

        let setter = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set),
            body: CodeBlockSyntax {
                """
                \(raw: storage) = min(max(newValue, \(raw: min)), \(raw: max))
                """
            }
        )

        return [getter, setter]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let type = binding.typeAnnotation?.type
        else {
            return []
        }

        // Revalidar límites para que la expansión peer falle de forma consistente cuando accessors también diagnostican.
        guard node.integerLiteralArgument(labeled: "min") != nil,
              node.integerLiteralArgument(labeled: "max") != nil
        else {
            return []
        }

        let name = pattern.identifier.text
        let initial = binding.initializer?.value ?? ExprSyntax(IntegerLiteralExprSyntax(0))

        let storage: DeclSyntax =
            """
            private var _\(raw: name): \(type.trimmed) = \(initial)
            """
        return [storage]
    }
}
