import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation
import Observation

/// Motor de demo offline — mismos stubs que DemoCLI, cableados para SwiftUI.
@Observable
@MainActor
final class DemoSession {
    enum Step: String, CaseIterable, Identifiable {
        case welcome
        case restaurants
        case analytics
        case autoInit
        case dependencyInjection
        case takeaway

        var id: String { rawValue }

        var title: String {
            switch self {
            case .welcome: "Bienvenida"
            case .restaurants: "1 · @Endpoint"
            case .analytics: "2 · @AnalyticsEvent"
            case .autoInit: "3 · @AutoInit"
            case .dependencyInjection: "4 · @AutoRegister"
            case .takeaway: "Cuándo no usar macros"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome:
                "Lab iOS progresivo — expande macros en Xcode, recorre demos offline."
            case .restaurants:
                "Obtén restaurantes vía EndpointProtocol generado + InMemoryHTTPClient."
            case .analytics:
                "Dispara eventos tipados; sin SDK de vendor — solo un sink en memoria."
            case .autoInit:
                "Init memberwise (y peers) sintetizados en compile-time."
            case .dependencyInjection:
                "Registro DI educativo — debate magia vs roots explícitos."
            case .takeaway:
                "Los macros eliminan boilerplate estructural — no reglas de negocio."
            }
        }
    }

    private(set) var restaurants: [Restaurant] = []
    private(set) var lastRequestDescription: String = ""
    private(set) var lastResponsePretty: String = ""
    private(set) var analyticsLog: [(name: String, detail: String)] = []
    private(set) var featuredDishes: [String] = []
    private(set) var autoInitSample: String = ""
    private(set) var builderSample: String = ""
    private(set) var clampNote: String = ""
    private(set) var statusMessage: String = "Listo — totalmente offline."

    private let http = InMemoryHTTPClient()
    private let analytics = InMemoryAnalytics()
    private let container = DependencyContainer()

    init() {
        seedHTTPStubs()
        MenuRepository.register(in: container)
    }

    func onAppear(step: Step) {
        let event = DemoStepViewed(step: step.rawValue)
        analytics.track(event)
        appendAnalytics(event)
    }

    func loadRestaurants(city: String = "San José") {
        let endpoint = GetRestaurants(city: city, limit: 5)
        lastRequestDescription = endpoint.requestDescription
        do {
            let response = try http.send(endpoint)
            lastResponsePretty = String(data: response.body, encoding: .utf8) ?? ""
            restaurants = decodeRestaurants(from: response.body, fallbackCity: city)
            statusMessage = "Cargados \(restaurants.count) restaurantes · \(city)"
        } catch {
            statusMessage = "Petición fallida: \(error.localizedDescription)"
            restaurants = []
        }
    }

    func openRestaurant(_ restaurant: Restaurant) {
        let event = RestaurantOpened(restaurantID: restaurant.id, source: "list")
        analytics.track(event)
        appendAnalytics(event)
        statusMessage = "Registrado \(type(of: event).eventName)"
    }

    func fireAnalyticsDemo() {
        let event = RestaurantOpened(restaurantID: "soda-tapia", source: "stage_tap")
        analytics.track(event)
        appendAnalytics(event)
        statusMessage = "Eventos registrados: \(analytics.events.count)"
    }

    func runAutoInitDemo() {
        let viaInit = Restaurant(
            id: "r1",
            name: "Soda Tapia",
            city: "San José",
            rating: 4.8
        )
        autoInitSample = "\(viaInit.name) · \(viaInit.city) · \(viaInit.rating.map { String($0) } ?? "—")"

        var builder = RestaurantBuilder()
        builder.id = "r2"
        builder.name = "Soda Tapia"
        builder.city = "San José"
        builder.rating = 4.9
        let viaBuilder = builder.build()
        builderSample = "\(viaBuilder.name) · \(viaBuilder.city)"

        var volume = VolumeControl()
        volume.percentage = 99
        clampNote = "Clamped 99 → \(volume.percentage) (max 10)"
        statusMessage = "@AutoInit / @MakeBuilder / @Clamped ejercitados"
    }

    func resolveMenuRepository() {
        let repo = container.resolve(MenuRepository.self)
        featuredDishes = repo.featured()
        statusMessage = "Resuelto MenuRepository · \(featuredDishes.count) platos"
    }

    func clearAnalytics() {
        analytics.reset()
        analyticsLog.removeAll()
        statusMessage = "Analytics limpiado"
    }

    // MARK: - Private

    private func seedHTTPStubs() {
        try? http.stub(
            GetRestaurants.endpointID,
            response: .init(jsonObject: [
                "city": "San José",
                "restaurants": [
                    ["id": "soda-tapia", "name": "Soda Tapia", "city": "San José", "rating": 4.8],
                    ["id": "la-esquin", "name": "La Esquina de Buenos Aires", "city": "San José", "rating": 4.7],
                    ["id": "silvestre", "name": "Silvestre", "city": "San José", "rating": 4.5],
                    ["id": "raco", "name": "Raco", "city": "San José", "rating": 4.6],
                    ["id": "almanza", "name": "Almanza", "city": "San José", "rating": 4.4],
                ],
            ])
        )
    }

    private func appendAnalytics(_ event: some AnalyticsEventProtocol) {
        analyticsLog.insert(
            (name: type(of: event).eventName, detail: event.payloadDescription),
            at: 0
        )
    }

    private func decodeRestaurants(from data: Data, fallbackCity: String) -> [Restaurant] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawList = root["restaurants"] as? [Any]
        else {
            return []
        }

        return rawList.enumerated().compactMap { index, item in
            if let name = item as? String {
                return Restaurant(id: "r\(index)", name: name, city: fallbackCity, rating: nil)
            }
            guard let row = item as? [String: Any], let name = row["name"] as? String else {
                return nil
            }
            let id = (row["id"] as? String) ?? "r\(index)"
            let city = (row["city"] as? String) ?? fallbackCity
            let rating = row["rating"] as? Double
            return Restaurant(id: id, name: name, city: city, rating: rating)
        }
    }
}
