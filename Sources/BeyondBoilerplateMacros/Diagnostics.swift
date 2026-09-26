import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Catálogo compartido de diagnósticos para cada macro educativa de este paquete.
///
/// Tip de producción: prefiere mensajes *accionables* sobre un genérico "macro failed".
/// En el escenario, expande un ejemplo que falle para mostrar cómo los macros ganan confianza.
enum BeyondBoilerplateDiagnostic: String, DiagnosticMessage {
    case stringifyMissingArgument
    case autoInitOnlyStructs
    case autoInitNoStoredProperties
    case makeBuilderOnlyStructs
    case makeBuilderNoStoredProperties
    case loggedOnlyVariables
    case clampedOnlyVariables
    case clampedMissingBounds
    case autoEquatableOnlyStructs
    case autoEquatableNoStoredProperties
    case endpointOnlyStructs
    case endpointMissingArguments
    case endpointEmptyPath
    case endpointNoProperties
    case analyticsOnlyStructs
    case analyticsNoProperties
    case autoRegisterOnlyNominalTypes
    case autoRegisterRequiresTypeName

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .stringifyMissingArgument:
            return "#stringify requiere exactamente un argumento de expresión, p. ej. #stringify(a + b)."
        case .autoInitOnlyStructs:
            return "@AutoInit solo se puede adjuntar a un struct. Los enums y las classes ya tienen reglas de inicialización más ricas—escribe esos inits a mano."
        case .autoInitNoStoredProperties:
            return "@AutoInit no encontró propiedades almacenadas. Añade members almacenados `let`/`var`, o quita el atributo."
        case .makeBuilderOnlyStructs:
            return "@MakeBuilder solo se puede adjuntar a un struct para que el peer Builder generado pueda llamar a un inicializador memberwise."
        case .makeBuilderNoStoredProperties:
            return "@MakeBuilder necesita al menos una propiedad almacenada para generar un peer Builder útil."
        case .loggedOnlyVariables:
            return "@Logged solo se puede adjuntar a una declaración de variable (propiedad almacenada)."
        case .clampedOnlyVariables:
            return "@Clamped solo se puede adjuntar a una declaración de variable (propiedad almacenada)."
        case .clampedMissingBounds:
            return "@Clamped requiere ambos argumentos enteros min: y max:, p. ej. @Clamped(min: 0, max: 10)."
        case .autoEquatableOnlyStructs:
            return "@AutoEquatable actualmente solo soporta structs. Para classes, implementa Equatable a mano (semántica de identidad vs valor)."
        case .autoEquatableNoStoredProperties:
            return "@AutoEquatable no encontró propiedades almacenadas para comparar."
        case .endpointOnlyStructs:
            return "@Endpoint solo se puede adjuntar a un struct que modele una petición HTTP."
        case .endpointMissingArguments:
            return "@Endpoint requiere argumentos method: y path:, p. ej. @Endpoint(method: .get, path: \"/restaurants\")."
        case .endpointEmptyPath:
            return "@Endpoint path debe ser un string literal no vacío que empiece con '/', p. ej. \"/restaurants\"."
        case .endpointNoProperties:
            return "Los tipos @Endpoint deben declarar al menos una propiedad (input de query/body). Usa una propiedad marcador si la ruta realmente no tiene ninguna."
        case .analyticsOnlyStructs:
            return "@AnalyticsEvent solo se puede adjuntar a un struct que modele el payload de un solo evento de analytics."
        case .analyticsNoProperties:
            return "@AnalyticsEvent no encontró propiedades almacenadas para codificar como parameters del evento."
        case .autoRegisterOnlyNominalTypes:
            return "@AutoRegister solo se puede adjuntar a un tipo struct o class."
        case .autoRegisterRequiresTypeName:
            return "@AutoRegister no pudo determinar el nombre del tipo a registrar en DependencyContainer."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "BeyondBoilerplateMacros", id: rawValue)
    }
}

extension MacroExpansionContext {
    func diagnose(_ diagnostic: BeyondBoilerplateDiagnostic, on node: some SyntaxProtocol) {
        self.diagnose(Diagnostic(node: Syntax(node), message: diagnostic))
    }
}
