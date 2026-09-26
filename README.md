# Beyond Boilerplate: Building Production-Ready Swift Macros

Educational Swift package and live-demo laboratory for Kevin Morales’s talk:

> **Beyond Boilerplate: Building Production-Ready Swift Macros**

Designed for DevFest (Spanish delivery later) and reuse at London / SwiftLeeds.  
**All code, comments, README text, and CLI output in this repository are in English.**

This is **not** a toy `#stringify`-only sample. It is a progressive laboratory you can open in Xcode, study line-by-line, run offline on stage, and use to teach *when* macros belong in production — and when they do not.

---

## Requirements

| Tool | Version verified on this package |
|------|----------------------------------|
| **Swift** | **6.4** (`swiftlang-6.4.0.34.1`) |
| **Xcode** | **27.0** (Build 27A266a) |
| **swift-syntax** | **604.0.0** (aligned with Swift 6.4) |
| **MacroTesting** | **0.7.x** (Point-Free) |
| **Platforms** | macOS 14+, iOS 17+ (library) |

> Macros require Swift 5.9+. This package targets **Swift 6 language mode** and current SwiftSyntax APIs (no deprecated expansion entry points).

### Open in Xcode — two entry points

**iOS SwiftUI demo (Simulator / device — preferred on stage):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Select scheme **BeyondBoilerplateDemo**, pick any iOS 17+ Simulator (e.g. iPhone 17), Run.  
The app target links the **local Swift package at the repo root** (`BeyondBoilerplateMacrosClient` + `DemoSupport`) — same macros as the CLI.

**Package / CLI laboratory:**

```bash
open Package.swift
```

Single root `Package.swift` — one cohesive package. The `.xcodeproj` is a thin iOS shell around it (not a second copy of the macros).

### Build, test, demo

```bash
swift build
swift test
swift run DemoCLI          # WOW conference path (default)
swift run DemoCLI levels   # progressive LEVEL 1–9 walkthrough
swift run DemoCLI help

# iOS app (from machine with Xcode + Simulator)
xcodebuild \
  -project Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj \
  -scheme BeyondBoilerplateDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Fully **offline**. Networking uses an in-memory stub. No third-party DI frameworks.

### Expand Macro (talk choreography)

| Where | What to expand |
|-------|----------------|
| `Apps/.../DemoModels.swift` | `@Endpoint`, `@AnalyticsEvent`, `@AutoInit`, `@MakeBuilder`, `@AutoRegister` |
| `Sources/DemoCLI/main.swift` | Same annotations on the CLI twin types |

In Xcode: click the attribute → **Editor → Expand Macro** (or right-click → Expand Macro).  
Tap through the iOS UI while the expansion sheet is open so the audience sees compile-time code and runtime behavior together.

---

## Package layout

```
BeyondBoilerplate-SwiftMacros/
├── Package.swift
├── README.md                          ← you are here (primary teaching)
├── Docs/                              ← optional deep-dives / talk notes
├── Apps/BeyondBoilerplateDemo/        ← iOS SwiftUI .xcodeproj (local SPM)
│   ├── BeyondBoilerplateDemo.xcodeproj
│   ├── project.yml                    ← XcodeGen spec (optional regenerate)
│   └── BeyondBoilerplateDemo/         ← SwiftUI sources + DemoModels.swift
├── Sources/
│   ├── BeyondBoilerplateMacros/       ← macro *implementations* (SwiftSyntax)
│   ├── BeyondBoilerplateMacrosClient/ ← public @freestanding / @attached decls
│   ├── DemoSupport/                   ← HTTPMethod, EndpointProtocol, DI, stubs
│   └── DemoCLI/                       ← stage executable (levels + WOW)
└── Tests/BeyondBoilerplateMacrosTests/← MacroTesting expansions + diagnostics
```

| Target / app | Role |
|--------------|------|
| `BeyondBoilerplateMacros` | `.macro` plugin — never imported by app code |
| `BeyondBoilerplateMacrosClient` | Declarations via `#externalMacro(module:type:)` |
| `DemoSupport` | Tiny protocols + offline HTTP/analytics/DI |
| `DemoCLI` | Progressive + WOW demo (terminal) |
| **BeyondBoilerplateDemo** | iOS SwiftUI app — same macros, tap-through UI |
| `BeyondBoilerplateMacrosTests` | Expansion & diagnostic tests |

**SPM vs app:** study / `swift test` / `DemoCLI` → open `Package.swift`. Live Expand Macro + Simulator → open the `.xcodeproj`. Do not gut either path; they share one package.
---

## 1. What is a Swift Macro?

### Simple answer

A Swift macro is a **compile-time program** that reads Swift source (as a syntax tree) and **writes more Swift source** back into your module before type-checking finishes. You author a small attribute or `#name(...)` call; the compiler expands it into real code that then compiles like anything else you typed by hand.

### Technical answer

Macros are a form of **metaprogramming**:

| Concept | Meaning |
|---------|---------|
| **Expansion** | The macro plugin runs in a separate process and returns new syntax nodes |
| **Generated code** | Ordinary Swift that must type-check; there is no hidden runtime interpreter |
| **Compile-time vs runtime** | Decisions and code emission happen at compile time; the resulting binary only contains the expanded code |
| **vs reflection** | Reflection inspects types at *runtime* and cannot invent new methods/conformances in your module |
| **vs traditional codegen** | Sourcery / Gyb / scripts run *outside* the compiler; macros participate in the build graph, diagnostics, and incremental compilation |

### ASCII pipeline

```
  Source.swift
       │
       ▼
  ┌─────────┐
  │  Parser │  tokens → SwiftSyntax tree (Trivia preserved)
  └────┬────┘
       │
       ▼
  ┌──────────────────┐
  │ Macro expansion  │  your plugin: inspect nodes, emit DeclSyntax / ExprSyntax
  │  (SwiftSyntax)   │  diagnose errors with source locations
  └────┬─────────────┘
       │
       ▼
  ┌──────────────────┐
  │ Generated Swift  │  spliced into the module (Expand Macro shows this)
  └────┬─────────────┘
       │
       ▼
  ┌──────────┐     ┌────────┐
  │ Typecheck│ ──▶  │ Binary │
  │ + SIL/IR │     └────────┘
  └──────────┘
```

**Key teaching line:** macros do not “run your business logic early.” They **author structural Swift** so humans stop copy-pasting it.

---

## 2. SwiftSyntax (deep but readable)

SwiftSyntax is a **source-accurate tree** of Swift code: every declaration, expression, attribute, and piece of trivia (spaces, comments, newlines) can be represented.

| Term | Intuition |
|------|-----------|
| **Tree / node** | Nested structure: `SourceFile` → `StructDecl` → `MemberBlock` → … |
| **Token** | Leaf: identifiers, keywords, punctuation (`struct`, `User`, `{`) |
| **Decl** | Declaration nodes (`StructDeclSyntax`, `FunctionDeclSyntax`, …) |
| **Expr** | Expression nodes (`InfixExprSyntax`, `StringLiteralExprSyntax`, …) |
| **Attribute** | `@Endpoint(method:path:)` as `AttributeSyntax` + argument list |
| **Trivia** | Leading/trailing whitespace & comments attached to tokens |
| **Source location** | Where diagnostics should underline |

### Conceptual tree for `struct User { let name: String }`

```
StructDeclSyntax
├── struct keyword
├── name: "User"
└── MemberBlock
    └── VariableDeclSyntax
        ├── let keyword
        └── PatternBinding
            ├── IdentifierPattern "name"
            └── TypeAnnotation → IdentifierType "String"
```

A **MemberMacro** walks `declaration.memberBlock.members`, filters stored properties, and emits a new `init` `DeclSyntax`.  
A **PeerMacro** returns declarations that appear *beside* the annotated type.  
An **ExtensionMacro** returns `extension Type: Protocol { … }`.

This package uses **SwiftSyntaxBuilder** string interpolation (`DeclSyntax`, `ExtensionDeclSyntax`) where readability for the stage wins, and typed builders/helpers in `SyntaxHelpers.swift` for shared property collection.

---

## 3. Types of macros (with in-repo examples)

| Kind | Role | Example in this repo |
|------|------|----------------------|
| **Freestanding / Expression** | `#name(args)` → expression | [`StringifyMacro.swift`](Sources/BeyondBoilerplateMacros/StringifyMacro.swift) |
| **MemberMacro** | Add members inside a type | [`AutoInitMacro.swift`](Sources/BeyondBoilerplateMacros/AutoInitMacro.swift) |
| **PeerMacro** | Emit sibling declarations | [`MakeBuilderMacro.swift`](Sources/BeyondBoilerplateMacros/MakeBuilderMacro.swift) |
| **AccessorMacro** | Attach get/set/didSet/… | [`LoggedMacro.swift`](Sources/BeyondBoilerplateMacros/LoggedMacro.swift), [`ClampedMacro.swift`](Sources/BeyondBoilerplateMacros/ClampedMacro.swift) |
| **ExtensionMacro** | Add extensions / conformances | [`AutoEquatableMacro.swift`](Sources/BeyondBoilerplateMacros/AutoEquatableMacro.swift) |
| **Multi-role** | One attribute, several protocols | `@Clamped`, `@Endpoint`, `@AnalyticsEvent` |

Public declarations live in [`Macros.swift`](Sources/BeyondBoilerplateMacrosClient/Macros.swift).

---

## 4. Production demos — BEFORE / AFTER

### 4.1 Networking — `@Endpoint`

**BEFORE (manual boilerplate every time):**

```swift
struct GetRestaurants: EndpointProtocol {
    let city: String
    let limit: Int

    static let endpointID = "GetRestaurants"
    var method: HTTPMethod { .get }
    var path: String { "/restaurants" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "city", value: String(describing: city)),
            URLQueryItem(name: "limit", value: String(describing: limit)),
        ]
    }
    var requestDescription: String {
        "\(method.rawValue) \(path) [\(Self.endpointID)]"
    }
}
```

**AFTER (what you write):**

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

**AFTER (what Expand Macro / tests show — real expansion):**

```swift
struct GetRestaurants {
    let city: String
    let limit: Int

    public static let endpointID: String = "GetRestaurants"

    public var method: HTTPMethod {
        .get
    }

    public var path: String {
        "/restaurants"
    }

    public var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "city", value: String(describing: city)),
            URLQueryItem(name: "limit", value: String(describing: limit))
        ]
    }

    public var requestDescription: String {
        "\(method.rawValue) \(path) [\(Self.endpointID)]"
    }
}

extension GetRestaurants: EndpointProtocol {
}
```

**Why each piece exists**

| Generated piece | Why |
|-----------------|-----|
| `endpointID` | Stable key for stubs / logging without stringly path coupling |
| `method` / `path` | From macro arguments — validated as literals where helpful |
| `queryItems` | Derived from stored properties — structural mapping macros excel at |
| `EndpointProtocol` extension | Lets `InMemoryHTTPClient` stay generic |

Invalid configs emit **helpful diagnostics** (empty path, enum attachment, missing args) — see tests.

### 4.2 Analytics — `@AnalyticsEvent`

**BEFORE:** hand-written `eventName` + `[String: String]` dictionaries that drift from property names.

**AFTER:**

```swift
@AnalyticsEvent
struct RestaurantOpened {
    let restaurantID: String
    let source: String
}
```

Expands to `eventName` (`restaurant_opened`), `parameters`, `payloadDescription`, and `AnalyticsEventProtocol` — no vendor SDK.

### 4.3 Educational DI — `@AutoRegister`

```swift
@AutoRegister
struct MenuRepository {
    init() {}
}
```

Expands to:

```swift
public static func register(in container: DependencyContainer) {
    container.register(MenuRepository.self) {
        MenuRepository()
    }
}
```

#### Magic, maintainability, debugging

| Question | Guidance |
|----------|----------|
| Is auto-registration “free”? | No — call sites still need `Type.register(in:)` (or a scanner you maintain) |
| When is it OK? | Homogeneous services with a clear composition root |
| When write registrations manually? | Test overrides, multi-binding, conditional environments, debugging “who created this?” |
| Failure mode | Missing `init()` → runtime `fatalError` in this tiny container — macros cannot always see full type-checker info |

**Talking point:** macros should reduce *noise*, not hide *architecture*.

---

## 5. SwiftSyntaxBuilder notes

Used heavily for readable expansions:

```swift
let initializer: DeclSyntax = """
\(raw: access)init(\(raw: parameterList)) {
    \(raw: assignments)
}
"""
```

| Technique | When |
|-----------|------|
| `DeclSyntax` / `ExtensionDeclSyntax` interpolation | Fast, stage-readable expansions |
| `\(literal:)` | Safe string/int literals in generated code |
| `\(raw:)` | Splice already-built Swift fragments |
| Typed helpers (`StoredProperty.collect`) | Shared analysis without copy-paste |

Prefer clarity over clever AST surgery for conference macros.

---

## 6. Production considerations

1. **Type safety** — expanded code is real Swift; the type checker is your backstop.  
2. **Compile-time guarantees** — bad attributes should **fail the build** with diagnostics, not surprise you at runtime.  
3. **Diagnostics example** — `@AutoInit` on an enum:

   > `@AutoInit can only be attached to a struct. Enums and classes already have richer initialization rules—write those inits by hand.`

4. **Generated code quality** — Expand Macro in review; keep expansions small enough to explain live.  
5. **Build times** — each macro plugin process + expansion costs; measure before decorating every type in an app.  
6. **API design** — avoid “magic global scanners”; prefer explicit arguments (`method:`, `path:`).  
7. **Debugging** — Xcode: right-click → **Expand Macro**. CLI: `swift run DemoCLI wow` prints the conceptual expansion.

---

## 7. When NOT to use macros

| Temptation | Prefer instead |
|------------|----------------|
| Business rules / pricing / auth policy | Ordinary functions & types |
| Complex algorithms | Testable pure Swift |
| Dynamic behavior depending on runtime values | Runtime code / protocols |
| Saving three lines once | Just write the three lines |
| Hiding architecture behind “framework magic” | Explicit composition roots |
| Auto-`Codable` / auto-`Hashable` for every model | Manual or carefully scoped codegen — edge cases abound |

**Decision guidance:** use a macro when the transformation is **structural, repetitive, locally reasoned from syntax**, and you can ship **excellent diagnostics**.

---

## 8. Comparison table

| Problem | Function | Protocol / Generic | Macro | External codegen | Reflection |
|---------|----------|--------------------|-------|------------------|------------|
| Reuse an algorithm | ✅ | ✅ | ❌ overkill | ❌ | ❌ |
| Polymorphic behavior | ✅ | ✅ best | ❌ | ❌ | fragile |
| Emit members/conformances from shape of a type | ❌ | limited | ✅ | ✅ | ❌ |
| Capture source text of an expression | ❌ | ❌ | ✅ `#stringify` | ❌ | ❌ |
| Cross-language / multi-file templates | ❌ | ❌ | limited | ✅ | ❌ |
| Inspect unknown types at runtime | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 9. Progressive learning — LEVEL 1–9

| Level | Focus | Run |
|------|-------|-----|
| **1** | Freestanding `#stringify` — AST → `(value, "source")` | `DemoCLI levels` |
| **2** | `@AutoInit` MemberMacro — optionals default to `nil` | |
| **3** | `@MakeBuilder` PeerMacro — sibling Builder, access-level aware | |
| **4** | `@Logged` / `@Clamped` AccessorMacro (+ Peer storage) | |
| **5** | `@AutoEquatable` ExtensionMacro — **limitations** called out | |
| **6** | `@Endpoint` production networking shape | |
| **7** | `@AnalyticsEvent` typed → dictionary payload | |
| **8** | `@AutoRegister` educational DI + debate | |
| **9** | When **not** to use macros — decision checklist | |

Implementation map: [`Sources/BeyondBoilerplateMacros/`](Sources/BeyondBoilerplateMacros/).

---

## 10. Conference demo script (30–45 min)

| Segment | Time | Show | Run | Explain | Audience takeaway |
|---------|------|------|-----|---------|-------------------|
| **Problem** | 3 min | Manual endpoint boilerplate slide / README BEFORE | — | Review noise, typos, drift | Boilerplate is a product risk |
| **Boilerplate tax** | 3 min | Multiply by N endpoints | — | Humans copy-paste badly | Structure wants automation |
| **First macro** | 4 min | `#stringify` in DemoCLI / Xcode | `levels` L1 | ExpressionMacro + source text | Macros see syntax |
| **SwiftSyntax** | 5 min | Tree diagram in README | — | Nodes, decls, attributes | You are editing a tree |
| **Expansion** | 4 min | Expand Macro on `@AutoInit` | L2–L3 | Member vs Peer | Role choice matters |
| **Production macro** | 8 min | `@Endpoint` BEFORE→AFTER | `wow` | Arguments, query mapping, protocol | Small expansions win |
| **Diagnostics** | 4 min | Break `@Endpoint` path / `@AutoInit` on enum | tests or Xcode | Actionable messages | Trust = diagnostics |
| **Testing** | 4 min | `BeyondBoilerplateMacrosTests` | `swift test` | MacroTesting snapshots | Treat expansions as API |
| **Limitations** | 4 min | `@AutoEquatable` / `@AutoRegister` debate | L5, L8 | Magic vs maintainability | Know the escape hatches |
| **Lessons** | 3 min | LEVEL 9 checklist | L9 | Decision table | Macros are a sharp tool |

**WOW moment (segment core):**  
1. Show verbose manual endpoint.  
2. Replace with `@Endpoint`.  
3. Expand Macro / `swift run DemoCLI wow` — “this is what the compiler generated.”  
4. Hit `InMemoryHTTPClient` — applause, still offline.

---

## 11. WOW moment (offline)

```bash
swift run DemoCLI wow
```

Prints: manual boilerplate → `@Endpoint` → generated-equivalent members → offline JSON response for Leeds / SwiftLeeds vibes.

In Xcode: open `Apps/BeyondBoilerplateDemo/.../DemoModels.swift` (or `Sources/DemoCLI/main.swift`), right-click `@Endpoint` → **Expand Macro**.  
On stage, prefer the iOS app so the audience sees the expansion *and* a restaurant list from `InMemoryHTTPClient`.

---

## 12. Testing macros

Uses [MacroTesting](https://github.com/pointfreeco/swift-macro-testing) with Swift Testing:

```swift
assertMacro {
    """
    #stringify(a + b)
    """
} expansion: {
    """
    (a + b, "a + b")
    """
}
```

Diagnostic tests assert the **underlined message**, not a generic “macro failed.”

```bash
swift test
# 18 tests — expansions + diagnostics
```

---

## Macros quick index

| Macro | Kind(s) | Intent |
|-------|---------|--------|
| `#stringify` | Expression | Teaching — value + source text |
| `@AutoInit` | Member | Memberwise `init` (optionals → `nil`) |
| `@MakeBuilder` | Peer | `TypeBuilder` sibling |
| `@Logged` | Accessor (`didSet`) | Observe writes |
| `@Clamped(min:max:)` | Accessor + Peer | Bound numeric storage |
| `@AutoEquatable` | Extension (+ Member role) | Stored-property `==` |
| `@Endpoint(method:path:)` | Member + Extension | Networking envelope |
| `@AnalyticsEvent` | Member + Extension | Event name + parameters |
| `@AutoRegister` | Member | `register(in: DependencyContainer)` |

---

## License / talk credit

Educational material for **Kevin Morales** — DevFest / London / SwiftLeeds.  
Feel free to fork for workshops; keep attribution in talk abstracts when you reuse the laboratory.

---

**Start here on stage:** `open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj` → Run on Simulator → Expand Macro on `@Endpoint` in `DemoModels.swift` → (optional) `swift run DemoCLI wow` for the terminal twin.
