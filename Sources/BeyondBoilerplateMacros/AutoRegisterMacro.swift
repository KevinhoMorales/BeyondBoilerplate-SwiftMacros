import SwiftSyntax
import SwiftSyntaxMacros

/// Conference core — MemberMacro for educational DI registration.
///
/// `@AutoRegister` adds `static func register(in:)` that inserts `Self` into
/// the small `DependencyContainer`. Teaching goal: show the *temptation* of magical
/// registration — and force the README / DemoCLI to discuss when manual registration
/// is clearer for debugging and test overrides.
public struct AutoRegisterMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isStruct || declaration.isClass else {
            context.diagnose(.autoRegisterOnlyNominalTypes, on: node)
            return []
        }

        guard let typeName = declaration.typeNameToken?.text else {
            context.diagnose(.autoRegisterRequiresTypeName, on: node)
            return []
        }

        // We require a zero-argument initializer at the `register` call site.
        // Diagnosing missing inits at macro time is intentionally avoided: that needs
        // full type-checking info macros don't reliably have. Document the contract instead.
        let method: DeclSyntax =
            """
            public static func register(in container: DependencyContainer) {
                container.register(\(raw: typeName).self) {
                    \(raw: typeName)()
                }
            }
            """

        return [method]
    }
}
