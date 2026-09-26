import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Conference core — MemberMacro (+ ExtensionMacro) for analytics event payloads.
///
/// No third-party SDK: we generate a stable `eventName` and `parameters` dictionary
/// so DemoCLI can print what would be sent. Teaching goal: macros shine when they
/// convert a typed struct into a repetitive dictionary representation.
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
        // snake_case-ish event names from the type: RestaurantOpened → restaurant_opened (simple heuristic).
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

    /// Minimal CamelCase → snake_case for demo event names (not a full Unicode word breaker).
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
