// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
#if canImport(AppKit)
import AppKit
#endif
@testable import StateUIFoundation
import StateUI

struct FoundationSurfaceTests {
    /// An attributed string's runs land as spans, one per run, in order.
    @Test func attributedTextBecomesSpans() throws {
        #if canImport(AppKit)
        let words = NSMutableAttributedString(string: "hello world")
        words.addAttribute(
            .foregroundColor, value: NSColor.red, range: NSRange(location: 0, length: 5))

        let node = Text(AttributedString(words)).node
        let spans = try #require(node.children.first { $0.type == "Spans" })

        #expect(spans.children.count == 2, "two attributes, two runs")
        #else
        let node = Text(AttributedString("plain")).node
        let spans = try #require(node.children.first { $0.type == "Spans" })
        #expect(spans.children.count == 1)
        #endif
    }

    /// A timeline view stands as a composed node.
    @Test func timelineViewBuilds() {
        let view = TimelineView(.animation(minimumInterval: 1.0 / 30)) { context -> TupleView in
            Text("\(context.date.timeIntervalSince1970 > 0)")
        }
        _ = view.node
    }

    /// `.onOpenURL` writes the SwiftUI spelling onto a view.
    @Test func openURLModifierApplies() {
        struct Page: View {
            var body: some View {
                Text("page")
                    .onOpenURL { url in _ = url.isFileURL }
            }
        }

        _ = Page().node
    }
}
