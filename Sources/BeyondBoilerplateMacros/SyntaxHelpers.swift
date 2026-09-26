import SwiftSyntax
import SwiftSyntaxBuilder

/// Helpers compartidos para recorrer propiedades almacenadas y construir listas de parámetros.
///
/// ¿Por qué un módulo helper? Las implementaciones de macros que tocan listas de propiedades
/// (AutoInit, MakeBuilder, Endpoint, Analytics, Equatable) comparten las mismas
/// preguntas de SwiftSyntax: "¿está stored?", "¿cuál es su tipo?", "¿es optional?".
struct StoredProperty {
    let name: TokenSyntax
    let type: TypeSyntax
    let isOptional: Bool
    let binding: PatternBindingSyntax

    /// Recoge bindings `let`/`var` stored, omitiendo propiedades computed y members static.
    static func collect(from declaration: some DeclGroupSyntax) -> [StoredProperty] {
        var results: [StoredProperty] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            // Omite members static / class — el init memberwise y los builders cuidan el estado de instancia.
            if varDecl.modifiers.contains(where: {
                $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
            }) {
                continue
            }
            // Omite propiedades que ya tienen accessors (computed / solo observadas).
            for binding in varDecl.bindings {
                if binding.accessorBlock != nil { continue }
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                guard let type = binding.typeAnnotation?.type else { continue }
                let optional = type.isOptionalType
                results.append(
                    StoredProperty(
                        name: pattern.identifier,
                        type: type,
                        isOptional: optional,
                        binding: binding
                    )
                )
            }
        }
        return results
    }
}

extension TypeSyntax {
    var isOptionalType: Bool {
        if self.is(OptionalTypeSyntax.self) { return true }
        if let identifier = self.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "Optional"
        }
        return false
    }

    /// Expresión default best-effort para propiedades del peer Builder.
    var builderDefaultExpression: ExprSyntax {
        if isOptionalType {
            return ExprSyntax(NilLiteralExprSyntax())
        }
        if let id = self.as(IdentifierTypeSyntax.self) {
            switch id.name.text {
            case "String":
                return ExprSyntax(StringLiteralExprSyntax(content: ""))
            case "Int", "Int8", "Int16", "Int32", "Int64",
                 "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
                return ExprSyntax(IntegerLiteralExprSyntax(0))
            case "Double", "Float", "CGFloat":
                return ExprSyntax(FloatLiteralExprSyntax(0))
            case "Bool":
                return ExprSyntax(BooleanLiteralExprSyntax(false))
            default:
                break
            }
        }
        // Fallback mantiene el Builder compilando para tipos custom que exponen `.init()`.
        return ExprSyntax(MemberAccessExprSyntax(name: .identifier("init")))
    }
}

extension AttributeSyntax {
    /// Lee una expresión de argumento etiquetado por texto de label (`method`, `path`, `min`, …).
    func argument(labeled label: String) -> ExprSyntax? {
        guard case let .argumentList(arguments) = arguments else { return nil }
        return arguments.first(where: { $0.label?.text == label })?.expression
    }

    func stringLiteralArgument(labeled label: String) -> String? {
        guard let expr = argument(labeled: label) else { return nil }
        guard let string = expr.as(StringLiteralExprSyntax.self),
              string.segments.count == 1,
              let segment = string.segments.first?.as(StringSegmentSyntax.self)
        else {
            return nil
        }
        return segment.content.text
    }

    func integerLiteralArgument(labeled label: String) -> Int? {
        guard let expr = argument(labeled: label) else { return nil }
        if let int = expr.as(IntegerLiteralExprSyntax.self) {
            return Int(int.literal.text)
        }
        // Soporte para menos unario: -1
        if let prefix = expr.as(PrefixOperatorExprSyntax.self),
           prefix.operator.text == "-",
           let int = prefix.expression.as(IntegerLiteralExprSyntax.self),
           let value = Int(int.literal.text)
        {
            return -value
        }
        return nil
    }
}

extension DeclGroupSyntax {
    var typeNameToken: TokenSyntax? {
        if let s = self.as(StructDeclSyntax.self) { return s.name }
        if let c = self.as(ClassDeclSyntax.self) { return c.name }
        if let e = self.as(EnumDeclSyntax.self) { return e.name }
        if let a = self.as(ActorDeclSyntax.self) { return a.name }
        return nil
    }

    var isStruct: Bool { self.is(StructDeclSyntax.self) }
    var isClass: Bool { self.is(ClassDeclSyntax.self) }
    var isEnum: Bool { self.is(EnumDeclSyntax.self) }
}
