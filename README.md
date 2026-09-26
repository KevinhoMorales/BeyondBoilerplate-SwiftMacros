# Beyond Boilerplate: Building Production-Ready Swift Macros

Paquete educativo de Swift y laboratorio de demo en vivo para la charla de Kevin Morales:

> **Beyond Boilerplate: Building Production-Ready Swift Macros**

**Español para DevFest ahora; inglés para SwiftLeeds más adelante.**  
Este repositorio está en **español** para humanos (README, comentarios educativos, salida de CLI y textos de UI de iOS). La **sintaxis de Swift**, identificadores, nombres de macros, rutas, comandos de CLI y URLs permanecen en **inglés**.

Esto **no** es un sample de juguete solo con `#stringify`. Es un laboratorio progresivo que puedes abrir en Xcode, estudiar línea a línea, ejecutar offline en el escenario y usar para enseñar *cuándo* los macros pertenecen a producción — y cuándo no.

---

## Requirements

| Tool | Version verified on this package |
|------|----------------------------------|
| **Swift** | **6.4** (`swiftlang-6.4.0.34.1`) |
| **Xcode** | **27.0** (Build 27A266a) |
| **swift-syntax** | **604.0.0** (aligned with Swift 6.4) |
| **MacroTesting** | **0.7.x** (Point-Free) |
| **Platforms** | macOS 14+, iOS 17+ (library) |

> Los macros requieren Swift 5.9+. Este paquete apunta al **modo de lenguaje Swift 6** y a las APIs actuales de SwiftSyntax (sin puntos de entrada de expansión deprecados).

### Abrir en Xcode — dos puntos de entrada

**Demo iOS SwiftUI (Simulator / device — preferido en el escenario):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Selecciona el scheme **BeyondBoilerplateDemo**, elige cualquier Simulator iOS 17+ (p. ej. iPhone 17), Run.  
El target de la app enlaza el **paquete Swift local en la raíz del repo** (`BeyondBoilerplateMacrosClient` + `DemoSupport`) — los mismos macros que el CLI.

**Laboratorio Package / CLI:**

```bash
open Package.swift
```

Un solo `Package.swift` en la raíz — un paquete cohesivo. El `.xcodeproj` es una capa iOS delgada alrededor (no una segunda copia de los macros).

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

Totalmente **offline**. La red usa un stub en memoria. Sin frameworks de DI de terceros.

### Expand Macro (coreografía de la charla)

| Where | What to expand |
|-------|----------------|
| `Apps/.../DemoModels.swift` | `@Endpoint`, `@AnalyticsEvent`, `@AutoInit`, `@MakeBuilder`, `@AutoRegister` |
| `Sources/DemoCLI/main.swift` | Las mismas anotaciones en los tipos gemelos del CLI |

En Xcode: haz clic en el atributo → **Editor → Expand Macro** (o clic derecho → Expand Macro).  
Navega la UI de iOS mientras la hoja de expansión está abierta para que la audiencia vea el código en compile-time y el comportamiento en runtime juntos.

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
| `BeyondBoilerplateMacros` | Plugin `.macro` — nunca lo importa el código de la app |
| `BeyondBoilerplateMacrosClient` | Declaraciones vía `#externalMacro(module:type:)` |
| `DemoSupport` | Protocolos pequeños + HTTP/analytics/DI offline |
| `DemoCLI` | Demo progresiva + WOW (terminal) |
| **BeyondBoilerplateDemo** | App iOS SwiftUI — mismos macros, UI por taps |
| `BeyondBoilerplateMacrosTests` | Tests de expansión y diagnósticos |

**SPM vs app:** estudiar / `swift test` / `DemoCLI` → abre `Package.swift`. Expand Macro en vivo + Simulator → abre el `.xcodeproj`. No descartes ninguno de los dos caminos; comparten un solo paquete.
---

## 1. ¿Qué es un Swift Macro?

### Respuesta simple

Un macro de Swift es un **programa en compile-time** que lee código fuente Swift (como un árbol de sintaxis) y **escribe más código fuente Swift** de vuelta en tu módulo antes de que termine el type-checking. Tú escribes un atributo pequeño o una llamada `#name(...)`; el compilador lo expande a código real que luego compila como cualquier cosa que hubieras escrito a mano.

### Respuesta técnica

Los macros son una forma de **metaprogramación**:

| Concept | Meaning |
|---------|---------|
| **Expansion** | El plugin del macro corre en un proceso separado y devuelve nuevos nodos de sintaxis |
| **Generated code** | Swift ordinario que debe pasar el type-check; no hay un intérprete oculto en runtime |
| **Compile-time vs runtime** | Las decisiones y la emisión de código ocurren en compile-time; el binario resultante solo contiene el código expandido |
| **vs reflection** | La reflexión inspecciona tipos en *runtime* y no puede inventar métodos/conformances nuevos en tu módulo |
| **vs traditional codegen** | Sourcery / Gyb / scripts corren *fuera* del compilador; los macros participan en el grafo de build, diagnósticos y compilación incremental |

### Pipeline ASCII

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

**Línea clave de enseñanza:** los macros no “ejecutan tu lógica de negocio antes.” **Autoran Swift estructural** para que los humanos dejen de copiar y pegar.

---

## 2. SwiftSyntax (profundo pero legible)

SwiftSyntax es un **árbol fiel al código fuente** de Swift: cada declaración, expresión, atributo y pieza de trivia (espacios, comentarios, saltos de línea) se puede representar.

| Term | Intuition |
|------|-----------|
| **Tree / node** | Estructura anidada: `SourceFile` → `StructDecl` → `MemberBlock` → … |
| **Token** | Hoja: identificadores, keywords, puntuación (`struct`, `User`, `{`) |
| **Decl** | Nodos de declaración (`StructDeclSyntax`, `FunctionDeclSyntax`, …) |
| **Expr** | Nodos de expresión (`InfixExprSyntax`, `StringLiteralExprSyntax`, …) |
| **Attribute** | `@Endpoint(method:path:)` como `AttributeSyntax` + lista de argumentos |
| **Trivia** | Espacios y comentarios leading/trailing unidos a los tokens |
| **Source location** | Dónde los diagnósticos deben subrayar |

### Árbol conceptual para `struct User { let name: String }`

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

Un **MemberMacro** recorre `declaration.memberBlock.members`, filtra propiedades almacenadas y emite un nuevo `init` `DeclSyntax`.  
Un **PeerMacro** devuelve declaraciones que aparecen *junto a* el tipo anotado.  
Un **ExtensionMacro** devuelve `extension Type: Protocol { … }`.

Este paquete usa interpolación de strings de **SwiftSyntaxBuilder** (`DeclSyntax`, `ExtensionDeclSyntax`) donde gana la legibilidad en el escenario, y builders/helpers tipados en `SyntaxHelpers.swift` para la recolección compartida de propiedades.

---

## 3. Tipos de macros (con ejemplos en el repo)

| Kind | Role | Example in this repo |
|------|------|----------------------|
| **Freestanding / Expression** | `#name(args)` → expresión | [`StringifyMacro.swift`](Sources/BeyondBoilerplateMacros/StringifyMacro.swift) |
| **MemberMacro** | Añadir members dentro de un tipo | [`AutoInitMacro.swift`](Sources/BeyondBoilerplateMacros/AutoInitMacro.swift) |
| **PeerMacro** | Emitir declaraciones hermanas | [`MakeBuilderMacro.swift`](Sources/BeyondBoilerplateMacros/MakeBuilderMacro.swift) |
| **AccessorMacro** | Adjuntar get/set/didSet/… | [`LoggedMacro.swift`](Sources/BeyondBoilerplateMacros/LoggedMacro.swift), [`ClampedMacro.swift`](Sources/BeyondBoilerplateMacros/ClampedMacro.swift) |
| **ExtensionMacro** | Añadir extensions / conformances | [`AutoEquatableMacro.swift`](Sources/BeyondBoilerplateMacros/AutoEquatableMacro.swift) |
| **Multi-role** | Un atributo, varios protocolos | `@Clamped`, `@Endpoint`, `@AnalyticsEvent` |

Las declaraciones públicas viven en [`Macros.swift`](Sources/BeyondBoilerplateMacrosClient/Macros.swift).

---

## 4. Demos de producción — BEFORE / AFTER

### 4.1 Networking — `@Endpoint`

**BEFORE (boilerplate manual cada vez):**

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

**AFTER (lo que escribes):**

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

**AFTER (lo que muestran Expand Macro / tests — expansión real):**

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

**Por qué existe cada pieza**

| Generated piece | Why |
|-----------------|-----|
| `endpointID` | Clave estable para stubs / logging sin acoplar al path como string |
| `method` / `path` | Desde argumentos del macro — validados como literales cuando ayuda |
| `queryItems` | Derivados de propiedades almacenadas — los macros de mapeo estructural destacan aquí |
| Extensión `EndpointProtocol` | Permite que `InMemoryHTTPClient` se mantenga genérico |

Las configs inválidas emiten **diagnósticos útiles** (path vacío, adjunto a enum, args faltantes) — ver tests.

### 4.2 Analytics — `@AnalyticsEvent`

**BEFORE:** `eventName` + diccionarios `[String: String]` escritos a mano que se desalinean de los nombres de propiedades.

**AFTER:**

```swift
@AnalyticsEvent
struct RestaurantOpened {
    let restaurantID: String
    let source: String
}
```

Expande a `eventName` (`restaurant_opened`), `parameters`, `payloadDescription` y `AnalyticsEventProtocol` — sin SDK de vendor.

### 4.3 DI educativa — `@AutoRegister`

```swift
@AutoRegister
struct MenuRepository {
    init() {}
}
```

Expande a:

```swift
public static func register(in container: DependencyContainer) {
    container.register(MenuRepository.self) {
        MenuRepository()
    }
}
```

#### Magia, mantenibilidad, debugging

| Question | Guidance |
|----------|----------|
| ¿El auto-registro es “gratis”? | No — los call sites aún necesitan `Type.register(in:)` (o un scanner que mantengas) |
| ¿Cuándo está bien? | Servicios homogéneos con un composition root claro |
| ¿Cuándo escribir registros a mano? | Overrides de test, multi-binding, entornos condicionales, debugging de “¿quién creó esto?” |
| Modo de fallo | Falta `init()` → `fatalError` en runtime en este contenedor pequeño — los macros no siempre ven la info completa del type-checker |

**Punto de la charla:** los macros deben reducir *ruido*, no ocultar *arquitectura*.

---

## 5. Notas de SwiftSyntaxBuilder

Usado mucho para expansiones legibles:

```swift
let initializer: DeclSyntax = """
\(raw: access)init(\(raw: parameterList)) {
    \(raw: assignments)
}
"""
```

| Technique | When |
|-----------|------|
| Interpolación `DeclSyntax` / `ExtensionDeclSyntax` | Expansiones rápidas y legibles en el escenario |
| `\(literal:)` | Literales string/int seguros en el código generado |
| `\(raw:)` | Empalmar fragmentos de Swift ya construidos |
| Helpers tipados (`StoredProperty.collect`) | Análisis compartido sin copy-paste |

Prefiere claridad sobre cirugía AST ingeniosa para macros de conferencia.

---

## 6. Consideraciones de producción

1. **Type safety** — el código expandido es Swift real; el type checker es tu red de seguridad.  
2. **Garantías en compile-time** — atributos malos deben **fallar el build** con diagnósticos, no sorprenderte en runtime.  
3. **Ejemplo de diagnóstico** — `@AutoInit` en un enum:

   > `@AutoInit solo se puede adjuntar a un struct. Los enums y las classes ya tienen reglas de inicialización más ricas—escribe esos inits a mano.`

4. **Calidad del código generado** — Expand Macro en review; mantén las expansiones lo bastante pequeñas para explicarlas en vivo.  
5. **Tiempos de build** — cada proceso de plugin de macro + expansión tiene costo; mide antes de decorar cada tipo de una app.  
6. **Diseño de API** — evita “scanners globales mágicos”; prefiere argumentos explícitos (`method:`, `path:`).  
7. **Debugging** — Xcode: clic derecho → **Expand Macro**. CLI: `swift run DemoCLI wow` imprime la expansión conceptual.

---

## 7. Cuándo NO usar macros

| Temptation | Prefer instead |
|------------|----------------|
| Reglas de negocio / precios / política de auth | Funciones y tipos ordinarios |
| Algoritmos complejos | Swift puro testeable |
| Comportamiento dinámico que depende de valores en runtime | Código en runtime / protocolos |
| Ahorrar tres líneas una sola vez | Solo escribe las tres líneas |
| Ocultar arquitectura detrás de “magia de framework” | Composition roots explícitos |
| Auto-`Codable` / auto-`Hashable` para cada modelo | Manual o codegen con alcance cuidadoso — abundan los edge cases |

**Guía de decisión:** usa un macro cuando la transformación es **estructural, repetitiva, razonada localmente desde la sintaxis**, y puedes entregar **diagnósticos excelentes**.

---

## 8. Tabla de comparación

| Problem | Function | Protocol / Generic | Macro | External codegen | Reflection |
|---------|----------|--------------------|-------|------------------|------------|
| Reutilizar un algoritmo | ✅ | ✅ | ❌ overkill | ❌ | ❌ |
| Comportamiento polimórfico | ✅ | ✅ best | ❌ | ❌ | fragile |
| Emitir members/conformances desde la forma de un tipo | ❌ | limited | ✅ | ✅ | ❌ |
| Capturar el texto fuente de una expresión | ❌ | ❌ | ✅ `#stringify` | ❌ | ❌ |
| Templates cross-language / multi-file | ❌ | ❌ | limited | ✅ | ❌ |
| Inspeccionar tipos desconocidos en runtime | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 9. Aprendizaje progresivo — LEVEL 1–9

| Level | Focus | Run |
|------|-------|-----|
| **1** | Freestanding `#stringify` — AST → `(value, "source")` | `DemoCLI levels` |
| **2** | `@AutoInit` MemberMacro — optionals default a `nil` | |
| **3** | `@MakeBuilder` PeerMacro — Builder hermano, consciente del access-level | |
| **4** | `@Logged` / `@Clamped` AccessorMacro (+ Peer storage) | |
| **5** | `@AutoEquatable` ExtensionMacro — se señalan las **limitaciones** | |
| **6** | Forma de networking de producción `@Endpoint` | |
| **7** | `@AnalyticsEvent` tipado → payload diccionario | |
| **8** | DI educativa `@AutoRegister` + debate | |
| **9** | Cuándo **no** usar macros — checklist de decisión | |

Mapa de implementación: [`Sources/BeyondBoilerplateMacros/`](Sources/BeyondBoilerplateMacros/).

---

## 10. Guion de demo de conferencia (30–45 min)

| Segment | Time | Show | Run | Explain | Audience takeaway |
|---------|------|------|-----|---------|-------------------|
| **Problem** | 3 min | Slide de boilerplate manual de endpoint / README BEFORE | — | Ruido de review, typos, drift | El boilerplate es un riesgo de producto |
| **Boilerplate tax** | 3 min | Multiplicar por N endpoints | — | Los humanos copian-pegan mal | La estructura pide automatización |
| **First macro** | 4 min | `#stringify` en DemoCLI / Xcode | `levels` L1 | ExpressionMacro + texto fuente | Los macros ven la sintaxis |
| **SwiftSyntax** | 5 min | Diagrama de árbol en el README | — | Nodes, decls, attributes | Estás editando un árbol |
| **Expansion** | 4 min | Expand Macro en `@AutoInit` | L2–L3 | Member vs Peer | La elección de rol importa |
| **Production macro** | 8 min | `@Endpoint` BEFORE→AFTER | `wow` | Argumentos, mapeo de query, protocolo | Las expansiones pequeñas ganan |
| **Diagnostics** | 4 min | Romper path de `@Endpoint` / `@AutoInit` en enum | tests o Xcode | Mensajes accionables | Confianza = diagnósticos |
| **Testing** | 4 min | `BeyondBoilerplateMacrosTests` | `swift test` | Snapshots de MacroTesting | Trata las expansiones como API |
| **Limitations** | 4 min | Debate `@AutoEquatable` / `@AutoRegister` | L5, L8 | Magia vs mantenibilidad | Conoce las salidas de escape |
| **Lessons** | 3 min | Checklist LEVEL 9 | L9 | Tabla de decisión | Los macros son una herramienta afilada |

**Momento WOW (núcleo del segmento):**  
1. Mostrar el endpoint manual verboso.  
2. Reemplazar con `@Endpoint`.  
3. Expand Macro / `swift run DemoCLI wow` — “esto es lo que generó el compilador.”  
4. Golpear `InMemoryHTTPClient` — aplausos, sigue offline.

---

## 11. Momento WOW (offline)

```bash
swift run DemoCLI wow
```

Imprime: boilerplate manual → `@Endpoint` → members equivalentes generados → respuesta JSON offline con vibes de Leeds / SwiftLeeds.

En Xcode: abre `Apps/BeyondBoilerplateDemo/.../DemoModels.swift` (o `Sources/DemoCLI/main.swift`), clic derecho en `@Endpoint` → **Expand Macro**.  
En el escenario, prefiere la app iOS para que la audiencia vea la expansión *y* una lista de restaurantes desde `InMemoryHTTPClient`.

---

## 12. Testing de macros

Usa [MacroTesting](https://github.com/pointfreeco/swift-macro-testing) con Swift Testing:

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

Los tests de diagnóstico afirman el **mensaje subrayado**, no un genérico “macro failed.”

```bash
swift test
# 18 tests — expansions + diagnostics
```

---

## Índice rápido de macros

| Macro | Kind(s) | Intent |
|-------|---------|--------|
| `#stringify` | Expression | Enseñanza — valor + texto fuente |
| `@AutoInit` | Member | `init` memberwise (optionals → `nil`) |
| `@MakeBuilder` | Peer | Sibling `TypeBuilder` |
| `@Logged` | Accessor (`didSet`) | Observar escrituras |
| `@Clamped(min:max:)` | Accessor + Peer | Storage numérico acotado |
| `@AutoEquatable` | Extension (+ rol Member) | `==` por propiedades almacenadas |
| `@Endpoint(method:path:)` | Member + Extension | Envelope de networking |
| `@AnalyticsEvent` | Member + Extension | Nombre de evento + parameters |
| `@AutoRegister` | Member | `register(in: DependencyContainer)` |

---

## License / crédito de la charla

Material educativo para **Kevin Morales** — DevFest / London / SwiftLeeds.  
Siéntete libre de hacer fork para workshops; mantén la atribución en abstracts de charlas cuando reutilices el laboratorio.

---

**Empieza aquí en el escenario:** `open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj` → Run en Simulator → Expand Macro en `@Endpoint` en `DemoModels.swift` → (opcional) `swift run DemoCLI wow` para el gemelo de terminal.
