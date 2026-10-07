import SwiftOmniUI

/// The opening page: a text entry and counter shared by every host.
///
/// A page is a value rebuilt on every render, and the `@State` on it survives
/// that - which is the whole of what makes the counter below work.
struct MainPage: View {
    /// The page as it runs - what it is called, and the rest of what it
    /// says about itself.
    @Environment private var page: PageSession

    @State private var count = 0
    @State private var name = ""

    var body: some View {
        VStack {
            Image("swiftomniui_tile.png")
                .frame(height: 120)
                .horizontalAlignment(.center)

            Text(name.isEmpty ? "Hello, SwiftOmniUI!" : "Hello, \(name)!")
                .font(.system(size: 28))
                .bold()
                .horizontalAlignment(.center)

            TextField("Type your name", text: $name)
                .frame(width: 240)

            Button(count == 0 ? "Click me" : "Clicked \(count) time\(count == 1 ? "" : "s")") {
                count += 1
            }
            .horizontalAlignment(.center)
            .padding(20)
        }
        .spacing(16)
        .verticalAlignment(.center)
        .padding(30)
        .onAppear { page.title = "HelloWorld" }
    }
}
