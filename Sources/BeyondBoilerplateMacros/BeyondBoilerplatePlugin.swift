import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Punto de entrada del compiler plugin — lista cada macro que provee este paquete.
///
/// Los targets SPM `.macro` deben exponer un CompilerPlugin `@main`. Xcode/SPM hospedan este
/// proceso por separado durante la compilación; el código cliente nunca importa este módulo directamente.
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
