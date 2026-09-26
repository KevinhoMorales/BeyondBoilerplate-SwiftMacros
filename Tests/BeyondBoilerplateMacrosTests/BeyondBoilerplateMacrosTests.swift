import MacroTesting
import Testing
@testable import BeyondBoilerplateMacros

@Suite(
    .macros(
        [
            "stringify": StringifyMacro.self,
            "AutoInit": AutoInitMacro.self,
            "MakeBuilder": MakeBuilderMacro.self,
            "Logged": LoggedMacro.self,
            "Clamped": ClampedMacro.self,
            "AutoEquatable": AutoEquatableMacro.self,
            "Endpoint": EndpointMacro.self,
            "AnalyticsEvent": AnalyticsEventMacro.self,
            "AutoRegister": AutoRegisterMacro.self,
        ]
    )
)
struct BeyondBoilerplateMacrosTests {
    // MARK: - Level 1: stringify

    @Test
    func stringifyExpansion() {
        assertMacro {
            """
            #stringify(a + b)
            """
        } expansion: {
            """
            (a + b, "a + b")
            """
        }
    }

    @Test
    func stringifyMissingArgumentDiagnostic() {
        assertMacro {
            """
            #stringify()
            """
        } diagnostics: {
            """
            #stringify()
            ┬───────────
            ╰─ 🛑 #stringify requiere exactamente un argumento de expresión, p. ej. #stringify(a + b).
            """
        }
    }

    // MARK: - Level 2: AutoInit

    @Test
    func autoInitMultiplePropertiesAndOptional() {
        assertMacro {
            """
            @AutoInit
            struct User {
                let name: String
                let age: Int
                let nickname: String?
            }
            """
        } expansion: {
            """
            struct User {
                let name: String
                let age: Int
                let nickname: String?

                init(name: String, age: Int, nickname: String? = nil) {
                    self.name = name
                    self.age = age
                    self.nickname = nickname
                }
            }
            """
        }
    }

    @Test
    func autoInitOnEnumDiagnostic() {
        assertMacro {
            """
            @AutoInit
            enum Role {
                case admin
            }
            """
        } diagnostics: {
            """
            @AutoInit
            ┬────────
            ╰─ 🛑 @AutoInit solo se puede adjuntar a un struct. Los enums y las classes ya tienen reglas de inicialización más ricas—escribe esos inits a mano.
            enum Role {
                case admin
            }
            """
        }
    }

    @Test
    func autoInitNoStoredPropertiesDiagnostic() {
        assertMacro {
            """
            @AutoInit
            struct Empty {
            }
            """
        } diagnostics: {
            """
            @AutoInit
            ┬────────
            ╰─ 🛑 @AutoInit no encontró propiedades almacenadas. Añade members almacenados `let`/`var`, o quita el atributo.
            struct Empty {
            }
            """
        }
    }

    // MARK: - Level 3: MakeBuilder

    @Test
    func makeBuilderExpansion() {
        assertMacro {
            """
            @MakeBuilder
            struct User {
                let name: String
                let age: Int
            }
            """
        } expansion: {
            """
            struct User {
                let name: String
                let age: Int
            }

            struct UserBuilder {
                var name: String = ""
                var age: Int = 0

                init() {
                }

                func build() -> User {
                    User(name: name, age: age)
                }
            }
            """
        }
    }

    @Test
    func makeBuilderOnEnumDiagnostic() {
        assertMacro {
            """
            @MakeBuilder
            enum Role {
                case admin
            }
            """
        } diagnostics: {
            """
            @MakeBuilder
            ┬───────────
            ╰─ 🛑 @MakeBuilder solo se puede adjuntar a un struct para que el peer Builder generado pueda llamar a un inicializador memberwise.
            enum Role {
                case admin
            }
            """
        }
    }

    // MARK: - Level 4: Logged / Clamped

    @Test
    func loggedExpansion() {
        assertMacro {
            """
            struct Volume {
                @Logged
                var level: Int
            }
            """
        } expansion: {
            """
            struct Volume {
                var level: Int {
                    didSet {
                        print("[Logged] level changed to \\(String(describing: level))")
                    }
                }
            }
            """
        }
    }

    @Test
    func clampedExpansion() {
        assertMacro {
            """
            struct Meter {
                @Clamped(min: 0, max: 10)
                var percentage: Int = 0
            }
            """
        } expansion: {
            """
            struct Meter {
                var percentage: Int {
                    get {
                        return _percentage
                    }
                    set {
                        _percentage = min(max(newValue, 0), 10)
                    }
                }

                private var _percentage: Int = 0
            }
            """
        }
    }

    @Test
    func clampedMissingBoundsDiagnostic() {
        assertMacro {
            """
            struct Meter {
                @Clamped
                var percentage: Int = 0
            }
            """
        } diagnostics: {
            """
            struct Meter {
                @Clamped
                ┬───────
                ╰─ 🛑 @Clamped requiere ambos argumentos enteros min: y max:, p. ej. @Clamped(min: 0, max: 10).
                var percentage: Int = 0
            }
            """
        }
    }

    // MARK: - Level 5: AutoEquatable

    @Test
    func autoEquatableExpansion() {
        assertMacro {
            """
            @AutoEquatable
            struct Point {
                let x: Int
                let y: Int
            }
            """
        } expansion: {
            """
            struct Point {
                let x: Int
                let y: Int
            }

            extension Point: Equatable {
                public static func == (lhs: Point, rhs: Point) -> Bool {
                    lhs.x == rhs.x && lhs.y == rhs.y
                }
            }
            """
        }
    }

    // MARK: - Production: Endpoint

    @Test
    func endpointExpansion() {
        assertMacro {
            """
            @Endpoint(method: .get, path: "/restaurants")
            struct GetRestaurants {
                let city: String
                let limit: Int
            }
            """
        } expansion: {
            """
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
                    "\\(method.rawValue) \\(path) [\\(Self.endpointID)]"
                }
            }

            extension GetRestaurants: EndpointProtocol {
            }
            """
        }
    }

    @Test
    func endpointEmptyPathDiagnostic() {
        assertMacro {
            """
            @Endpoint(method: .get, path: "")
            struct Bad {
                let city: String
            }
            """
        } diagnostics: {
            """
            @Endpoint(method: .get, path: "")
            ┬────────────────────────────────
            ╰─ 🛑 @Endpoint path debe ser un string literal no vacío que empiece con '/', p. ej. "/restaurants".
            struct Bad {
                let city: String
            }
            """
        }
    }

    @Test
    func endpointOnEnumDiagnostic() {
        assertMacro {
            """
            @Endpoint(method: .get, path: "/x")
            enum Bad {
                case a
            }
            """
        } diagnostics: {
            """
            @Endpoint(method: .get, path: "/x")
            ┬──────────────────────────────────
            ╰─ 🛑 @Endpoint solo se puede adjuntar a un struct que modele una petición HTTP.
            enum Bad {
                case a
            }
            """
        }
    }

    // MARK: - Production: AnalyticsEvent

    @Test
    func analyticsEventExpansion() {
        assertMacro {
            """
            @AnalyticsEvent
            struct RestaurantOpened {
                let restaurantID: String
                let source: String
            }
            """
        } expansion: {
            """
            struct RestaurantOpened {
                let restaurantID: String
                let source: String

                public static let eventName: String = "restaurant_opened"

                public var parameters: [String: String] {
                    [
                        "restaurantID": String(describing: restaurantID),
                        "source": String(describing: source)
                    ]
                }

                public var payloadDescription: String {
                    let pairs = parameters.map {
                        "\\($0.key)=\\($0.value)"
                    } .sorted().joined(separator: ", ")
                    return "\\(Self.eventName) { \\(pairs) }"
                }
            }

            extension RestaurantOpened: AnalyticsEventProtocol {
            }
            """
        }
    }

    @Test
    func analyticsNoPropertiesDiagnostic() {
        assertMacro {
            """
            @AnalyticsEvent
            struct EmptyEvent {
            }
            """
        } diagnostics: {
            """
            @AnalyticsEvent
            ┬──────────────
            ╰─ 🛑 @AnalyticsEvent no encontró propiedades almacenadas para codificar como parameters del evento.
            struct EmptyEvent {
            }
            """
        }
    }

    // MARK: - Production: AutoRegister

    @Test
    func autoRegisterExpansion() {
        assertMacro {
            """
            @AutoRegister
            struct MenuRepository {
                init() {
                }
            }
            """
        } expansion: {
            """
            struct MenuRepository {
                init() {
                }

                public static func register(in container: DependencyContainer) {
                    container.register(MenuRepository.self) {
                        MenuRepository()
                    }
                }
            }
            """
        }
    }

    @Test
    func autoRegisterOnEnumDiagnostic() {
        assertMacro {
            """
            @AutoRegister
            enum Service {
                case live
            }
            """
        } diagnostics: {
            """
            @AutoRegister
            ┬────────────
            ╰─ 🛑 @AutoRegister solo se puede adjuntar a un tipo struct o class.
            enum Service {
                case live
            }
            """
        }
    }
}
