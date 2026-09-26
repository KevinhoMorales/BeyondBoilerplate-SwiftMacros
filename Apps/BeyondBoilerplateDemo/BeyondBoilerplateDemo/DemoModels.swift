import BeyondBoilerplateMacrosClient
import DemoSupport
import Foundation

// MARK: - Objetivos de Expand Macro (charla en escenario)
//
// En Xcode: haz clic en un atributo → Editor → Expand Macro
// Demos en vivo preferidas: @Endpoint, @AnalyticsEvent, @AutoInit

@AutoInit
@MakeBuilder
@AutoEquatable
struct Restaurant: Sendable, Identifiable {
    let id: String
    let name: String
    let city: String
    let rating: Double?
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

@AnalyticsEvent
struct DemoStepViewed: Sendable {
    let step: String
}

@AutoRegister
struct MenuRepository: Sendable {
    init() {}

    func featured() -> [String] {
        ["Casado", "Gallo Pinto", "Chorreadas"]
    }
}

struct VolumeControl {
    @Logged
    var level: Int = 0

    @Clamped(min: 0, max: 10)
    var percentage: Int = 0
}
