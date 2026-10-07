import Foundation
import SwiftOmniUI
import SwiftOmniUIFoundation

/// `TimelineView`: a view rebuilt on a schedule, each build handed its moment.
struct TimelineViewSample: SampleContent, ExampleContent {
    /// When the page's clock began - the display is elapsed seconds.
    @State private var started = Date()

    static let id = "timeline-view"
    static let title = "TimelineView"
    static let summary = "A view rebuilt on a schedule, handed the current date."

    static let code = """
        @State private var started = Date()

        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let seconds = context.date.timeIntervalSince(started)
            let tenths = Int(seconds * 10)
            VStack {
                Text("\\(tenths / 10).\\(tenths % 10)s")
                ProgressView(seconds.truncatingRemainder(dividingBy: 10) / 10)
            }
        }
        """

    var notes: (any View)? {
        VStack {
            Text("The schedule `.animation(minimumInterval:)` rebuilds the "
                + "content at the display's pace - the ticker behind it is "
                + "started while the view stands and stopped on disappear, so "
                + "a page left alone costs nothing.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("Each rebuild is handed `context.date` - the same moment the "
                + "whole build stands at, however long it takes.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let seconds = context.date.timeIntervalSince(started)
            let tenths = Int(seconds * 10)

            VStack {
                Text("\(tenths / 10).\(tenths % 10) seconds on this page")
                    .font(.system(size: 20, design: .monospaced))

                ProgressView(seconds.truncatingRemainder(dividingBy: 10) / 10)

                Button("Restart", action: { started = Date() })
                    .font(.system(size: 13))
            }
            .spacing(10)
        }
        .accessibilityIdentifier("timeline.view")
    }
}
