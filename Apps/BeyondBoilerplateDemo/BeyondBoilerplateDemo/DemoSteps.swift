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
                    "Esta app iOS enlaza el mismo paquete Swift local que DemoCLI. "
                        + "Úsala en Simulator o device para expandir macros en vivo y recorrer networking, analytics y DI offline."
                )
                .font(.body)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    labelRow(icon: "hammer", title: "Expand Macro", detail: "DemoModels.swift — @Endpoint, @AnalyticsEvent, @AutoInit")
                    labelRow(icon: "iphone", title: "Run", detail: "Scheme BeyondBoilerplateDemo · cualquier Simulator iOS 17+")
                    labelRow(icon: "terminal", title: "Gemelo CLI", detail: "swift run DemoCLI — mismos macros, ruta de terminal")
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
                Text("Anotado en DemoModels.swift — Expand Macro en @Endpoint para mostrar witnesses generados de EndpointProtocol.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Cargar restaurantes (London)") {
                    session.loadRestaurants(city: "London")
                }
                .buttonStyle(.borderedProminent)
                if !session.lastRequestDescription.isEmpty {
                    LabeledContent("Request", value: session.lastRequestDescription)
                        .font(.caption.monospaced())
                }
            }

            Section("Resultados") {
                if session.restaurants.isEmpty {
                    Text("Toca Cargar para golpear InMemoryHTTPClient — sin red.")
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
                Section("JSON offline") {
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
                Text("Expand Macro en @AnalyticsEvent en DemoModels.swift — eventName + parameters sintetizados.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Disparar RestaurantOpened") {
                    session.fireAnalyticsDemo()
                }
                .buttonStyle(.borderedProminent)
                Button("Limpiar log", role: .destructive) {
                    session.clearAnalytics()
                }
            }

            Section("Eventos registrados") {
                if session.analyticsLog.isEmpty {
                    Text("Aún no hay eventos — abre un restaurante del paso 1 o toca Disparar.")
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
                Text("Expand Macro en @AutoInit / @MakeBuilder / @Clamped sobre Restaurant y VolumeControl.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Ejecutar demo @AutoInit") {
                    session.runAutoInitDemo()
                }
                .buttonStyle(.borderedProminent)
            }

            if !session.autoInitSample.isEmpty {
                Section("Init memberwise") {
                    Text(session.autoInitSample)
                }
                Section("Peer RestaurantBuilder") {
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
                Text("Expand Macro en @AutoRegister — emite static register(in: DependencyContainer). Debate magia vs composition roots en el escenario.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Resolver MenuRepository") {
                    session.resolveMenuRepository()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Platos destacados") {
                if session.featuredDishes.isEmpty {
                    Text("Aún no resuelto.").foregroundStyle(.secondary)
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
                Text("Cuándo no usar macros")
                    .font(.title2.weight(.bold))

                takeaway("Prefiere una función cuando ahorras ~3 líneas una sola vez.")
                takeaway("Prefiere protocolos o generics para comportamiento polimórfico.")
                takeaway("Prefiere código manual para reglas de negocio y algoritmos complejos.")
                takeaway("Prefiere macros para boilerplate repetitivo y estructural con diagnósticos excelentes.")

                Text("Siempre Expand Macro. Siempre entrega diagnósticos. Siempre conoce la salida de escape.")
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
