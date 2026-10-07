import SwiftOmniUI

/// `@AppStorage` - a value kept in the platform's settings store under a key,
/// lent to the view as an ordinary property and its bindings.
struct AppStorageSample: SampleContent, ExampleContent {
    /// Kept counts and words, spelled the SwiftUI way: the key is a string
    /// beside the default, and a write reaches the store with nothing awaited.
    @AppStorage("gallery.appstorage.count") private var count = 0.0
    @AppStorage("gallery.appstorage.who") private var who = ""
    @AppStorage("gallery.appstorage.loud") private var loud = false

    static let id = "appStorage"
    static let title = "AppStorage"
    static let summary = "A property wrapper that reads and writes the platform's settings store."

    static let code = """
        @AppStorage("gallery.appstorage.count") private var count = 0.0
        @AppStorage("gallery.appstorage.who") private var who = ""
        @AppStorage("gallery.appstorage.loud") private var loud = false

        VStack {
            // `count` is a Double on the surface - the store holds it, the
            // view reads it.
            Stepper($count, in: 0 ... 99)

            Text("count: \\(Int(count))")

            TextField("Your name", text: $who)

            Toggle("Loud", isOn: $loud)
        }
        """

    var body: some View {
        VStack {
            Stepper($count, in: 0 ... 99)
                .accessibilityIdentifier("appstorage.stepper")

            Text("count: \(Int(count))")
                .font(.system(size: 13))

            TextField("Your name", text: $who)

            Toggle("Loud", isOn: $loud)

            if !who.isEmpty {
                Text("Hello, \(loud ? who.uppercased() : who)")
                    .font(.system(size: 13))
                    .foregroundStyle(loud ? Palette.accent : Color.primary)
            }
        }
        .spacing(10)
    }

    var notes: (any View)? {
        VStack {
            Text("`@AppStorage(\"key\")` is `@State` under a name: the value is "
                + "there again the next time the app opens, and a write reaches "
                + "the store by itself. Close the gallery and run it again - "
                + "the count, the name and the toggle are where you left them.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("The projected value is a Binding, so `$count` hands a "
                + "Stepper the means to write it, and `$who` a TextField. The "
                + "store's keys live under `gallery.*` in this app's settings, "
                + "next to the ones the Persistent state sample writes under "
                + "the same mechanism.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }
}
