import SwiftSyntax
import SwiftSyntaxMacros

// ES: MemberMacro — escribe members *dentro* del tipo anotado.
// EN: MemberMacro — writes members *inside* the annotated type.
//
// ES: @AutoInit genera un init memberwise público.
// EN: @AutoInit synthesizes a public memberwise init.
public struct AutoInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // ES: Solo structs tienen este patrón simple.
        // EN: Only structs get this simple pattern.
        guard declaration.isStruct else {
            context.diagnose(.autoInitOnlyStructs, on: node)
            return []
        }

        // ES: Lista de propiedades let/var almacenadas.
        // EN: List of stored let/var properties.
        let properties = StoredProperty.collect(from: declaration)
        guard !properties.isEmpty else {
            context.diagnose(.autoInitNoStoredProperties, on: node)
            return []
        }

        // ES: Respeta public si el struct es public.
        // EN: Honor public if the struct is public.
        let access = accessPrefix(for: declaration.modifiers)

        // ES: Optionals → parámetro = nil por defecto.
        // EN: Optionals → parameter defaults to nil.
        let parameterList = properties.map { property in
            if property.isOptional {
                return "\(property.name): \(property.type) = nil"
            }
            return "\(property.name): \(property.type)"
        }.joined(separator: ", ")

        // ES: Cuerpo: self.x = x para cada propiedad.
        // EN: Body: self.x = x for each property.
        let assignments = properties.map { property in
            "self.\(property.name) = \(property.name)"
        }.joined(separator: "\n")

        // ES: DeclSyntax es el pedazo de Swift que se inserta.
        // EN: DeclSyntax is the Swift snippet that gets inserted.
        let initializer: DeclSyntax =
            """
            \(raw: access)init(\(raw: parameterList)) {
                \(raw: assignments)
            }
            """

        return [initializer]
    }
}
