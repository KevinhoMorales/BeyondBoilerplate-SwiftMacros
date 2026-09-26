# Más allá del boilerplate: macros Swift listas para producción

Material de la charla **DevFest 2026** (Kevin Morales): macros pensadas para producción, una app iOS para enseñarlas en vivo y un CLI para explorarlas sin red.

El código, los identificadores y la salida del CLI están en **inglés**. Este README es la guía en español.

---

## ¿Qué es una macro de Swift?

Imagina que el compilador tiene un ayudante. Tú escribes una anotación corta (`@Endpoint`, `@AutoInit`, `#stringify`…) y, **antes de type-checkear**, ese ayudante lee tu código como árbol de sintaxis, escribe el Swift que faltaba y lo inserta en el módulo. Lo que sale es código normal: se type-checkea, se depura y se compila igual que si lo hubieras tecleado a mano.

No es reflexión en runtime. Tampoco un script externo tipo Sourcery. La macro vive dentro del build: puede fallar con **diagnósticos** claros y lo que produce es Swift ordinario.

La intuición útil: si copias la misma *forma* una y otra vez (un `init` memberwise, el envelope de un endpoint, el diccionario de un evento de analytics…), una macro puede **escribir esa estructura** a partir de lo que ya declaraste.

### Sin macro vs con macro — dos ejemplos

Mismo endpoint, dos formas de escribirlo. A la izquierda (o arriba), el ruido que repites en cada API. A la derecha (o abajo), lo que dejas en el fuente cuando usas la macro.

**Networking — a mano:**

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

**Networking — con `@Endpoint`:**

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

La expansión genera `endpointID`, `method`, `path`, `queryItems`, `requestDescription` y `extension GetRestaurants: EndpointProtocol`. En Xcode: clic en `@Endpoint` → **Expand Macro** y lo ves literal.

Otro patrón que duele menos con macros: el `init` memberwise.

**Init — a mano:**

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

**Init — con `@AutoInit`:**

```swift
@AutoInit
struct Restaurant {
    let id: String
    let name: String
    let rating: Double?
}
```

Misma forma, menos copia-pega. La macro no inventa lógica de negocio: solo **autoría estructural**.

---

## ¿Cuándo valen la pena?

Cuando el patrón es **estructural, repetitivo** y se puede razonar desde la sintaxis del tipo o de la expresión:

| Situación | En este repo |
|-----------|--------------|
| Cada endpoint repite el mismo envelope | `@Endpoint(method:path:)` |
| Los eventos de analytics se desincronizan del modelo | `@AnalyticsEvent` |
| Copias el mismo `init` en cada struct | `@AutoInit` |
| Quieres que una config mala **falle en el build** | Ruta vacía, macro en un `enum`, args faltantes → diagnóstico claro |

Si el problema es regla de negocio, un algoritmo o algo que depende de valores en runtime, suele ganar Swift normal: funciones, protocolos y composición explícita. Las macros quitan ruido; no deberían esconder arquitectura.

---

## Tipos de macros (mapa corto)

Dos familias:

| Familia | Cómo se ve | Idea |
|---------|------------|------|
| **Freestanding** | `#stringify(a + b)` | Llamada suelta; suele producir una **expresión** |
| **Attached** | `@AutoInit`, `@Endpoint(...)` | Atributo sobre un tipo o propiedad; produce miembros, peers, accessors o extensiones |

Roles habituales en las **attached**:

| Rol | Qué hace | En este repo |
|-----|----------|--------------|
| **Member** | Añade miembros *dentro* del tipo | `@AutoInit`, parte de `@Endpoint` |
| **Peer** | Declara algo *al lado* del tipo | `@MakeBuilder` → `FooBuilder` junto a `Foo` |
| **Accessor** | Adjunta `get` / `set` / `didSet`… | `@Logged`, `@Clamped` |
| **Extension** | Emite `extension Tipo: Protocolo` | `@AutoEquatable`, parte de `@Endpoint` |

Una sola anotación puede mezclar roles (`@Endpoint` = member + extension). Elegir el rol correcto es media batalla de diseño.

Declaraciones: [`Macros.swift`](Sources/BeyondBoilerplateMacrosClient/Macros.swift).  
Implementaciones: [`Sources/BeyondBoilerplateMacros/`](Sources/BeyondBoilerplateMacros/).

---

## Qué hay en el repo

Un solo `Package.swift` en la raíz. La app iOS lo consume en local — no hay dos copias de las macros.

| Pieza | Rol |
|-------|-----|
| `BeyondBoilerplateMacros` | Plugin `.macro` (SwiftSyntax) — la app no lo importa |
| `BeyondBoilerplateMacrosClient` | Declaraciones vía `#externalMacro` |
| `DemoSupport` | `HTTPMethod`, `EndpointProtocol`, HTTP/analytics/DI mínimos (offline) |
| `DemoCLI` | Escenario de terminal (`wow`, `levels`, `help`) |
| **BeyondBoilerplateDemo** | App SwiftUI — mismas macros, UI para recorrerlas |
| `BeyondBoilerplateMacrosTests` | Expansiones y diagnósticos (MacroTesting) |

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

**Requisitos:** Swift 6.4+, Xcode reciente, macOS 14+ / iOS 17+ (librería). Macros desde Swift 5.9+; este paquete usa **Swift 6** language mode.

**App iOS (recomendada en escenario):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Scheme **BeyondBoilerplateDemo** → Simulator iOS 17+ → Run.  
El target enlaza el paquete local (`BeyondBoilerplateMacrosClient` + `DemoSupport`).

**Paquete / CLI:**

```bash
open Package.swift
swift build
swift test
swift run DemoCLI          # camino WOW (default)
swift run DemoCLI levels   # recorrido LEVEL 1–9
swift run DemoCLI help
```

Todo **offline** (stub en memoria). Sin frameworks de DI de terceros.

---

## Expand Macro en Xcode

1. Abre `Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo/DemoModels.swift` (o `Sources/DemoCLI/main.swift`).
2. Haz clic en el atributo (`@Endpoint`, `@AnalyticsEvent`, `@AutoInit`, …).
3. **Editor → Expand Macro** (o clic derecho → **Expand Macro**).

En la charla: deja la hoja de expansión abierta mientras usas la UI — el público ve el código en compile-time y el comportamiento en runtime a la vez.

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

**Arranque en escenario:** `open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj` → Run → Expand Macro sobre `@Endpoint` en `DemoModels.swift`.
