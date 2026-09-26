import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Shared diagnostic catalog for every educational macro in this package.
///
/// Production tip: prefer *actionable* messages over generic "macro failed".
/// Speakers should expand a failing example on stage to show how macros earn trust.
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
            return "#stringify requires exactly one expression argument, e.g. #stringify(a + b)."
        case .autoInitOnlyStructs:
            return "@AutoInit can only be attached to a struct. Enums and classes already have richer initialization rules—write those inits by hand."
        case .autoInitNoStoredProperties:
            return "@AutoInit found no stored properties. Add `let`/`var` stored members, or remove the attribute."
        case .makeBuilderOnlyStructs:
            return "@MakeBuilder can only be attached to a struct so the generated peer Builder can call a memberwise initializer."
        case .makeBuilderNoStoredProperties:
            return "@MakeBuilder needs at least one stored property to generate a useful Builder peer type."
        case .loggedOnlyVariables:
            return "@Logged can only be attached to a variable declaration (stored property)."
        case .clampedOnlyVariables:
            return "@Clamped can only be attached to a variable declaration (stored property)."
        case .clampedMissingBounds:
            return "@Clamped requires both min: and max: integer arguments, e.g. @Clamped(min: 0, max: 10)."
        case .autoEquatableOnlyStructs:
            return "@AutoEquatable currently supports structs only. For classes, implement Equatable manually (identity vs value semantics)."
        case .autoEquatableNoStoredProperties:
            return "@AutoEquatable found no stored properties to compare."
        case .endpointOnlyStructs:
            return "@Endpoint can only be attached to a struct that models one HTTP request."
        case .endpointMissingArguments:
            return "@Endpoint requires method: and path: arguments, e.g. @Endpoint(method: .get, path: \"/restaurants\")."
        case .endpointEmptyPath:
            return "@Endpoint path must be a non-empty string literal starting with '/', e.g. \"/restaurants\"."
        case .endpointNoProperties:
            return "@Endpoint types should declare at least one property (query/body input). Use a marker property if the route truly has none."
        case .analyticsOnlyStructs:
            return "@AnalyticsEvent can only be attached to a struct that models a single analytics event payload."
        case .analyticsNoProperties:
            return "@AnalyticsEvent found no stored properties to encode as event parameters."
        case .autoRegisterOnlyNominalTypes:
            return "@AutoRegister can only be attached to a struct or class type."
        case .autoRegisterRequiresTypeName:
            return "@AutoRegister could not determine the type name to register in DependencyContainer."
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
