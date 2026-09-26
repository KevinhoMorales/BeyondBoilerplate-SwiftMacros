# Beyond Boilerplate: Building Production-Ready Swift Macros

Laboratorio corto para la charla de **Kevin Morales** en **DevFest 2026**.

Paquete Swift con macros de ejemplo, una app iOS offline y un CLI (`DemoCLI`) para ver el “antes / después” en vivo. README y textos de UI en español; sintaxis, nombres de macros, rutas, comandos y URLs en inglés.

**Idea en una frase:** un macro escribe código por ti en *compile time*; el binario solo lleva el Swift ya expandido.

Más detalle vive en comentarios del código y en [`Docs/SPEAKER_NOTES.md`](Docs/SPEAKER_NOTES.md).

---

## Requisitos mínimos

| Herramienta | Versión |
|-------------|---------|
| **Swift** | 6.4+ |
| **Xcode** | 27+ (app iOS) |
| **Plataformas** | macOS 14+, iOS 17+ |

---

## Abrir y correr

**App iOS (preferida en escenario):**

```bash
git clone https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros.git
cd BeyondBoilerplate-SwiftMacros
open Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo.xcodeproj
```

Scheme **BeyondBoilerplateDemo** → Simulator iOS 17+ → Run.  
La app usa el paquete local de la raíz (mismos macros que el CLI).

**Package / CLI:**

```bash
open Package.swift   # opcional
swift test
swift run DemoCLI          # path WOW (default)
swift run DemoCLI levels   # LEVEL 1–9
swift run DemoCLI help
```

Todo es **offline** (HTTP stub en memoria).

---

## Ejemplo corto: `@Endpoint`

**BEFORE** (a mano, cada endpoint):

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

**AFTER** (lo que escribes):

```swift
@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants {
    let city: String
    let limit: Int
}
```

En Xcode: clic derecho en `@Endpoint` → **Expand Macro** para ver el código generado.

---

## Macros del repo

| Macro | Qué hace |
|-------|----------|
| `#stringify` | Valor + texto fuente (enseñanza) |
| `@AutoInit` | `init` memberwise |
| `@MakeBuilder` | Sibling `TypeBuilder` |
| `@Logged` | Observa escrituras (`didSet`) |
| `@Clamped(min:max:)` | Número acotado |
| `@AutoEquatable` | `==` por propiedades |
| `@Endpoint(method:path:)` | Envelope de networking |
| `@AnalyticsEvent` | Nombre + parameters |
| `@AutoRegister` | `register(in: DependencyContainer)` |

---

## Expand Macro en Xcode

1. Abre `Apps/BeyondBoilerplateDemo/BeyondBoilerplateDemo/DemoModels.swift` (o `Sources/DemoCLI/main.swift`).
2. Clic en el atributo → **Editor → Expand Macro** (o clic derecho).
3. En la app, carga restaurantes con la hoja de expansión abierta: compile-time y runtime juntos.

---

## Repo y estructura

https://github.com/KevinhoMorales/BeyondBoilerplate-SwiftMacros

```
BeyondBoilerplate-SwiftMacros/
├── Package.swift
├── Apps/BeyondBoilerplateDemo/     ← .xcodeproj iOS
├── Sources/
│   ├── BeyondBoilerplateMacros/        ← implementaciones
│   ├── BeyondBoilerplateMacrosClient/  ← declaraciones públicas
│   ├── DemoSupport/                    ← stubs offline
│   └── DemoCLI/                        ← executable de demo
└── Tests/BeyondBoilerplateMacrosTests/
```

Material educativo para **Kevin Morales** — DevFest 2026.
