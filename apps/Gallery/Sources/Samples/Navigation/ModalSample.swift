import StateUI

/// A native modal stack owned by application state.
struct ModalSample: SampleContent, ExampleContent {
    let nav: Navigation

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

                    Button("Present")
                        .onClicked { sheets.append(.settings) }
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
                Button("Close")
                    .onClicked { sheets.removeLast() }
            }
        }
        """

    var notes: (any View)? { nil }

    var body: some View {
        VStack {
            DebugInfoLabel()

            Button("Present native modal")
                .accessibilityIdentifier("modal.present")
                .background(Palette.accent)
                .foregroundStyle(.white)
                .shape(.roundedRectangle(8))
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
                .onClicked { nav.present(.page) }

            Text(nav.sheets.isEmpty ? "Nothing presented" : "Depth: \(nav.sheets.count)")
                .fontSize(13)
                .fontFamily("Menlo")
                .foregroundStyle(Palette.accent)
        }
        .spacing(12)
    }
}
