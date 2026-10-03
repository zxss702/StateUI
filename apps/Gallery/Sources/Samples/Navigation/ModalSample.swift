import StateUI

/// A native modal stack owned by application state.
struct ModalSample: SampleContent, ExampleContent {
    let nav: Navigation
    @State private var sheeted = false

    static let id = "modal"
    static let title = "Presenting over everything"
    static let summary = "One array drives the platform's native modal stack."

    static let code = """
        enum Sheet: Hashable {
            case settings
        }

        struct MainWindow: WindowScene {
            @State private var sheets: [Sheet] = []

            var page: any Page {
                HomePage(sheets: $sheets)
            }
        }

        struct HomePage: View {
            @Environment private var window: WindowSession
            @Binding var sheets: [Sheet]

            var body: some View {
                VStack {
                    DebugInfoLabel()

                    Button("Present", action: { sheets.append(.settings) })
                        
                        .onAppear {
                            window.modalStack = ModalStack($sheets) { _ in
                                SettingsPage(sheets: $sheets)
                            }
                        }
                }
            }
        }

        struct SettingsPage: View {
            @Binding var sheets: [Sheet]

            var body: some View {
                Button("Close", action: { sheets.removeLast() })
                    
            }
        }
        """

    var notes: (any View)? { nil }

    var body: some View {
        VStack {
            DebugInfoLabel()

            Button("Present native modal", action: { nav.present(.page) })
                .accessibilityIdentifier("modal.present")
                .background(Palette.accent)
                .foregroundStyle(.white)
                .shape(.roundedRectangle(8))
                .contentPadding(EdgeInsets(20, 10))
                .horizontalAlignment(.center)
                

            Text(nav.sheets.isEmpty ? "Nothing presented" : "Depth: \(nav.sheets.count)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Palette.accent)

            // `.sheet` presents over the window while `isPresented` holds, and
            // dismissing the sheet writes the binding back to false.
            Button("Present .sheet", action: { sheeted = true })
                .help("The SwiftUI-style presentation modifier.")
                .sheet(isPresented: $sheeted) {
                    VStack {
                        Text("A presented sheet")
                            .font(.system(size: 15))
                        Button("Dismiss", action: { sheeted = false })
                    }
                    .spacing(16)
                    .contentPadding(EdgeInsets(40, 60))
                    .background(Palette.raised)
                }
        }
        .spacing(12)
    }
}
