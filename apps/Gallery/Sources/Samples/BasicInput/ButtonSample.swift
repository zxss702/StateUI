import StateUI

/// A button wired to a click, beside an outlined one and a disabled one.
struct ButtonSample: SampleContent, ExampleContent {
    @State private var counter = 0

    static let id = "button"
    static let title = "Button"
    static let summary = "A tappable button wired to a click, with an outlined "
        + "and a disabled one beside it."

    static let code = """
        @State private var counter = 0

        VStack {
            // The count is read here, so a click builds this closure again.
            DebugInfoLabel()

            Button("Increment")
                .onClicked { counter += 1 }

            Text("Clicked \\(counter) time(s)")

            Button("Outlined")
                .background(.transparent)
                .stroke(Palette.accent)
                .strokeWidth(1)
                .onClicked { counter += 1 }

            Button("Disabled")
                .disabled(true)
        }
        """

    var body: some View {
        VStack {
            DebugInfoLabel()

            Button("Increment")
                .background(Palette.accent)
                .foregroundStyle(.white)
                .shape(.roundedRectangle(8))
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
                .onClicked { counter += 1 }

            Text("Clicked \(counter) time(s)")
                .fontSize(15)
                .multilineTextAlignment(.center)

            Button("Outlined")
                .background(.transparent)
                .foregroundStyle(Palette.accent)
                .stroke(Palette.accent)
                .strokeWidth(1)
                .shape(.roundedRectangle(8))
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
                .onClicked { counter += 1 }

            Button("Disabled")
                .disabled(true)
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
        }
        .spacing(12)
    }

    var notes: (any View)? {
        Text("Also `.onPressed` and `.onReleased`, for the moment the button goes "
            + "down and comes up.")
            .fontSize(12)
            .foregroundStyle(Palette.subtle)
    }
}
