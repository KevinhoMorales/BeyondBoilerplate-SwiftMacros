import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// ES: AccessorMacro + PeerMacro — un atributo, dos roles.
// EN: AccessorMacro + PeerMacro — one attribute, two roles.
//
// ES: Peer escribe _name; Accessor escribe get/set que acotan.
// EN: Peer writes _name; Accessor writes get/set that clamp.
public struct ClampedMacro: AccessorMacro, PeerMacro {
    // MARK: Accessors

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // ES: Debe ser una propiedad var con nombre.
        // EN: Must be a named var property.
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(.clampedOnlyVariables, on: node)
            return []
        }

        // ES: Lee min: y max: del atributo @Clamped(min:max:).
        // EN: Read min: and max: from @Clamped(min:max:).
        guard let min = node.integerLiteralArgument(labeled: "min"),
              let max = node.integerLiteralArgument(labeled: "max")
        else {
            context.diagnose(.clampedMissingBounds, on: node)
            return []
        }

        let name = pattern.identifier.text
        let storage = "_\(name)"

        // ES: get devuelve el storage privado.
        // EN: get returns the private storage.
        let getter = AccessorDeclSyntax(
            accessorSpecifier: .keyword(.get),
            body: CodeBlockSyntax {
                "return \(raw: storage)"
            }
        )

        // ES: set acota newValue entre min y max.
        // EN: set clamps newValue between min and max.
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

    // MARK: Peer storage

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

        // ES: Sin límites válidos, no emitas storage (el accessor ya diagnosticó).
        // EN: Without valid bounds, skip storage (accessor already diagnosed).
        guard node.integerLiteralArgument(labeled: "min") != nil,
              node.integerLiteralArgument(labeled: "max") != nil
        else {
            return []
        }

        let name = pattern.identifier.text
        let initial = binding.initializer?.value ?? ExprSyntax(IntegerLiteralExprSyntax(0))

        // ES: Storage privado _percentage junto a la propiedad.
        // EN: Private _percentage storage beside the property.
        let storage: DeclSyntax =
            """
            private var _\(raw: name): \(type.trimmed) = \(initial)
            """
        return [storage]
    }
}
