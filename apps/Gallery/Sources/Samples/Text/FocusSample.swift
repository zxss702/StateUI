import SwiftOmniUI

/// `@FocusState`, `.focused` and `.defaultFocus`: where the keyboard starts,
/// and where it moves.
struct FocusSample: SampleContent, ExampleContent {
    @State private var name = ""
    @State private var email = ""

    /// Which field holds the focus - `defaultFocus` claims `name` to start.
    @FocusState private var focused: Field?

    /// The fields focus can move between.
    private enum Field: Hashable {
        case name, email
    }

    static let id = "focus"
    static let title = "Keyboard focus"
    static let summary = "FocusState drives the caret; defaultFocus names where it opens."

    static let code = """
        @State private var name = ""
        @State private var email = ""
        @FocusState private var focused: Field?

        private enum Field: Hashable {
            case name, email
        }

        VStack {
            TextField("Name", text: $name)
                .focused($focused, equals: .name)
                .defaultFocus($focused, .name)

            TextField("Email", text: $email)
                .focused($focused, equals: .email)

            Button("Move to email", action: { focused = .email })
        }
        """

    var notes: (any View)? {
        VStack {
            Text("`.defaultFocus($focused, .name)` claims the focus for Name "
                + "when the page stands, unless the user already focused "
                + "something. Writing `focused = .email` moves it; a tap into a "
                + "field writes the same state back.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }

    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .focused($focused, equals: .name)
                .defaultFocus($focused, .name)
                .accessibilityIdentifier("focus.name")

            TextField("Email", text: $email)
                .focused($focused, equals: .email)
                .accessibilityIdentifier("focus.email")

            HStack {
                Button("Focus name", action: { focused = .name })
                Button("Focus email", action: { focused = .email })
            }
            .spacing(10)

            Text("Focus: \(focused == .name ? "name" : focused == .email ? "email" : "none")")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Palette.accent)
        }
        .spacing(12)
    }
}
