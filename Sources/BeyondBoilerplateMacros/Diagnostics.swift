import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Shared diagnostic catalog for every teaching macro in this package.
///
/// Production tip: prefer *actionable* messages over a generic "macro failed".
/// On stage, expand a failing example to show how macros earn trust.
enum BeyondBoilerplateDiagnostic: DiagnosticMessage {
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
    case urlMissingArgument
    case urlRequiresStringLiteral
    case urlInvalidLiteral(String)
    case describableOnlyStructs
    case describableNoStoredProperties

    var severity: DiagnosticSeverity { .error }

    var diagnosticID: MessageID {
        MessageID(domain: "BeyondBoilerplateMacros", id: id)
    }

    private var id: String {
        switch self {
        case .stringifyMissingArgument: return "stringifyMissingArgument"
        case .autoInitOnlyStructs: return "autoInitOnlyStructs"
        case .autoInitNoStoredProperties: return "autoInitNoStoredProperties"
        case .makeBuilderOnlyStructs: return "makeBuilderOnlyStructs"
        case .makeBuilderNoStoredProperties: return "makeBuilderNoStoredProperties"
        case .loggedOnlyVariables: return "loggedOnlyVariables"
        case .clampedOnlyVariables: return "clampedOnlyVariables"
        case .clampedMissingBounds: return "clampedMissingBounds"
        case .autoEquatableOnlyStructs: return "autoEquatableOnlyStructs"
        case .autoEquatableNoStoredProperties: return "autoEquatableNoStoredProperties"
        case .endpointOnlyStructs: return "endpointOnlyStructs"
        case .endpointMissingArguments: return "endpointMissingArguments"
        case .endpointEmptyPath: return "endpointEmptyPath"
        case .endpointNoProperties: return "endpointNoProperties"
        case .analyticsOnlyStructs: return "analyticsOnlyStructs"
        case .analyticsNoProperties: return "analyticsNoProperties"
        case .autoRegisterOnlyNominalTypes: return "autoRegisterOnlyNominalTypes"
        case .autoRegisterRequiresTypeName: return "autoRegisterRequiresTypeName"
        case .urlMissingArgument: return "urlMissingArgument"
        case .urlRequiresStringLiteral: return "urlRequiresStringLiteral"
        case .urlInvalidLiteral: return "urlInvalidLiteral"
        case .describableOnlyStructs: return "describableOnlyStructs"
        case .describableNoStoredProperties: return "describableNoStoredProperties"
        }
    }

    var message: String {
        switch self {
        case .stringifyMissingArgument:
            return "#stringify requires exactly one expression argument, e.g. #stringify(a + b)."
        case .autoInitOnlyStructs:
            return "@AutoInit can only be attached to a struct. Enums and classes already have richer initialization rules—write those inits by hand."
        case .autoInitNoStoredProperties:
            return "@AutoInit found no stored properties. Add stored `let`/`var` members, or remove the attribute."
        case .makeBuilderOnlyStructs:
            return "@MakeBuilder can only be attached to a struct so the generated Builder peer can call a memberwise initializer."
        case .makeBuilderNoStoredProperties:
            return "@MakeBuilder needs at least one stored property to generate a useful Builder peer."
        case .loggedOnlyVariables:
            return "@Logged can only be attached to a variable declaration (stored property)."
        case .clampedOnlyVariables:
            return "@Clamped can only be attached to a variable declaration (stored property)."
        case .clampedMissingBounds:
            return "@Clamped requires both integer arguments min: and max:, e.g. @Clamped(min: 0, max: 10)."
        case .autoEquatableOnlyStructs:
            return "@AutoEquatable currently only supports structs. For classes, implement Equatable by hand (identity vs value semantics)."
        case .autoEquatableNoStoredProperties:
            return "@AutoEquatable found no stored properties to compare."
        case .endpointOnlyStructs:
            return "@Endpoint can only be attached to a struct that models an HTTP request."
        case .endpointMissingArguments:
            return "@Endpoint requires method: and path: arguments, e.g. @Endpoint(method: .get, path: \"/restaurants\")."
        case .endpointEmptyPath:
            return "@Endpoint path must be a non-empty string literal starting with '/', e.g. \"/restaurants\"."
        case .endpointNoProperties:
            return "@Endpoint types must declare at least one property (query/body input). Use a marker property if the route truly has none."
        case .analyticsOnlyStructs:
            return "@AnalyticsEvent can only be attached to a struct that models a single analytics event payload."
        case .analyticsNoProperties:
            return "@AnalyticsEvent found no stored properties to encode as event parameters."
        case .autoRegisterOnlyNominalTypes:
            return "@AutoRegister can only be attached to a struct or class type."
        case .autoRegisterRequiresTypeName:
            return "@AutoRegister could not determine the type name to register in DependencyContainer."
        case .urlMissingArgument:
            return "#URL requires a string literal argument, e.g. #URL(\"https://example.com\")."
        case .urlRequiresStringLiteral:
            return "#URL only accepts a string literal (not a variable). Pass the URL text inline so it can be validated at compile time."
        case .urlInvalidLiteral(let value):
            return "#URL(\"\(value)\") is not a valid absolute URL. Include a scheme and host, e.g. #URL(\"https://swiftleeds.co.uk\")."
        case .describableOnlyStructs:
            return "@Describable can only be attached to a struct."
        case .describableNoStoredProperties:
            return "@Describable found no stored properties to include in description."
        }
    }
}

extension MacroExpansionContext {
    func diagnose(_ diagnostic: BeyondBoilerplateDiagnostic, on node: some SyntaxProtocol) {
        self.diagnose(Diagnostic(node: Syntax(node), message: diagnostic))
    }
}
