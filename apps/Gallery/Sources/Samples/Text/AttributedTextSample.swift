import Foundation
import StateUI
import StateUIFoundation

/// `Text(AttributedString)`: runs keep the look the string wrote for them.
struct AttributedTextSample: SampleContent, ExampleContent {
    static let id = "attributed-text"
    static let title = "Attributed text"
    static let summary = "An AttributedString's runs shown with each run's own look."

    static let code = """
        let words = try? AttributedString(
            markdown: "**Bold** words, _italic_ ones, ~~struck~~ ones and `code`.")

        Text(words ?? AttributedString("plain"))
        """

    var notes: (any View)? {
        VStack {
            Text("Markdown's **bold**, _italic_, ~~strike~~ and `code` arrive as "
                + "presentation intents on Apple's platforms; the free-standing "
                + "Foundation carries a string's runs and its link attribute.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }

    var body: some View {
        VStack {
            Text(Self.rich ?? AttributedString("plain text"))
                .font(.system(size: 16))
        }
        .spacing(12)
    }

    /// The attributed string the page draws. A markdown parse is Apple's
    /// Foundation scope; the free-standing Foundation names the link
    /// attribute alone, so there the runs are composed instead - what the
    /// sample shows either way is runs keeping the look the string wrote.
    private static var rich: AttributedString? {
        #if canImport(AppKit) || canImport(UIKit)
        return try? AttributedString(
            markdown: "**StateUI** shows _attributed_ runs - "
                + "~~crossed out~~ words and `code` too.")
        #else
        var link = AttributeContainer()
        link.link = URL(string: "https://stateui.dev")
        return AttributedString("StateUI shows attributed runs - ")
            + AttributedString("a link", attributes: link)
            + AttributedString(" beside plain words.")
        #endif
    }
}
