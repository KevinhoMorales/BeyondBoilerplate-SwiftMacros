import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation

// MARK: - Demo model types (annotated for live expansion)

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
            print("Unknown mode '\(mode)'.\n")
            printHelp()
        }
    }

    static func printHelp() {
        print(
            """
            DemoCLI — Beyond Boilerplate: Building Production-Ready Swift Macros

            Usage:
              swift run DemoCLI           # WOW conference path (default)
              swift run DemoCLI wow       # same
              swift run DemoCLI levels    # progressive LEVEL 1–9 walkthrough
              swift run DemoCLI help

            Fully offline. No network. Expand Macro in Xcode for source-level expansions.
            """
        )
    }
}

// MARK: - Progressive levels

extension DemoCLI {
    static func runAllLevels() {
        banner("PROGRESSIVE LABORATORY — LEVELS 1–9")

        level1_Stringify()
        level2_AutoInit()
        level3_MakeBuilder()
        level4_LoggedAndClamped()
        level5_AutoEquatable()
        level6_Endpoint()
        level7_Analytics()
        level8_AutoRegister()
        level9_DecisionGuidance()

        banner("END OF LEVELS — try: swift run DemoCLI wow")
    }

    static func level1_Stringify() {
        section("LEVEL 1 — Freestanding ExpressionMacro: #stringify")
        let answer = 21
        let (value, source) = #stringify(answer * 2)
        print("  Expanded idea: (answer * 2, \"answer * 2\")")
        print("  Runtime value: \(value)")
        print("  Captured source text: \(source)")
        print("  Takeaway: macros see the AST / source text at compile time.")
    }

    static func level2_AutoInit() {
        section("LEVEL 2 — MemberMacro: @AutoInit")
        let restaurant = Restaurant(id: "r1", name: "Soda Tapia", city: "San José", rating: 4.8)
        print("  Built with generated memberwise init: \(restaurant)")
        print("  Takeaway: MemberMacro emits members *inside* the type.")
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
        print("  Peer type RestaurantBuilder emitted beside Restaurant.")
        print("  Built: \(restaurant)")
        print("  Takeaway: PeerMacro creates sibling declarations at the same scope.")
    }

    static func level4_LoggedAndClamped() {
        section("LEVEL 4 — AccessorMacro: @Logged + @Clamped")
        var control = VolumeControl()
        control.level = 3
        control.percentage = 99
        print("  Clamped 99 → \(control.percentage) (max 10)")
        print("  Takeaway: accessors can observe (didSet) or replace get/set (Clamped + peer storage).")
    }

    static func level5_AutoEquatable() {
        section("LEVEL 5 — ExtensionMacro: @AutoEquatable")
        let a = Restaurant(id: "x", name: "A", city: "Cartago", rating: nil)
        let b = Restaurant(id: "x", name: "A", city: "Cartago", rating: nil)
        print("  a == b → \(a == b)")
        print("  LIMITATION: great for simple value structs; do NOT auto-gen Codable/Hashable blindly.")
    }

    static func level6_Endpoint() {
        section("LEVEL 6 — Production: @Endpoint")
        let endpoint = GetRestaurants(city: "London", limit: 5)
        print("  \(endpoint.requestDescription)")
        print("  query: \(endpoint.queryItems)")
        let client = InMemoryHTTPClient()
        do {
            try client.stub(
                GetRestaurants.endpointID,
                response: .init(jsonObject: ["restaurants": ["Dishoom", "Padella"]])
            )
            let response = try client.send(endpoint)
            let text = String(data: response.body, encoding: .utf8) ?? ""
            print("  Offline response (\(response.statusCode)):\n\(text)")
        } catch {
            print("  error: \(error)")
        }
    }

    static func level7_Analytics() {
        section("LEVEL 7 — Production: @AnalyticsEvent")
        let event = RestaurantOpened(restaurantID: "r1", source: "search")
        let analytics = InMemoryAnalytics()
        analytics.track(event)
        print("  \(event.payloadDescription)")
        print("  Recorded events: \(analytics.events.count)")
    }

    static func level8_AutoRegister() {
        section("LEVEL 8 — Production (educational DI): @AutoRegister")
        let container = DependencyContainer()
        MenuRepository.register(in: container)
        let repo = container.resolve(MenuRepository.self)
        print("  \(repo.featured())")
        print("  Debate on stage: magic registration vs explicit composition roots.")
    }

    static func level9_DecisionGuidance() {
        section("LEVEL 9 — When NOT to use macros")
        print(
            """
              Prefer a function when you are saving ~3 lines once.
              Prefer protocols/generics for polymorphic behavior.
              Prefer manual code for business rules and complex algorithms.
              Prefer macros for repetitive, structural, locally-reasoned boilerplate
              with excellent diagnostics — networking envelopes, lens code, typed events.
            """
        )
    }
}

// MARK: - WOW conference path

extension DemoCLI {
    static func runWowPath() {
        banner("WOW PATH — boilerplate → macro → generated equivalent")

        print(
            """

            ── 1. THE PROBLEM (verbose manual endpoint) ─────────────────────────
            Imagine writing this by hand for every API call:

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

            Multiply by dozens of endpoints. Typos in paths. Drift in IDs. Review noise.
            """
        )

        print(
            """
            ── 2. THE MACRO ─────────────────────────────────────────────────────
            @Endpoint(method: .get, path: "/restaurants")
            struct GetRestaurants {
                let city: String
                let limit: Int
            }
            """
        )

        let endpoint = GetRestaurants(city: "Leeds", limit: 3)
        print("── 3. WHAT THE COMPILER GENERATED (conceptual Expand Macro) ───────")
        print(generatedEndpointExpansionPrintout())
        print("── 4. RUNTIME (fully offline InMemoryHTTPClient) ──────────────────")
        print("  \(endpoint.requestDescription)")

        let client = InMemoryHTTPClient()
        do {
            try client.stub(
                "GetRestaurants",
                response: .init(jsonObject: [
                    "city": "Leeds",
                    "highlights": ["SwiftLeeds", "Tiled Hall", "Belgrave Music Hall"],
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

            ── 5. AUDIENCE TAKEAWAY ─────────────────────────────────────────────
            Macros delete *structural* boilerplate while keeping types in the driver's seat.
            Always Expand Macro. Always ship diagnostics. Always know when NOT to use them.

            Next: swift run DemoCLI levels
            """
        )
    }

    /// Printed expansion must match what EndpointMacro actually emits (keep in sync with tests/README).
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
