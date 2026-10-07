import SwiftOmniUI

/// `.commands` on a scene - menus of the application's own on the platform's
/// menu surface, whichever page shows.
struct CommandsSample: SampleContent, ExampleContent {
    static let id = "commands"
    static let title = "Commands"
    static let summary = "Menus the scene declares once - a CommandMenu of its own, or entries spliced into the platform's."

    /// Listed where a menu bar exists to look at.
    static let formFactors: Set<FormFactor> = [.desktop]

    static let code = """
        // On the SCENE, not a page: a CommandMenu stands whichever window is
        // in front, and its entries are views - a Button is a menu item, its
        // .keyboardShortcut shown beside it.
        var windows: Windows {
            Windows {
                WindowGroup(.debugInspector) { DebugInspector() }
            } main: {
                MainWindow()
            }
            .commands {
                CommandMenu("Gallery") {
                    Button("Home", action: { nav.home() })
                        .keyboardShortcut("h", modifiers: [.command, .shift])
                }
            }
        }

        // A CommandGroup splices entries into a region the platform already
        // has - .appInfo is where "About" lives.
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Gallery") { showAbout() }
            }
        }
        """

    var body: some View {
        VStack {
            // The real thing is above this window: the "Gallery" menu in the
            // menu bar holds a Home item the scene declared once. This row
            // sketches it for devices whose menu bar is another shape.
            HStack {
                Text("Gallery")
                    .font(.system(size: 13))
                    .padding(EdgeInsets(10, 4))
                Text("Home  ⇧⌘H")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.subtle)
                    .padding(EdgeInsets(10, 4))
            }
            .style("Card")
            .shape(.roundedRectangle(8))
        }
        .spacing(10)
    }

    var notes: (any View)? {
        VStack {
            Text("This gallery really declares one - look at the menu bar: "
                + "the Gallery menu's Home item is a `CommandMenu` in this "
                + "scene's `.commands` block, and ⇧⌘H goes home from any page "
                + "in any of the app's windows.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("A `CommandGroup(replacing:)` is the other half: it splices "
                + "entries into a region the platform already has - `.appInfo` "
                + "for About, `.newItem` beside New - so the app stands inside "
                + "the platform's own menus rather than only beside them.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }
}
