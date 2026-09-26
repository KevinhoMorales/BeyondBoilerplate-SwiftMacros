import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Level 4 — AccessorMacro.
///
/// `@Logged` añade un observer `didSet` que imprime actualizaciones.
/// Objetivo didáctico: AccessorMacro adjunta accessors a una propiedad almacenada existente
/// sin reemplazar su storage (a diferencia de conversiones get/set computed que necesitan
/// un backing store vía PeerMacro).
///
/// Usamos `didSet` a propósito (no get/set) para que la propiedad siga siendo stored —
/// menos piezas móviles para una explicación en vivo de conferencia.
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
