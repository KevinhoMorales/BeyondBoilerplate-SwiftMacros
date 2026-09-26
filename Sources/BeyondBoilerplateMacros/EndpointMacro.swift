import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Conference core — MemberMacro + ExtensionMacro for a tiny networking layer.
///
/// ```swift
/// @Endpoint(method: .get, path: "/restaurants")
/// struct GetRestaurants {
///     let city: String
/// }
/// ```
///
/// Expansion supplies EndpointProtocol witnesses used by the offline `InMemoryHTTPClient`.
/// Keep the generated surface small enough to Expand Macro live and still finish the sentence.
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
            // String(describing:) keeps the demo free of Encodable constraints while remaining honest.
            """
            URLQueryItem(name: "\(property.name)", value: String(describing: \(property.name)))
            """
        }.joined(separator: ",\n")

        // Members stay on the type so call sites read as `GetRestaurants(city:).method`.
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
        // Validation already diagnosed in MemberMacro; only emit conformance for valid shapes.
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
