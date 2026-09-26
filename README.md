# Más allá del boilerplate: macros Swift listas para producción

Material de la charla **DevFest 2026** (Kevin Morales): un paquete Swift con macros de producción, una app iOS de demo y un CLI para explorarlas en vivo.

---

## ¿Qué es una macro de Swift?

A grosso modo: una **macro** es un pequeño programa que el compilador ejecuta **en tiempo de compilación**. Lee el código que escribiste (como árbol de sintaxis, no como texto suelto), genera **más código Swift** y lo inserta en tu módulo. Ese código generado se type-checkea y se compila igual que si lo hubieras escrito a mano.

No es reflexión en runtime ni un script externo tipo Sourcery: la macro participa en el grafo de compilación, puede emitir **diagnósticos** con ubicación en el fuente y lo que produce es Swift ordinario.

La idea práctica: si te encuentras copiando la misma forma (init memberwise, envelope de networking, payload de analytics…) una y otra vez, una macro puede **escribir esa estructura** a partir de lo que ya declaraste.

---

## ¿Cuándo ayudan de verdad?

Las macros brillan cuando el patrón es **estructural y repetitivo**, y se puede razonar desde la sintaxis del tipo o de la expresión:

| Situación | Ejemplo concreto |
|-----------|------------------|
| Envelope de networking igual en cada endpoint | `@Endpoint(method:path:)` genera `method`, `path`, `queryItems` y la conformidad a `EndpointProtocol` |
| Eventos de analytics que se desincronizan del modelo | `@AnalyticsEvent` deriva `eventName` y `parameters` de las propiedades almacenadas |
| `init` memberwise que copias en cada struct | `@AutoInit` emite el inicializador (opcionales → `nil`) |
| Validar configuración **antes** de llegar a runtime | Ruta vacía, macro mal aplicada a un `enum`, argumentos faltantes → el **build falla** con un mensaje claro |

Si el problema es lógica de negocio, algoritmos o comportamiento que depende de valores en runtime, suele ser mejor Swift normal (funciones, protocolos, composición explícita).

---

## Tipos de macros (comparación sencilla)

Hay dos familias grandes:

| Familia | Cómo se ve | Idea |
|---------|------------|------|
| **Freestanding** | `#stringify(a + b)` | Una llamada suelta; típicamente produce una **expresión** |
| **Attached** | `@AutoInit`, `@Endpoint(...)` | Un atributo pegado a un tipo, propiedad, etc.; produce miembros, peers, accessors o extensiones |

Dentro de las **attached**, el rol importa:

| Rol | Qué hace | Analogía rápida | En este repo |
|-----|----------|-----------------|--------------|
| **Member** | Añade miembros *dentro* del tipo | “Mete un `init` o unas props en el struct” | `@AutoInit`, parte de `@Endpoint` |
| **Peer** | Declara algo *al lado* del tipo anotado | “Crea un `FooBuilder` hermano de `Foo`” | `@MakeBuilder` |
| **Accessor** | Adjunta `get` / `set` / `didSet`… a una propiedad | “Observa o acota escrituras” | `@Logged`, `@Clamped` |
| **Conformance / Extension** | Emite `extension Tipo: Protocolo` | “Haz que cumpla un protocolo sin escribirlo a mano” | `@AutoEquatable`, parte de `@Endpoint` |

Una sola anotación puede combinar varios roles (por ejemplo `@Endpoint` = member + extension). Elegir el rol correcto es mitad del diseño de la macro.

Declaraciones públicas: [`Sources/BeyondBoilerplateMacrosClient/Macros.swift`](Sources/BeyondBoilerplateMacrosClient/Macros.swift).  
Implementaciones: [`Sources/BeyondBoilerplateMacros/`](Sources/BeyondBoilerplateMacros/).

---

## Qué hace este repositorio

Paquete Swift único en la raíz + una app iOS que lo consume en local. No hay dos copias de las macros.

| Pieza | Rol |
|-------|-----|
| `BeyondBoilerplateMacros` | Plugin `.macro` (SwiftSyntax) — no lo importas desde la app |
| `BeyondBoilerplateMacrosClient` | Declaraciones `@freestanding` / `@attached` vía `#externalMacro` |
| `DemoSupport` | `HTTPMethod`, `EndpointProtocol`, cliente HTTP en memoria, analytics y DI mínimos (offline) |
| `DemoCLI` | Ejecutable de escenario (`wow`, `levels`, `help`) |
| **BeyondBoilerplateDemo** | App SwiftUI iOS — mismas macros, UI para recorrerlas |
| `BeyondBoilerplateMacrosTests` | Expansiones y diagnósticos con MacroTesting |

### Macros para probar

| Macro | Tipo(s) | Para qué |
|-------|---------|----------|
| `#stringify` | Expression | Valor + texto fuente (pedagogía) |
| `@AutoInit` | Member | `init` memberwise |
| `@MakeBuilder` | Peer | Sibling `TypeBuilder` |
| `@Logged` | Accessor | Observar escrituras (`didSet`) |
| `@Clamped(min:max:)` | Accessor + Peer | Acotar un numérico |
| `@AutoEquatable` | Extension | `==` por propiedades almacenadas |
| `@Endpoint(method:path:)` | Member + Extension | Envelope de networking |
| `@AnalyticsEvent` | Member + Extension | Nombre de evento + parámetros |
| `@AutoRegister` | Member | `register(in: DependencyContainer)` (DI educativa) |

### Cómo abrir y ejecutar

**Requisitos:** Swift 6.4+, Xcode reciente, macOS 14+ / iOS 17+ (librería). Macros requieren Swift 5.9+; este paquete usa **Swift 6** language mode.

**App iOS (recomendado en escenario):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Scheme **BeyondBoilerplateDemo** → Simulator iOS 17+ → Run.  
El target enlaza el paquete local de la raíz (`BeyondBoilerplateMacrosClient` + `DemoSupport`).

**Paquete / CLI:**

```bash
open Package.swift
swift build
swift test
swift run DemoCLI          # camino WOW (default)
swift run DemoCLI levels   # recorrido LEVEL 1–9
swift run DemoCLI help
```

Todo funciona **offline** (stub en memoria). Sin frameworks de DI de terceros.

---

## BEFORE / AFTER — `@Endpoint`

**Antes** (boilerplate a mano en cada endpoint):

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

**Después** (lo que escribes):

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

La expansión genera `endpointID`, `method`, `path`, `queryItems`, `requestDescription` y `extension GetRestaurants: EndpointProtocol`. Ábrela en Xcode (abajo) o mírala en los tests.

---

## Expand Macro en Xcode

1. Abre `Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo/DemoModels.swift` (o `Sources/DemoCLI/main.swift`).
2. Haz clic en el atributo (`@Endpoint`, `@AnalyticsEvent`, `@AutoInit`, …).
3. **Editor → Expand Macro** (o clic derecho → **Expand Macro**).

En la charla: deja la hoja de expansión abierta mientras usas la UI de la app — el público ve el código en compile-time y el comportamiento en runtime a la vez.

---

## Layout del repo

```
BeyondBoilerplate-SwiftMacros/
├── Package.swift
├── README.md
├── Docs/                              ← notas de speaker / slides
├── Apps/BeyondBoilerplateDemo/        ← .xcodeproj iOS (SPM local)
├── Sources/
│   ├── BeyondBoilerplateMacros/       ← implementaciones
│   ├── BeyondBoilerplateMacrosClient/ ← declaraciones públicas
│   ├── DemoSupport/                   ← stubs offline
│   └── DemoCLI/                       ← ejecutable de demo
└── Tests/BeyondBoilerplateMacrosTests/
```

Estudio / `swift test` / CLI → `Package.swift`. Expand Macro + Simulator → el `.xcodeproj`. Ambos comparten el mismo paquete.

---

## Licencia / crédito

Material educativo de la charla DevFest 2026 — **Kevin Morales**.  
Puedes forkarlo para talleres; mantén la atribución si reutilizas el material en abstracts.

**Arranque rápido en escenario:** `open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj` → Run → Expand Macro sobre `@Endpoint` en `DemoModels.swift`.
