import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Beyond Boilerplate")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(DemoTheme.ink)

                Text("Building Production-Ready Swift Macros")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DemoTheme.accent)

                Text(
                    "This iOS app links the same local Swift package as DemoCLI. "
                        + "Use it on Simulator or device to expand macros live and tap through offline networking, analytics, and DI."
                )
                .font(.body)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    labelRow(icon: "hammer", title: "Expand Macro", detail: "DemoModels.swift — @Endpoint, @AnalyticsEvent, @AutoInit")
                    labelRow(icon: "iphone", title: "Run", detail: "Scheme BeyondBoilerplateDemo · any iOS 17+ Simulator")
                    labelRow(icon: "terminal", title: "CLI twin", detail: "swift run DemoCLI — same macros, terminal path")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
    }

    private func labelRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(DemoTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

struct RestaurantsStepView: View {
    @Bindable var session: DemoSession

    var body: some View {
        List {
            Section {
                Text("Annotated in DemoModels.swift — Expand Macro on @Endpoint to show generated EndpointProtocol witnesses.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Load restaurants (London)") {
                    session.loadRestaurants(city: "London")
                }
                .buttonStyle(.borderedProminent)
                if !session.lastRequestDescription.isEmpty {
                    LabeledContent("Request", value: session.lastRequestDescription)
                        .font(.caption.monospaced())
                }
            }

            Section("Results") {
                if session.restaurants.isEmpty {
                    Text("Tap Load to hit InMemoryHTTPClient — no network.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.restaurants) { restaurant in
                        Button {
                            session.openRestaurant(restaurant)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(restaurant.name).font(.headline)
                                    Text(restaurant.city).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let rating = restaurant.rating {
                                    Text(String(format: "%.1f", rating))
                                        .font(.subheadline.monospacedDigit().weight(.semibold))
                                        .foregroundStyle(DemoTheme.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }

            if !session.lastResponsePretty.isEmpty {
                Section("Offline JSON") {
                    Text(session.lastResponsePretty)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct AnalyticsStepView: View {
    @Bindable var session: DemoSession

    var body: some View {
        List {
            Section {
                Text("Expand Macro on @AnalyticsEvent in DemoModels.swift — eventName + parameters synthesized.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Fire RestaurantOpened") {
                    session.fireAnalyticsDemo()
                }
                .buttonStyle(.borderedProminent)
                Button("Clear log", role: .destructive) {
                    session.clearAnalytics()
                }
            }

            Section("Recorded events") {
                if session.analyticsLog.isEmpty {
                    Text("No events yet — open a restaurant from step 1 or tap Fire.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(session.analyticsLog.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.name).font(.subheadline.weight(.semibold))
                            Text(entry.detail).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct AutoInitStepView: View {
    @Bindable var session: DemoSession

    var body: some View {
        List {
            Section {
                Text("Expand Macro on @AutoInit / @MakeBuilder / @Clamped on Restaurant and VolumeControl.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Run @AutoInit demo") {
                    session.runAutoInitDemo()
                }
                .buttonStyle(.borderedProminent)
            }

            if !session.autoInitSample.isEmpty {
                Section("Memberwise init") {
                    Text(session.autoInitSample)
                }
                Section("RestaurantBuilder peer") {
                    Text(session.builderSample)
                }
                Section("@Clamped") {
                    Text(session.clampNote)
                }
            }
        }
    }
}

struct DIStepView: View {
    @Bindable var session: DemoSession

    var body: some View {
        List {
            Section {
                Text("Expand Macro on @AutoRegister — emits static register(in: DependencyContainer). Discuss magic vs composition roots on stage.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Resolve MenuRepository") {
                    session.resolveMenuRepository()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Featured dishes") {
                if session.featuredDishes.isEmpty {
                    Text("Not resolved yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(session.featuredDishes, id: \.self) { dish in
                        Text(dish)
                    }
                }
            }
        }
    }
}

struct TakeawayStepView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("When not to use macros")
                    .font(.title2.weight(.bold))

                takeaway("Prefer a function when you are saving ~3 lines once.")
                takeaway("Prefer protocols or generics for polymorphic behavior.")
                takeaway("Prefer manual code for business rules and complex algorithms.")
                takeaway("Prefer macros for repetitive, structural boilerplate with excellent diagnostics.")

                Text("Always Expand Macro. Always ship diagnostics. Always know the escape hatch.")
                    .font(.callout.weight(.semibold))
                    .padding(.top, 8)
                    .foregroundStyle(DemoTheme.accent)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func takeaway(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DemoTheme.accent)
            Text(text).font(.body)
        }
    }
}
