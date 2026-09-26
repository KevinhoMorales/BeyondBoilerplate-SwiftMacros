import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation

// MARK: - Tipos modelo de demo (anotados para expansión en vivo)

@AutoInit
@MakeBuilder
@AutoEquatable
struct Restaurant: Sendable {
    let id: String
    let name: String
    let city: String
    let rating: Double?
}

struct VolumeControl {
    @Logged
    var level: Int = 0

    @Clamped(min: 0, max: 10)
    var percentage: Int = 0
}

@Endpoint(method: .get, path: "/restaurants")
struct GetRestaurants: Sendable {
    let city: String
    let limit: Int
}

@AnalyticsEvent
struct RestaurantOpened: Sendable {
    let restaurantID: String
    let source: String
}

@AutoRegister
struct MenuRepository: Sendable {
    init() {}

    func featured() -> [String] {
        ["Casado", "Gallo Pinto", "Chorreadas"]
    }
}

// MARK: - Entry

@main
struct DemoCLI {
    static func main() {
        let args = CommandLine.arguments.dropFirst()
        let mode = args.first ?? "wow"

        switch mode {
        case "levels", "--levels":
            runAllLevels()
        case "wow", "--wow":
            runWowPath()
        case "help", "--help", "-h":
            printHelp()
        default:
            print("Modo desconocido '\(mode)'.\n")
            printHelp()
        }
    }

    static func printHelp() {
        print(
            """
            DemoCLI — Beyond Boilerplate: Building Production-Ready Swift Macros

            Uso:
              swift run DemoCLI           # ruta WOW de conferencia (default)
              swift run DemoCLI wow       # igual
              swift run DemoCLI levels    # recorrido progresivo LEVEL 1–9
              swift run DemoCLI help

            Totalmente offline. Sin red. Expand Macro en Xcode para expansiones a nivel de fuente.
            """
        )
    }
}

// MARK: - Niveles progresivos

extension DemoCLI {
    static func runAllLevels() {
        banner("LABORATORIO PROGRESIVO — LEVELS 1–9")

        level1_Stringify()
        level2_AutoInit()
        level3_MakeBuilder()
        level4_LoggedAndClamped()
        level5_AutoEquatable()
        level6_Endpoint()
        level7_Analytics()
        level8_AutoRegister()
        level9_DecisionGuidance()

        banner("FIN DE LEVELS — prueba: swift run DemoCLI wow")
    }

    static func level1_Stringify() {
        section("LEVEL 1 — ExpressionMacro freestanding: #stringify")
        let answer = 21
        let (value, source) = #stringify(answer * 2)
        print("  Idea expandida: (answer * 2, \"answer * 2\")")
        print("  Valor en runtime: \(value)")
        print("  Texto fuente capturado: \(source)")
        print("  Conclusión: los macros ven el AST / texto fuente en compile-time.")
    }

    static func level2_AutoInit() {
        section("LEVEL 2 — MemberMacro: @AutoInit")
        let restaurant = Restaurant(id: "r1", name: "Soda Tapia", city: "San José", rating: 4.8)
        print("  Construido con init memberwise generado: \(restaurant)")
        print("  Conclusión: MemberMacro emite members *dentro* del tipo.")
    }

    static func level3_MakeBuilder() {
        section("LEVEL 3 — PeerMacro: @MakeBuilder")
        let restaurant = RestaurantBuilder()
            .with { builder in
                builder.id = "r2"
                builder.name = "Café Britt"
                builder.city = "Heredia"
                builder.rating = 4.5
            }
            .build()
        print("  Tipo peer RestaurantBuilder emitido junto a Restaurant.")
        print("  Construido: \(restaurant)")
        print("  Conclusión: PeerMacro crea declaraciones hermanas en el mismo scope.")
    }

    static func level4_LoggedAndClamped() {
        section("LEVEL 4 — AccessorMacro: @Logged + @Clamped")
        var control = VolumeControl()
        control.level = 3
        control.percentage = 99
        print("  Clamped 99 → \(control.percentage) (max 10)")
        print("  Conclusión: los accessors pueden observar (didSet) o reemplazar get/set (Clamped + peer storage).")
    }

    static func level5_AutoEquatable() {
        section("LEVEL 5 — ExtensionMacro: @AutoEquatable")
        let a = Restaurant(id: "x", name: "A", city: "Cartago", rating: nil)
        let b = Restaurant(id: "x", name: "A", city: "Cartago", rating: nil)
        print("  a == b → \(a == b)")
        print("  LIMITACIÓN: genial para value structs simples; NO auto-generes Codable/Hashable a ciegas.")
    }

    static func level6_Endpoint() {
        section("LEVEL 6 — Producción: @Endpoint")
        let endpoint = GetRestaurants(city: "San José", limit: 5)
        print("  \(endpoint.requestDescription)")
        print("  query: \(endpoint.queryItems)")
        let client = InMemoryHTTPClient()
        do {
            try client.stub(
                GetRestaurants.endpointID,
                response: .init(jsonObject: ["restaurants": ["Soda Tapia", "Silvestre"]])
            )
            let response = try client.send(endpoint)
            let text = String(data: response.body, encoding: .utf8) ?? ""
            print("  Respuesta offline (\(response.statusCode)):\n\(text)")
        } catch {
            print("  error: \(error)")
        }
    }

    static func level7_Analytics() {
        section("LEVEL 7 — Producción: @AnalyticsEvent")
        let event = RestaurantOpened(restaurantID: "r1", source: "search")
        let analytics = InMemoryAnalytics()
        analytics.track(event)
        print("  \(event.payloadDescription)")
        print("  Eventos registrados: \(analytics.events.count)")
    }

    static func level8_AutoRegister() {
        section("LEVEL 8 — Producción (DI educativa): @AutoRegister")
        let container = DependencyContainer()
        MenuRepository.register(in: container)
        let repo = container.resolve(MenuRepository.self)
        print("  \(repo.featured())")
        print("  Debate en el escenario: registro mágico vs composition roots explícitos.")
    }

    static func level9_DecisionGuidance() {
        section("LEVEL 9 — Cuándo NO usar macros")
        print(
            """
              Prefiere una función cuando ahorras ~3 líneas una sola vez.
              Prefiere protocolos/generics para comportamiento polimórfico.
              Prefiere código manual para reglas de negocio y algoritmos complejos.
              Prefiere macros para boilerplate repetitivo, estructural y razonado localmente
              con diagnósticos excelentes — envelopes de networking, lens code, eventos tipados.
            """
        )
    }
}

// MARK: - Ruta WOW de conferencia

extension DemoCLI {
    static func runWowPath() {
        banner("RUTA WOW — boilerplate → macro → equivalente generado")

        print(
            """

            ── 1. EL PROBLEMA (endpoint manual verboso) ─────────────────────────
            Imagina escribir esto a mano para cada llamada de API:

            struct GetRestaurantsManual: EndpointProtocol {
                let city: String
                let limit: Int

                static let endpointID = "GetRestaurantsManual"
                var method: HTTPMethod { .get }
                var path: String { "/restaurants" }
                var queryItems: [URLQueryItem] {
                    [
                        URLQueryItem(name: "city", value: String(describing: city)),
                        URLQueryItem(name: "limit", value: String(describing: limit)),
                    ]
                }
                var requestDescription: String {
                    "\\(method.rawValue) \\(path) [\\(Self.endpointID)]"
                }
            }

            Multiplica por docenas de endpoints. Typos en paths. Drift en IDs. Ruido de review.
            """
        )

        print(
            """
            ── 2. EL MACRO ──────────────────────────────────────────────────────
            @Endpoint(method: .get, path: "/restaurants")
            struct GetRestaurants {
                let city: String
                let limit: Int
            }
            """
        )

        let endpoint = GetRestaurants(city: "San José", limit: 3)
        print("── 3. LO QUE GENERÓ EL COMPILADOR (Expand Macro conceptual) ───────")
        print(generatedEndpointExpansionPrintout())
        print("── 4. RUNTIME (InMemoryHTTPClient totalmente offline) ─────────────")
        print("  \(endpoint.requestDescription)")

        let client = InMemoryHTTPClient()
        do {
            try client.stub(
                "GetRestaurants",
                response: .init(jsonObject: [
                    "city": "San José",
                    "highlights": ["DevFest 2026", "Casado", "Gallo Pinto"],
                ])
            )
            let response = try client.send(endpoint)
            print("  status: \(response.statusCode)")
            print(String(data: response.body, encoding: .utf8) ?? "")
        } catch {
            print("  error: \(error)")
        }

        print(
            """

            ── 5. CONCLUSIÓN PARA LA AUDIENCIA ──────────────────────────────────
            Los macros eliminan boilerplate *estructural* manteniendo los tipos al volante.
            Siempre Expand Macro. Siempre entrega diagnósticos. Siempre sabe cuándo NO usarlos.

            Siguiente: swift run DemoCLI levels
            """
        )
    }

    /// La expansión impresa debe coincidir con lo que EndpointMacro emite realmente (mantén sync con tests/README).
    static func generatedEndpointExpansionPrintout() -> String {
        """
          // members
          public static let endpointID: String = "GetRestaurants"
          public var method: HTTPMethod { .get }
          public var path: String { "/restaurants" }
          public var queryItems: [URLQueryItem] {
              [
                  URLQueryItem(name: "city", value: String(describing: city)),
                  URLQueryItem(name: "limit", value: String(describing: limit)),
              ]
          }
          public var requestDescription: String {
              "\\(method.rawValue) \\(path) [\\(Self.endpointID)]"
          }

          // extension
          extension GetRestaurants: EndpointProtocol {}
        """
    }
}

// MARK: - Helpers

private extension RestaurantBuilder {
    func with(_ mutate: (inout RestaurantBuilder) -> Void) -> RestaurantBuilder {
        var copy = self
        mutate(&copy)
        return copy
    }
}

private func banner(_ text: String) {
    print("\n════════════════════════════════════════════════════════════")
    print(text)
    print("════════════════════════════════════════════════════════════")
}

private func section(_ text: String) {
    print("\n── \(text)")
}
