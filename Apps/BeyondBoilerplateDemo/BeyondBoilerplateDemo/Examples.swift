import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation

// ES: Modelos reales para Expand Macro (clic en el atributo en Xcode).
// EN: Real models for Expand Macro (click the attribute in Xcode).

// MARK: - Basic models

// ES: Plato — @Describable escribe CustomStringConvertible.
// EN: Dish — @Describable writes CustomStringConvertible.
@Describable
@AutoInit
struct Dish: Sendable {
    let name: String
    let price: Double
}

// MARK: - Intermediate models

// ES: @AutoInit (member) escribe el init dentro del tipo.
// EN: @AutoInit (member) writes the init inside the type.
@AutoInit
@MakeBuilder
@AutoEquatable
struct Restaurant: Sendable {
    let id: String
    let name: String
    let city: String
    let rating: Double?
}

// ES: @Clamped (accessor + peer) limita el valor al escribir.
// EN: @Clamped (accessor + peer) clamps the value on write.
struct VolumeControl {
    @Clamped(min: 0, max: 100)
    var percentage: Int = 0
}

// MARK: - Advanced models

// ES: @Endpoint (member + extension) con args method/path.
// EN: @Endpoint (member + extension) with method/path args.
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
        ["Casado", "Gallo Pinto"]
    }
}

// MARK: - Short Before / After / Expanded strings

enum Sample {
    enum AutoInit {
        static let before = """
        init(id: String, name: String, city: String, rating: Double? = nil) {
            self.id = id; self.name = name
            self.city = city; self.rating = rating
        }
        """
        static let after = """
        @AutoInit
        struct Restaurant { let id: String; … }
        """
        static let expanded = """
        init(id:name:city:rating: = nil) { self.id = id; … }
        """
    }

    enum MakeBuilder {
        static let before = """
        // Hand-written sibling type:
        struct RestaurantBuilder {
            var id = ""; var name = ""
            func build() -> Restaurant { … }
        }
        """
        static let after = """
        @MakeBuilder
        struct Restaurant { … }
        // → peer RestaurantBuilder appears beside it
        """
        static let expanded = """
        struct RestaurantBuilder {
            var id: String = ""
            func build() -> Restaurant { … }
        }
        """
    }

    enum Clamped {
        static let before = """
        private var _percentage = 0
        var percentage: Int {
            get { _percentage }
            set { _percentage = min(max(newValue, 0), 100) }
        }
        """
        static let after = """
        @Clamped(min: 0, max: 100)
        var percentage: Int = 0
        """
        static let expanded = """
        var percentage: Int {
            get { _percentage }
            set { _percentage = min(max(newValue, 0), 100) }
        }
        private var _percentage: Int = 0
        """
    }

    enum EquatableExt {
        static let before = """
        extension Restaurant: Equatable {
            static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
                lhs.id == rhs.id && lhs.name == rhs.name …
            }
        }
        """
        static let after = """
        @AutoEquatable
        struct Restaurant { … }
        """
        static let expanded = """
        extension Restaurant: Equatable {
            static func == (lhs:rhs:) -> Bool { … }
        }
        """
    }

    enum Endpoint {
        static let before = """
        struct GetRestaurants: EndpointProtocol {
            let city: String; let limit: Int
            static let endpointID = "GetRestaurants"
            var method: HTTPMethod { .get }
            var path: String { "/restaurants" }
            var queryItems: [URLQueryItem] { … }
        }
        """
        static let after = """
        @Endpoint(method: .get, path: "/restaurants")
        struct GetRestaurants {
            let city: String
            let limit: Int
        }
        """
        static let expanded = """
        public static let endpointID = "GetRestaurants"
        public var method: HTTPMethod { .get }
        public var path: String { "/restaurants" }
        // + queryItems + EndpointProtocol
        """
    }

    static let diagnosticEmptyPath =
        "error: @Endpoint path must be a non-empty string literal starting with '/', e.g. \"/restaurants\"."
    static let diagnosticBadURL =
        "error: #URL(\"not a url\") is not a valid absolute URL. Include a scheme and host."
}
