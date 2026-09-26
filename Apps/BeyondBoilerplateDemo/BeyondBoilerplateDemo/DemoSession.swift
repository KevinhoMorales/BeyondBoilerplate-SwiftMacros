import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation
import Observation

/// Offline demo engine — same stubs as DemoCLI, wired for SwiftUI.
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
            case .welcome: "Welcome"
            case .restaurants: "1 · @Endpoint"
            case .analytics: "2 · @AnalyticsEvent"
            case .autoInit: "3 · @AutoInit"
            case .dependencyInjection: "4 · @AutoRegister"
            case .takeaway: "When not to use macros"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome:
                "Progressive iOS lab — expand macros in Xcode, tap through offline demos."
            case .restaurants:
                "Fetch restaurants via generated EndpointProtocol + InMemoryHTTPClient."
            case .analytics:
                "Fire typed events; no vendor SDK — just an in-memory sink."
            case .autoInit:
                "Memberwise init (and peers) synthesized at compile time."
            case .dependencyInjection:
                "Educational DI registration — debate magic vs explicit roots."
            case .takeaway:
                "Macros delete structural boilerplate — not business rules."
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
    private(set) var statusMessage: String = "Ready — fully offline."

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

    func loadRestaurants(city: String = "London") {
        let endpoint = GetRestaurants(city: city, limit: 5)
        lastRequestDescription = endpoint.requestDescription
        do {
            let response = try http.send(endpoint)
            lastResponsePretty = String(data: response.body, encoding: .utf8) ?? ""
            restaurants = decodeRestaurants(from: response.body, fallbackCity: city)
            statusMessage = "Loaded \(restaurants.count) restaurants · \(city)"
        } catch {
            statusMessage = "Request failed: \(error.localizedDescription)"
            restaurants = []
        }
    }

    func openRestaurant(_ restaurant: Restaurant) {
        let event = RestaurantOpened(restaurantID: restaurant.id, source: "list")
        analytics.track(event)
        appendAnalytics(event)
        statusMessage = "Tracked \(type(of: event).eventName)"
    }

    func fireAnalyticsDemo() {
        let event = RestaurantOpened(restaurantID: "dishoom", source: "stage_tap")
        analytics.track(event)
        appendAnalytics(event)
        statusMessage = "Events recorded: \(analytics.events.count)"
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
        builder.name = "Dishoom"
        builder.city = "London"
        builder.rating = 4.9
        let viaBuilder = builder.build()
        builderSample = "\(viaBuilder.name) · \(viaBuilder.city)"

        var volume = VolumeControl()
        volume.percentage = 99
        clampNote = "Clamped 99 → \(volume.percentage) (max 10)"
        statusMessage = "@AutoInit / @MakeBuilder / @Clamped exercised"
    }

    func resolveMenuRepository() {
        let repo = container.resolve(MenuRepository.self)
        featuredDishes = repo.featured()
        statusMessage = "Resolved MenuRepository · \(featuredDishes.count) dishes"
    }

    func clearAnalytics() {
        analytics.reset()
        analyticsLog.removeAll()
        statusMessage = "Analytics cleared"
    }

    // MARK: - Private

    private func seedHTTPStubs() {
        try? http.stub(
            GetRestaurants.endpointID,
            response: .init(jsonObject: [
                "city": "London",
                "restaurants": [
                    ["id": "dishoom", "name": "Dishoom", "city": "London", "rating": 4.8],
                    ["id": "padella", "name": "Padella", "city": "London", "rating": 4.7],
                    ["id": "bao", "name": "Bao", "city": "London", "rating": 4.5],
                    ["id": "stjohn", "name": "St. JOHN", "city": "London", "rating": 4.6],
                    ["id": "brat", "name": "Brat", "city": "London", "rating": 4.4],
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
