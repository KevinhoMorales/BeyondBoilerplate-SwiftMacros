// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

/// Beyond Boilerplate: Building Production-Ready Swift Macros
///
/// Single-root package layout for conference demos and progressive study:
/// - BeyondBoilerplateMacros        → macro implementations (SwiftSyntax)
/// - BeyondBoilerplateMacrosClient  → public `@freestanding` / `@attached` declarations
/// - DemoSupport                    → offline networking / analytics / DI stubs
/// - DemoCLI                        → stage-ready progressive + WOW demo executable
let package = Package(
    name: "BeyondBoilerplateSwiftMacros",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BeyondBoilerplateMacrosClient",
            targets: ["BeyondBoilerplateMacrosClient"]
        ),
        .library(
            name: "DemoSupport",
            targets: ["DemoSupport"]
        ),
        .executable(
            name: "DemoCLI",
            targets: ["DemoCLI"]
        ),
    ],
    dependencies: [
        // 604.x aligns with Swift 6.4 / Xcode 27. MacroTesting accepts < 605.0.0.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "604.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    ],
    targets: [
        .macro(
            name: "BeyondBoilerplateMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "BeyondBoilerplateMacrosClient",
            dependencies: ["BeyondBoilerplateMacros", "DemoSupport"]
        ),
        .target(
            name: "DemoSupport",
            dependencies: []
        ),
        .executableTarget(
            name: "DemoCLI",
            dependencies: [
                "BeyondBoilerplateMacrosClient",
                "DemoSupport",
            ]
        ),
        .testTarget(
            name: "BeyondBoilerplateMacrosTests",
            dependencies: [
                "BeyondBoilerplateMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
