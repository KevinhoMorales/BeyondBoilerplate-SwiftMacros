import SwiftUI

// ES: Contenedor con un control segmentado: Basic / Intermediate / Advanced.
// EN: Shell with a segmented control: Basic / Intermediate / Advanced.
struct ContentView: View {
    // ES: Nivel seleccionado (0=Basic, 1=Intermediate, 2=Advanced).
    // EN: Selected level (0=Basic, 1=Intermediate, 2=Advanced).
    @State private var level: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Level", selection: $level) {
                    Text("Basic").tag(0)
                    Text("Intermediate").tag(1)
                    Text("Advanced").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // ES: Una sola sección visible a la vez (corta y clara).
                // EN: Only one section visible at a time (short and clear).
                Group {
                    if level == 0 {
                        BasicLevelView()
                    } else if level == 1 {
                        IntermediateLevelView()
                    } else {
                        AdvancedLevelView()
                    }
                }
            }
            .navigationTitle("Beyond Boilerplate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ES: Bloque reutilizable Before / After / Expanded con un toggle.
// EN: Reusable Before / After / Expanded block with a toggle.
struct BeforeAfterCard: View {
    let title: String
    let before: String
    let after: String
    let expanded: String

    // ES: 0 = Before, 1 = After, 2 = Expanded.
    // EN: 0 = Before, 1 = After, 2 = Expanded.
    @State private var mode: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Picker("Mode", selection: $mode) {
                Text("Before").tag(0)
                Text("After").tag(1)
                Text("Expanded").tag(2)
            }
            .pickerStyle(.segmented)

            Text(codeForMode)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var codeForMode: String {
        if mode == 0 {
            return before
        }
        if mode == 1 {
            return after
        }
        return expanded
    }
}

struct ResultBox: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
