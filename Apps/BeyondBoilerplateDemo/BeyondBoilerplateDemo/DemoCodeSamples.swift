import Foundation

/// Sample source shown in the UI as text — mirrors README sin/con macro.
/// Not compiled; the live “Con macro” path uses real annotations in `DemoModels.swift`.
enum DemoCodeSamples {
    enum Endpoint {
        static let withoutMacro = """
        struct GetRestaurants: EndpointProtocol {
            let city: String
            let limit: Int

            static let endpointID = "GetRestaurants"
            var method: HTTPMethod { .get }
            var path: String { "/restaurants" }
            var queryItems: [URLQueryItem] {
                [
                    URLQueryItem(name: "city",
                        value: String(describing: city)),
                    URLQueryItem(name: "limit",
                        value: String(describing: limit)),
                ]
            }
            var requestDescription: String {
                "\\(method.rawValue) \\(path) [\\(Self.endpointID)]"
            }
        }
        """

        static let withMacro = """
        @Endpoint(method: .get, path: "/restaurants")
        struct GetRestaurants: Sendable {
            let city: String
            let limit: Int
        }
        """

        static let whatYouSee =
            "Sin macro: el boilerplate que copiarías en cada endpoint. "
            + "Con macro: lo que escribes con @Endpoint — Expand Macro en Xcode revela el resto."

        static let whyItHelps =
            "El macro genera method, path, queryItems y EndpointProtocol. "
            + "Menos ruido, menos drift entre endpoints, mismos tipos en compile-time."
    }

    enum Analytics {
        static let withoutMacro = """
        struct RestaurantOpened {
            let restaurantID: String
            let source: String

            static let eventName = "restaurant_opened"
            var parameters: [String: String] {
                [
                    "restaurant_id": restaurantID,
                    "source": source,
                ]
            }
        }
        """

        static let withMacro = """
        @AnalyticsEvent
        struct RestaurantOpened: Sendable {
            let restaurantID: String
            let source: String
        }
        """

        static let whatYouSee =
            "Sin macro: nombres y diccionarios a mano (fáciles de desincronizar). "
            + "Con macro: solo propiedades; eventName y parameters se sintetizan."

        static let whyItHelps =
            "Los eventos tipados dejan de depender de strings sueltos. "
            + "Expand Macro muestra eventName + payload — sin SDK de analytics."
    }

    enum AutoInit {
        static let withoutMacro = """
        struct Restaurant {
            let id: String
            let name: String
            let city: String
            let rating: Double?

            init(
                id: String,
                name: String,
                city: String,
                rating: Double? = nil
            ) {
                self.id = id
                self.name = name
                self.city = city
                self.rating = rating
            }
        }
        """

        static let withMacro = """
        @AutoInit
        @MakeBuilder
        @AutoEquatable
        struct Restaurant: Sendable, Identifiable {
            let id: String
            let name: String
            let city: String
            let rating: Double?
        }
        """

        static let whatYouSee =
            "Init memberwise (y Builder) que reescribirías al añadir una propiedad. "
            + "Con @AutoInit / @MakeBuilder el compilador lo mantiene al día."

        static let whyItHelps =
            "Macros estructurales: la forma del tipo es la fuente de verdad. "
            + "Ideal para boilerplate repetitivo — no para reglas de negocio."
    }

    enum AutoRegister {
        static let withoutMacro = """
        struct MenuRepository {
            init() {}
            func featured() -> [String] { … }
        }

        // En el composition root, a mano:
        container.register(MenuRepository.self) {
            MenuRepository()
        }
        """

        static let withMacro = """
        @AutoRegister
        struct MenuRepository: Sendable {
            init() {}
            func featured() -> [String] { … }
        }

        // Sigue siendo explícito en el root:
        MenuRepository.register(in: container)
        """

        static let whatYouSee =
            "El macro emite register(in:) en el tipo. "
            + "Aún llamas register desde el composition root — no es un escáner mágico global."

        static let whyItHelps =
            "Reduce ruido de registro homogéneo. "
            + "Debate en escenario: ¿cuándo preferir registro 100% manual?"
    }
}
