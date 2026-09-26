import SwiftUI

@main
struct BeyondBoilerplateDemoApp: App {
    @State private var session = DemoSession()

    var body: some Scene {
        WindowGroup {
            DemoRootView(session: session)
        }
    }
}
