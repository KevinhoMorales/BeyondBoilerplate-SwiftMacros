import SwiftUI

struct DemoRootView: View {
    @Bindable var session: DemoSession
    @State private var selection: DemoSession.Step? = .welcome

    var body: some View {
        NavigationSplitView {
            List(DemoSession.Step.allCases, selection: $selection) { step in
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline)
                    Text(step.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .tag(step)
            }
            .navigationTitle("Beyond Boilerplate")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            Group {
                if let selection {
                    stepView(for: selection)
                        .navigationTitle(selection.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear { session.onAppear(step: selection) }
                } else {
                    ContentUnavailableView(
                        "Pick a demo step",
                        systemImage: "sparkles",
                        description: Text("Start with Welcome, then walk @Endpoint → analytics → DI.")
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                statusBar
            }
        }
        .tint(DemoTheme.accent)
    }

    @ViewBuilder
    private func stepView(for step: DemoSession.Step) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
        case .restaurants:
            RestaurantsStepView(session: session)
        case .analytics:
            AnalyticsStepView(session: session)
        case .autoInit:
            AutoInitStepView(session: session)
        case .dependencyInjection:
            DIStepView(session: session)
        case .takeaway:
            TakeawayStepView()
        }
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .foregroundStyle(DemoTheme.accent)
            Text(session.statusMessage)
                .font(.footnote.weight(.medium))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

enum DemoTheme {
    static let accent = Color(red: 0.10, green: 0.42, blue: 0.48)
    static let surface = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.18)
}

#Preview {
    DemoRootView(session: DemoSession())
}
