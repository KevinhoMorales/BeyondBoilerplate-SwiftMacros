import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Compiler plugin entry point — lists every macro this package provides.
///
/// SPM `.macro` targets must expose an `@main` CompilerPlugin. Xcode/SPM host this
/// process separately during compilation; client code never imports this module directly.
@main
struct BeyondBoilerplatePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        AutoInitMacro.self,
        MakeBuilderMacro.self,
        LoggedMacro.self,
        ClampedMacro.self,
        AutoEquatableMacro.self,
        EndpointMacro.self,
        AnalyticsEventMacro.self,
        AutoRegisterMacro.self,
    ]
}
