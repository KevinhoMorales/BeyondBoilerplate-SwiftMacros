# Beyond Boilerplate: Production-Ready Swift Macros

Material for the **SwiftLeeds** talk (Kevin Morales): production-minded macros, an iOS app for live teaching, and a CLI to explore them offline.

---

## What is a Swift macro?

Imagine the compiler has a helper. You write a short annotation (`@Endpoint`, `@AutoInit`, `#stringify`…) and, **before type-checking**, that helper reads your code as a syntax tree, writes the Swift that was missing, and inserts it into the module. What comes out is ordinary code: it type-checks, debugs, and compiles as if you had typed it by hand.

It is not runtime reflection. It is not an external script like Sourcery. The macro lives inside the build: it can fail with clear **diagnostics**, and what it produces is ordinary Swift.

Useful intuition: if you copy the same *shape* again and again (a memberwise `init`, an endpoint envelope, an analytics event dictionary…), a macro can **write that structure** from what you already declared.

### Without macro vs with macro — two examples

Same endpoint, two ways to write it. On the left (or above), the noise you repeat for every API. On the right (or below), what you leave in source when you use the macro.

**Networking — by hand:**

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

**Networking — with `@Endpoint`:**

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

The expansion generates `endpointID`, `method`, `path`, `queryItems`, `requestDescription`, and `extension GetRestaurants: EndpointProtocol`. In Xcode: click `@Endpoint` → **Expand Macro** and you see it literally.

Another pattern that hurts less with macros: the memberwise `init`.

**Init — by hand:**

```swift
struct Restaurant {
    let id: String
    let name: String
    let rating: Double?

    init(id: String, name: String, rating: Double? = nil) {
        self.id = id
        self.name = name
        self.rating = rating
    }
}
```

**Init — with `@AutoInit`:**

```swift
@AutoInit
struct Restaurant {
    let id: String
    let name: String
    let rating: Double?
}
```

Same shape, less copy-paste. The macro does not invent business logic: only **structural authorship**.

---

## When are they worth it?

When the pattern is **structural, repetitive**, and can be reasoned from the type or expression syntax:

| Situation | In this repo |
|-----------|--------------|
| Every endpoint repeats the same envelope | `@Endpoint(method:path:)` |
| Analytics events drift out of sync with the model | `@AnalyticsEvent` |
| You copy the same `init` on every struct | `@AutoInit` |
| You want a bad config to **fail at build time** | Empty path, macro on an `enum`, missing args → clear diagnostic |

If the problem is a business rule, an algorithm, or something that depends on runtime values, ordinary Swift usually wins: functions, protocols, and explicit composition. Macros remove noise; they should not hide architecture.

---

## Macro types (short map)

Two families:

| Family | How it looks | Idea |
|--------|--------------|------|
| **Freestanding** | `#stringify(a + b)` | Standalone call; usually produces an **expression** |
| **Attached** | `@AutoInit`, `@Endpoint(...)` | Attribute on a type or property; produces members, peers, accessors, or extensions |

Common roles for **attached** macros:

| Role | What it does | In this repo |
|------|--------------|--------------|
| **Member** | Adds members *inside* the type | `@AutoInit`, part of `@Endpoint` |
| **Peer** | Declares something *beside* the type | `@MakeBuilder` → `FooBuilder` next to `Foo` |
| **Accessor** | Attaches `get` / `set` / `didSet`… | `@Logged`, `@Clamped` |
| **Extension** | Emits `extension Type: Protocol` | `@AutoEquatable`, part of `@Endpoint` |

A single annotation can mix roles (`@Endpoint` = member + extension). Picking the right role is half the design battle.

Declarations: [`Macros.swift`](Sources/BeyondBoilerplateMacrosClient/Macros.swift).  
Implementations: [`Sources/BeyondBoilerplateMacros/`](Sources/BeyondBoilerplateMacros/).

---

## What’s in the repo

A single `Package.swift` at the root. The iOS app consumes it locally — there are not two copies of the macros.

| Piece | Role |
|-------|------|
| `BeyondBoilerplateMacros` | `.macro` plugin (SwiftSyntax) — the app does not import it |
| `BeyondBoilerplateMacrosClient` | Declarations via `#externalMacro` |
| `DemoSupport` | `HTTPMethod`, `EndpointProtocol`, minimal HTTP/analytics/DI (offline) |
| `DemoCLI` | Terminal scenario (`wow`, `levels`, `help`) |
| **BeyondBoilerplateDemo** | SwiftUI app — same macros, UI to walk through them |
| `BeyondBoilerplateMacrosTests` | Expansions and diagnostics (MacroTesting) |

### Macros to try

| Macro | Type(s) | Purpose |
|-------|---------|---------|
| `#stringify` | Expression | Value + source text (teaching) |
| `#URL` | Expression | Compile-time validated URL literal |
| `@Describable` | Extension | `CustomStringConvertible` from stored properties |
| `@AutoInit` | Member | Memberwise `init` |
| `@MakeBuilder` | Peer | Sibling `TypeBuilder` |
| `@Logged` | Accessor | Observe writes (`didSet`) |
| `@Clamped(min:max:)` | Accessor + Peer | Clamp a numeric |
| `@AutoEquatable` | Extension | `==` from stored properties |
| `@Endpoint(method:path:)` | Member + Extension | Networking envelope |
| `@AnalyticsEvent` | Member + Extension | Event name + parameters |
| `@AutoRegister` | Member | `register(in: DependencyContainer)` (educational DI) |

### Learning path: Basic / Intermediate / Advanced

The iOS demo is small and interactive (segmented control, four Swift files). UI text is English; comments are bilingual (`// ES:` / `// EN:`) in the app **and** in the macro implementations so reading source teaches how a macro is built.

| Level | On screen | Macros / ideas |
|-------|-----------|----------------|
| **Basic** | One sentence: macros write code at compile time; `#` vs `@`; pick `#stringify` expressions; run `#URL`; print `@Describable` Dish | `#stringify`, `#URL`, `@Describable` |
| **Intermediate** | One tiny Before / After / Expanded per role; clamp stepper (try 150 → stores 100); note on `@Observable` | Member `@AutoInit`, peer `@MakeBuilder`, accessor `@Clamped`, extension `@AutoEquatable` |
| **Advanced** | Real-world list (`@Observable`, `#Preview`, `@Model`, `@Test`/`#expect`, `@Reducer`); live `@Endpoint`; diagnostic cards; 4 benefits | `@Endpoint`, diagnostics, compile-time safety |

Stage flow: Basic → Intermediate → Advanced. Keep `Examples.swift` open for **Expand Macro**.

### How to open and run

**Requirements:** Swift 6.4+, recent Xcode, macOS 14+ / iOS 17+ (library). Macros since Swift 5.9+; this package uses **Swift 6** language mode.

**iOS app (recommended on stage):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Scheme **BeyondBoilerplateDemo** → iOS 17+ Simulator → Run.  
The target links the local package (`BeyondBoilerplateMacrosClient` + `DemoSupport`).

**Package / CLI:**

```bash
open Package.swift
swift build
swift test
swift run DemoCLI          # WOW path (default)
swift run DemoCLI levels   # LEVEL 1–9 walkthrough
swift run DemoCLI help
```

Everything is **offline** (in-memory stub). No third-party DI frameworks.

---

## Expand Macro in Xcode

1. Open `Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo/Examples.swift` (or `Sources/DemoCLI/main.swift`).
2. Click the attribute (`@Describable`, `@Endpoint`, `@AutoInit`, …) or a `#URL` / `#stringify` call.
3. **Editor → Expand Macro** (or right-click → **Expand Macro**).

On stage: leave the expansion sheet open while you scroll Before / After / Expanded code and tap the live demo buttons.

---

## Repo layout

```
BeyondBoilerplate-SwiftMacros/
├── Package.swift
├── README.md
├── Docs/                              ← speaker notes / slides
├── Apps/BeyondBoilerplateDemo/        ← iOS .xcodeproj (local SPM)
├── Sources/
│   ├── BeyondBoilerplateMacros/       ← implementations
│   ├── BeyondBoilerplateMacrosClient/ ← public declarations
│   ├── DemoSupport/                   ← offline stubs
│   └── DemoCLI/                       ← demo executable
└── Tests/BeyondBoilerplateMacrosTests/
```

Study / `swift test` / CLI → `Package.swift`. Expand Macro + Simulator → the `.xcodeproj`. Both share the same package.

---

## License / credit

Educational material for the SwiftLeeds talk — **Kevin Morales**.  
You may fork it for workshops; keep attribution if you reuse the material in abstracts.

**Stage cold start:** `open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj` → Run → **Basic** (run `#stringify` / `#URL` / Dish) → **Intermediate** (clamp 150→100) → **Advanced** (live `@Endpoint`) → Expand Macro in `Examples.swift`.
