// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
@testable import StateUIGTK
import XCTest

/// A `LazyVStack` on GTK answers the same window questions as everywhere:
/// the rows the scroller's reach holds are mounted, and no more.
final class GTKLazyTests: XCTestCase {
    /// Of a thousand rows a window's worth are built, and no more.
    func testOnlyTheWindowedRowsAreBuilt() throws {
        try onUIThread {
            let host = GTKRenderer.running { LazyRowsPage() }
            host.settle { host.views(GTKLabelView.self).count > 4 }

            XCTAssertLessThan(host.views(GTKLabelView.self).count, 60, "a window's reach of a thousand rows")
        }
    }

    /// Scrolling asks the rows the window moved to be built, and lets the
    /// ones it left go.
    func testScrollingBuildsAheadAndLetsGoBehind() throws {
        try onUIThread {
            let host = GTKRenderer.running { LazyRowsPage() }
            let scroll = try XCTUnwrap(host.views(GTKScrollView.self).first)
            host.settle { host.views(GTKLabelView.self).contains { $0.text == "Row 0" } }

            scroll.scroller.move(to: Point(0, 20_000))
            host.settle { host.views(GTKLabelView.self).contains { $0.text == "Row 500" } }

            let standing = host.views(GTKLabelView.self).map(\.text)
            XCTAssertFalse(standing.contains("Row 0"), "the first row was let go")
            XCTAssertLessThan(standing.count, 150, "still a window's reach")
        }
    }

    /// The room is the run's whole length before most of its rows exist.
    func testTheScrollRoomIsTheWholeRunAtOnce() throws {
        try onUIThread {
            let host = GTKRenderer.running { LazyRowsPage() }
            host.settle { host.views(GTKLabelView.self).count > 4 }

            // A thousand forty-point rows: the lazy view's height is their run.
            let lazy = try XCTUnwrap(host.views(GTKLazyStackView.self).first)
            XCTAssertEqual(lazy.frame.height, 40_000, accuracy: 4_000)
        }
    }

    /// Outside a scroller there is no window to narrow by: every child is
    /// built, as a plain stack's would be.
    func testALazyStackWithNoScrollerBuildsAll() throws {
        try onUIThread {
            let host = GTKRenderer.running { LazyRowsPage(count: 30, scrolls: false) }
            host.settle { host.views(GTKLabelView.self).count == 30 }

            XCTAssertEqual(host.views(GTKLabelView.self).count, 30)
        }
    }
}

/// A thousand forty-point rows in a scroller - or thirty, where it does not
/// scroll.
private struct LazyRowsPage: View {
    var count = 1_000
    var scrolls = true

    var body: some View {
        if scrolls {
            ScrollView {
                LazyVStack {
                    ForEach(0..<count) { row in
                        Text("Row \(row)").frame(height: 40)
                    }
                }
            }
        } else {
            LazyVStack {
                ForEach(0..<count) { row in
                    Text("Row \(row)").frame(height: 40)
                }
            }
        }
    }
}
