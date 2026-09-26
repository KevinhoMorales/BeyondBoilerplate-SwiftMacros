import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Núcleo de conferencia — MemberMacro + ExtensionMacro para una capa mínima de networking.
///
/// ```swift
/// @Endpoint(method: .get, path: "/restaurants")
/// struct GetRestaurants {
///     let city: String
/// }
/// ```
///
/// La expansión aporta witnesses de EndpointProtocol usados por el `InMemoryHTTPClient` offline.
/// Mantén la superficie generada lo bastante pequeña para Expand Macro en vivo y aún terminar la frase.
public struct EndpointMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isStruct else {
            context.diagnose(.endpointOnlyStructs, on: node)
            return []
        }

        guard let methodExpr = node.argument(labeled: "method"),
              let path = node.stringLiteralArgument(labeled: "path")
        else {
            context.diagnose(.endpointMissingArguments, on: node)
            return []
        }

        guard !path.isEmpty, path.hasPrefix("/") else {
            context.diagnose(.endpointEmptyPath, on: node)
            return []
        }

        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.endpointNoProperties, on: node)
            return []
        }

        let typeName = declaration.typeNameToken?.text ?? "Endpoint"
        let queryPairs = properties.map { property in
            // String(describing:) mantiene la demo libre de constraints Encodable y sigue siendo honesta.
            """
            URLQueryItem(name: "\(property.name)", value: String(describing: \(property.name)))
            """
        }.joined(separator: ",\n")

        // Los members viven en el tipo para que los call sites se lean como `GetRestaurants(city:).method`.
        let members: [DeclSyntax] = [
            """
            public static let endpointID: String = "\(raw: typeName)"
            """,
            """
            public var method: HTTPMethod { \(methodExpr) }
            """,
            """
            public var path: String { \(literal: path) }
            """,
            """
            public var queryItems: [URLQueryItem] {
                [
                    \(raw: queryPairs)
                ]
            }
            """,
            """
            public var requestDescription: String {
                "\\(method.rawValue) \\(path) [\\(Self.endpointID)]"
            }
            """,
        ]

        return members
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // La validación ya diagnosticó en MemberMacro; solo emite conformance para formas válidas.
        guard declaration.isStruct,
              node.argument(labeled: "method") != nil,
              let path = node.stringLiteralArgument(labeled: "path"),
              !path.isEmpty,
              path.hasPrefix("/"),
              !StoredProperty.collect(from: declaration).isEmpty
        else {
            return []
        }

        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(type.trimmed): EndpointProtocol {
            }
            """
        )
        return [extensionDecl]
    }
}
