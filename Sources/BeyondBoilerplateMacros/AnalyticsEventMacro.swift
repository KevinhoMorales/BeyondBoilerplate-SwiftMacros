import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Núcleo de conferencia — MemberMacro (+ ExtensionMacro) para payloads de analytics events.
///
/// Sin SDK de terceros: generamos un `eventName` estable y un diccionario `parameters`
/// para que DemoCLI pueda imprimir lo que se enviaría. Objetivo didáctico: los macros brillan
/// cuando convierten un struct tipado en una representación repetitiva de diccionario.
public struct AnalyticsEventMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isStruct else {
            context.diagnose(.analyticsOnlyStructs, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.analyticsNoProperties, on: node)
            return []
        }

        let typeName = declaration.typeNameToken?.text ?? "Event"
        // Nombres de evento tipo snake_case desde el tipo: RestaurantOpened → restaurant_opened (heurística simple).
        let eventName = snakeCase(from: typeName)

        let parameterEntries = properties.map { property in
            "\"\(property.name)\": String(describing: \(property.name))"
        }.joined(separator: ",\n")

        return [
            """
            public static let eventName: String = \(literal: eventName)
            """,
            """
            public var parameters: [String: String] {
                [
                    \(raw: parameterEntries)
                ]
            }
            """,
            """
            public var payloadDescription: String {
                let pairs = parameters.map { "\\($0.key)=\\($0.value)" }.sorted().joined(separator: ", ")
                return "\\(Self.eventName) { \\(pairs) }"
            }
            """,
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.isStruct,
              !StoredProperty.collect(from: declaration).isEmpty
        else {
            return []
        }

        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(type.trimmed): AnalyticsEventProtocol {
            }
            """
        )
        return [extensionDecl]
    }

    /// CamelCase → snake_case mínimo para nombres de evento de demo (no es un word breaker Unicode completo).
    private static func snakeCase(from typeName: String) -> String {
        var result = ""
        for (index, character) in typeName.enumerated() {
            if character.isUppercase, index > 0 {
                result.append("_")
            }
            result.append(character.lowercased())
        }
        return result
    }
}
