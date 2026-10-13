import BeyondBoilerplateMacrosClient
import DemoSupport
import SwiftUI

// MARK: - Basic

// ES: Nivel 1 — qué es una macro, # vs @, demos interactivas.
// EN: Level 1 — what a macro is, # vs @, interactive demos.
struct BasicLevelView: View {
    // ES: Preset elegido para #stringify (evaluado con macros reales).
    // EN: Chosen #stringify preset (evaluated with real macros).
    @State private var stringifyChoice: Int = 0
    @State private var stringifyResult: String = ""
    @State private var urlResult: String = ""
    @State private var dishResult: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A macro is code that writes code at compile time.")
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("# vs @")
                        .font(.headline)
                    Text("# freestanding — a call like #stringify(…)\n@ attached — an attribute like @Describable on a type")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                stringifyCard
                urlCard
                dishCard
            }
            .padding(16)
        }
    }

    private var stringifyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interactive #stringify")
                .font(.headline)
            Text("Pick an expression. The macro returns (value, \"source text\").")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Expression", selection: $stringifyChoice) {
                Text("2 + 3").tag(0)
                Text("21 * 2").tag(1)
                Text("10 - 4").tag(2)
            }
            .pickerStyle(.segmented)

            Button("Run #stringify") {
                runStringify()
            }
            .buttonStyle(.borderedProminent)

            if !stringifyResult.isEmpty {
                ResultBox(text: stringifyResult)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var urlCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interactive #URL")
                .font(.headline)
            Text("Valid URL literals expand at compile time. Typos fail the build.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Build #URL(\"https://swiftleeds.co.uk\")") {
                runURL()
            }
            .buttonStyle(.borderedProminent)

            if !urlResult.isEmpty {
                ResultBox(text: urlResult)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var dishCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("@Describable on Dish")
                .font(.headline)
            Text("Attached macro. Expand Macro on Dish in Examples.swift.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Print Dish description") {
                runDish()
            }
            .buttonStyle(.borderedProminent)

            if !dishResult.isEmpty {
                ResultBox(text: dishResult)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // ES: Cada preset llama a #stringify con una expresión fija (tipado explícito).
    // EN: Each preset calls #stringify with a fixed expression (explicit typing).
    private func runStringify() {
        let value: Int
        let source: String
        if stringifyChoice == 0 {
            let pair: (Int, String) = #stringify(2 + 3)
            value = pair.0
            source = pair.1
        } else if stringifyChoice == 1 {
            let pair: (Int, String) = #stringify(21 * 2)
            value = pair.0
            source = pair.1
        } else {
            let pair: (Int, String) = #stringify(10 - 4)
            value = pair.0
            source = pair.1
        }
        stringifyResult = "(\(value), \"\(source)\")"
    }

    private func runURL() {
        let site: URL = #URL("https://swiftleeds.co.uk")
        urlResult = site.absoluteString
    }

    private func runDish() {
        let dish: Dish = Dish(name: "Casado", price: 8.5)
        dishResult = String(describing: dish)
    }
}

// MARK: - Intermediate

// ES: Nivel 2 — un ejemplo corto por rol: member / peer / accessor / extension.
// EN: Level 2 — one tiny example per role: member / peer / accessor / extension.
struct IntermediateLevelView: View {
    @State private var clampAttempt: Int = 50
    @State private var clampShown: Int = 50
    @State private var builderNote: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Attached roles — one tiny example each")
                    .font(.title3.weight(.semibold))

                BeforeAfterCard(
                    title: "Member · @AutoInit",
                    before: Sample.AutoInit.before,
                    after: Sample.AutoInit.after,
                    expanded: Sample.AutoInit.expanded
                )

                BeforeAfterCard(
                    title: "Peer · @MakeBuilder",
                    before: Sample.MakeBuilder.before,
                    after: Sample.MakeBuilder.after,
                    expanded: Sample.MakeBuilder.expanded
                )

                Button("Build Restaurant with RestaurantBuilder") {
                    runBuilder()
                }
                .buttonStyle(.bordered)
                if !builderNote.isEmpty {
                    ResultBox(text: builderNote)
                }

                BeforeAfterCard(
                    title: "Accessor · @Clamped",
                    before: Sample.Clamped.before,
                    after: Sample.Clamped.after,
                    expanded: Sample.Clamped.expanded
                )

                clampDemo

                BeforeAfterCard(
                    title: "Extension · @AutoEquatable",
                    before: Sample.EquatableExt.before,
                    after: Sample.EquatableExt.after,
                    expanded: Sample.EquatableExt.expanded
                )

                Text("@Observable (Apple) combines member + memberAttribute + extension — same idea as stacking roles.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(16)
        }
    }

    private var clampDemo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try setting 150 — it clamps to 100")
                .font(.subheadline.weight(.semibold))

            // ES: Stepper solo cambia el intento; el botón aplica @Clamped.
            // EN: Stepper only changes the attempt; the button applies @Clamped.
            Stepper(value: $clampAttempt, in: 0...200, step: 25) {
                Text("Attempted value: \(clampAttempt)")
            }

            Button("Apply to @Clamped property") {
                applyClamp()
            }
            .buttonStyle(.borderedProminent)

            ResultBox(text: "Stored percentage: \(clampShown) (max 100)")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func runBuilder() {
        var builder: RestaurantBuilder = RestaurantBuilder()
        builder.id = "r1"
        builder.name = "Soda Tapia"
        builder.city = "San José"
        builder.rating = 4.8
        let restaurant: Restaurant = builder.build()
        builderNote = "Built: \(restaurant.name) · \(restaurant.city)"
    }

    private func applyClamp() {
        var volume: VolumeControl = VolumeControl()
        // ES: Si intentas 150, @Clamped guarda 100.
        // EN: If you try 150, @Clamped stores 100.
        volume.percentage = clampAttempt
        clampShown = volume.percentage
    }
}

// MARK: - Advanced

// ES: Nivel 3 — casos reales, @Endpoint en vivo, diagnósticos, 4 beneficios.
// EN: Level 3 — real-world cases, live @Endpoint, diagnostics, 4 benefits.
struct AdvancedLevelView: View {
    @State private var endpointResult: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Real-world macros you already use")
                    .font(.title3.weight(.semibold))

                realWorldList

                BeforeAfterCard(
                    title: "@Endpoint (attached + method/path args)",
                    before: Sample.Endpoint.before,
                    after: Sample.Endpoint.after,
                    expanded: Sample.Endpoint.expanded
                )

                Button("Live offline @Endpoint call") {
                    runEndpoint()
                }
                .buttonStyle(.borderedProminent)

                if !endpointResult.isEmpty {
                    ResultBox(text: endpointResult)
                }

                diagnosticCard

                benefitsCard
            }
            .padding(16)
        }
    }

    private var realWorldList: some View {
        VStack(alignment: .leading, spacing: 8) {
            benefitRow(name: "@Observable", detail: "UI updates without ObservableObject boilerplate")
            benefitRow(name: "#Preview", detail: "Canvas previews from a freestanding macro")
            benefitRow(name: "@Model (SwiftData)", detail: "Persistence schema from your types")
            benefitRow(name: "@Test / #expect", detail: "Swift Testing without XCTest ceremony")
            benefitRow(name: "@Reducer (TCA)", detail: "Feature modules with less glue code")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func benefitRow(name: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var diagnosticCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics — misuse fails the build")
                .font(.headline)
            Text("Wrong usage cannot compile, so we show the message as text:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Sample.diagnosticEmptyPath)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.red)
            Text(Sample.diagnosticBadURL)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4 benefits")
                .font(.headline)
            Text("1. Less code to write and review")
                .font(.body)
            Text("2. Generated code never drifts out of date")
                .font(.body)
            Text("3. Bad config fails at compile time")
                .font(.body)
            Text("4. Zero runtime cost (some build-time cost)")
                .font(.body)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func runEndpoint() {
        let endpoint: GetRestaurants = GetRestaurants(city: "San José", limit: 3)
        let request: String = endpoint.requestDescription

        let client: InMemoryHTTPClient = InMemoryHTTPClient()
        var statusLine: String = "no response"
        do {
            let stub: InMemoryHTTPClient.StubResponse = try InMemoryHTTPClient.StubResponse(
                jsonObject: ["ok": true]
            )
            client.stub(GetRestaurants.endpointID, response: stub)
            let response: InMemoryHTTPClient.StubResponse = try client.send(endpoint)
            statusLine = "HTTP \(response.statusCode)"
        } catch {
            statusLine = "error"
        }

        endpointResult = "\(request)\n\(statusLine)"
    }
}
