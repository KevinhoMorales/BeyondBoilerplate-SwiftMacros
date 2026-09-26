import SwiftUI

// MARK: - Shared teaching chrome

enum MacroSide: String, CaseIterable, Identifiable {
    case without
    case with

    var id: String { rawValue }

    var label: String {
        switch self {
        case .without: "Sin macro"
        case .with: "Con macro"
        }
    }
}

struct StepIntroCard: View {
    let eyebrow: String
    let title: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(DemoTheme.accent)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(DemoTheme.ink)
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    DemoTheme.surface,
                    Color(red: 0.93, green: 0.95, blue: 0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

struct TeachingCaption: View {
    let whatYouSee: String
    let whyItHelps: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            captionBlock(
                icon: "eye",
                title: "Qué estás viendo",
                body: whatYouSee
            )
            captionBlock(
                icon: "lightbulb",
                title: "Por qué ayuda el macro",
                body: whyItHelps
            )
        }
    }

    private func captionBlock(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DemoTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DemoTheme.ink)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CodeBlockView: View {
    let title: String
    let code: String
    var highlight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(highlight ? DemoTheme.accent : .secondary)
                Spacer(minLength: 0)
                Text("Swift")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DemoTheme.ink)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        highlight ? DemoTheme.accent.opacity(0.45) : Color.black.opacity(0.06),
                        lineWidth: highlight ? 1.5 : 1
                    )
            )
        }
    }
}

/// Segmented Sin macro / Con macro with sample source + teaching captions.
struct MacroContrastSection: View {
    let withoutTitle: String
    let withoutCode: String
    let withTitle: String
    let withCode: String
    let whatYouSee: String
    let whyItHelps: String
    @Binding var side: MacroSide

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Comparar", selection: $side) {
                ForEach(MacroSide.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch side {
                case .without:
                    CodeBlockView(
                        title: withoutTitle,
                        code: withoutCode,
                        highlight: false
                    )
                case .with:
                    CodeBlockView(
                        title: withTitle,
                        code: withCode,
                        highlight: true
                    )
                }
            }
            .animation(.easeInOut(duration: 0.22), value: side)

            TeachingCaption(whatYouSee: whatYouSee, whyItHelps: whyItHelps)
        }
    }
}

// MARK: - Steps

struct WelcomeStepView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beyond Boilerplate")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(DemoTheme.ink)

                    Text("Macros Swift listas para producción")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DemoTheme.accent)

                    Text(
                        "Recorrido progresivo para DevFest 2026: cada paso muestra el mismo concepto "
                            + "sin macro y con macro, luego ejecuta el camino real (macros en DemoModels.swift)."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    labelRow(
                        icon: "rectangle.split.2x1",
                        title: "Sin macro / Con macro",
                        detail: "Código de ejemplo en pantalla — el WOW es @Endpoint."
                    )
                    labelRow(
                        icon: "hammer",
                        title: "Expand Macro",
                        detail: "DemoModels.swift — @Endpoint, @AnalyticsEvent, @AutoInit…"
                    )
                    labelRow(
                        icon: "iphone",
                        title: "Ejecutar",
                        detail: "Scheme BeyondBoilerplateDemo · Simulator iOS 17+"
                    )
                    labelRow(
                        icon: "terminal",
                        title: "Gemelo CLI",
                        detail: "swift run DemoCLI — mismos macros, ruta de terminal"
                    )
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Empieza por el paso 1 · @Endpoint — ahí se ve la diferencia de un vistazo.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(DemoTheme.accent)
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), DemoTheme.surface.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
    @State private var side: MacroSide = .without

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepIntroCard(
                    eyebrow: "Paso 1 · WOW",
                    title: "@Endpoint",
                    caption: "El mismo endpoint de networking: boilerplate manual frente a una anotación. "
                        + "Luego pulsa Cargar para ver InMemoryHTTPClient (sin red)."
                )

                MacroContrastSection(
                    withoutTitle: "Lo que escribes a mano",
                    withoutCode: DemoCodeSamples.Endpoint.withoutMacro,
                    withTitle: "Lo que escribes con @Endpoint",
                    withCode: DemoCodeSamples.Endpoint.withMacro,
                    whatYouSee: DemoCodeSamples.Endpoint.whatYouSee,
                    whyItHelps: DemoCodeSamples.Endpoint.whyItHelps,
                    side: $side
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Ruta con macros (en vivo)")
                        .font(.headline)
                    Text(
                        "GetRestaurants en DemoModels.swift ya usa @Endpoint. "
                            + "En Xcode: clic en @Endpoint → Editor → Expand Macro."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Button("Cargar restaurantes (San José)") {
                        session.loadRestaurants(city: "San José")
                    }
                    .buttonStyle(.borderedProminent)

                    if !session.lastRequestDescription.isEmpty {
                        LabeledContent("Request", value: session.lastRequestDescription)
                            .font(.caption.monospaced())
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                resultsBlock

                if !session.lastResponsePretty.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JSON offline")
                            .font(.headline)
                        Text(session.lastResponsePretty)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.97))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var resultsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados")
                .font(.headline)

            if session.restaurants.isEmpty {
                Text("Pulsa Cargar para golpear InMemoryHTTPClient — sin red.")
                    .font(.subheadline)
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
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundStyle(.primary)
                    if restaurant.id != session.restaurants.last?.id {
                        Divider()
                    }
                }
                Text("Toca un restaurante para disparar @AnalyticsEvent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AnalyticsStepView: View {
    @Bindable var session: DemoSession
    @State private var side: MacroSide = .without

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepIntroCard(
                    eyebrow: "Paso 2",
                    title: "@AnalyticsEvent",
                    caption: "Eventos tipados sin diccionarios a mano ni SDK de terceros — solo un sink en memoria."
                )

                MacroContrastSection(
                    withoutTitle: "Lo que escribes a mano",
                    withoutCode: DemoCodeSamples.Analytics.withoutMacro,
                    withTitle: "Lo que escribes con @AnalyticsEvent",
                    withCode: DemoCodeSamples.Analytics.withMacro,
                    whatYouSee: DemoCodeSamples.Analytics.whatYouSee,
                    whyItHelps: DemoCodeSamples.Analytics.whyItHelps,
                    side: $side
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Disparar evento real")
                        .font(.headline)
                    Text("RestaurantOpened en DemoModels.swift — Expand Macro para ver eventName + parameters.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button("Disparar RestaurantOpened") {
                            session.fireAnalyticsDemo()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Limpiar registro", role: .destructive) {
                            session.clearAnalytics()
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Eventos registrados")
                        .font(.headline)
                    if session.analyticsLog.isEmpty {
                        Text("Aún no hay eventos — abre un restaurante en el paso 1 o pulsa Disparar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(session.analyticsLog.enumerated()), id: \.offset) { _, entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.name).font(.subheadline.weight(.semibold))
                                Text(entry.detail)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }
}

struct AutoInitStepView: View {
    @Bindable var session: DemoSession
    @State private var side: MacroSide = .without

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepIntroCard(
                    eyebrow: "Paso 3",
                    title: "@AutoInit · @MakeBuilder · @Clamped",
                    caption: "Init memberwise y peers sintetizados en compilación. "
                        + "Expand Macro sobre Restaurant y VolumeControl en DemoModels.swift."
                )

                MacroContrastSection(
                    withoutTitle: "Init a mano (se rompe al añadir props)",
                    withoutCode: DemoCodeSamples.AutoInit.withoutMacro,
                    withTitle: "Con @AutoInit + peers",
                    withCode: DemoCodeSamples.AutoInit.withMacro,
                    whatYouSee: DemoCodeSamples.AutoInit.whatYouSee,
                    whyItHelps: DemoCodeSamples.AutoInit.whyItHelps,
                    side: $side
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Ejercer macros en vivo")
                        .font(.headline)
                    Button("Ejecutar demo @AutoInit") {
                        session.runAutoInitDemo()
                    }
                    .buttonStyle(.borderedProminent)

                    if !session.autoInitSample.isEmpty {
                        resultRow(title: "Init memberwise", value: session.autoInitSample)
                        resultRow(title: "RestaurantBuilder (peer)", value: session.builderSample)
                        resultRow(title: "@Clamped", value: session.clampNote)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }

    private func resultRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospaced())
        }
        .padding(.top, 4)
    }
}

struct DIStepView: View {
    @Bindable var session: DemoSession
    @State private var side: MacroSide = .without

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepIntroCard(
                    eyebrow: "Paso 4 · debate",
                    title: "@AutoRegister",
                    caption: "DI educativa: el macro emite register(in:), pero el composition root sigue siendo explícito. "
                        + "Habla en escenario de magia vs roots claros."
                )

                MacroContrastSection(
                    withoutTitle: "Registro 100% manual",
                    withoutCode: DemoCodeSamples.AutoRegister.withoutMacro,
                    withTitle: "Con @AutoRegister",
                    withCode: DemoCodeSamples.AutoRegister.withMacro,
                    whatYouSee: DemoCodeSamples.AutoRegister.whatYouSee,
                    whyItHelps: DemoCodeSamples.AutoRegister.whyItHelps,
                    side: $side
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Resolver desde el container")
                        .font(.headline)
                    Text("MenuRepository.register(in:) ya se llamó al arrancar. Expand Macro sobre @AutoRegister.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Resolver MenuRepository") {
                        session.resolveMenuRepository()
                    }
                    .buttonStyle(.borderedProminent)

                    if session.featuredDishes.isEmpty {
                        Text("Aún no resuelto.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Platos destacados")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                        ForEach(session.featuredDishes, id: \.self) { dish in
                            Text("· \(dish)")
                                .font(.body)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DemoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }
}

struct TakeawayStepView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cuándo no usar macros")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DemoTheme.ink)

                Text(
                    "Los macros borran boilerplate estructural — no reglas de negocio. "
                        + "Cierra la charla con esta checklist."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                takeaway("Prefiere una función cuando ahorras ~3 líneas una sola vez.")
                takeaway("Prefiere protocolos o generics para comportamiento polimórfico.")
                takeaway("Prefiere código manual para reglas de negocio y algoritmos complejos.")
                takeaway("Prefiere macros para boilerplate estructural repetitivo con diagnósticos excelentes.")

                Text("Siempre Expand Macro. Siempre diagnósticos. Siempre conoce la vía de escape.")
                    .font(.callout.weight(.semibold))
                    .padding(.top, 8)
                    .foregroundStyle(DemoTheme.accent)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), DemoTheme.surface.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func takeaway(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DemoTheme.accent)
            Text(text).font(.body)
        }
    }
}
