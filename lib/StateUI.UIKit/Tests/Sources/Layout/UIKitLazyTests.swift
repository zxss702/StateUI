// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import UIKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
@testable import StateUIUIKit
import XCTest

/// A `LazyVStack` on UIKit answers the same window questions as everywhere:
/// the rows the scroller's reach holds are mounted, and no more.
final class UIKitLazyTests: XCTestCase {
    /// Of a thousand rows a window's worth are built, and no more.
    @MainActor
    func testOnlyTheWindowedRowsAreBuilt() throws {
        let host = UIKitRenderer.running { LazyRowsPage() }
        defer { host.finish() }
        host.settle { host.views(UIKitLabelView.self).count > 4 }

        XCTAssertLessThan(host.views(UIKitLabelView.self).count, 300, "a window's reach of a thousand rows")
    }

    /// Scrolling asks the rows the window moved to be built, and lets the
    /// ones it left go.
    @MainActor
    func testScrollingBuildsAheadAndLetsGoBehind() throws {
        let host = UIKitRenderer.running { LazyRowsPage() }
        defer { host.finish() }
        let scroll = try XCTUnwrap(host.views(UIKitScrollView.self).first)
        host.settle { host.views(UIKitLabelView.self).contains { $0.text == "Row 0" } }

        scroll.scroller.contentOffset = CGPoint(x: 0, y: 20_000)
        host.settle { host.views(UIKitLabelView.self).contains { $0.text == "Row 500" } }

        let standing = host.views(UIKitLabelView.self).compactMap(\.text)
        XCTAssertFalse(standing.contains("Row 0"), "the first row was let go")
        XCTAssertLessThan(standing.count, 400, "still a window's reach")
    }

    /// The room is the run's whole length before most of its rows exist.
    @MainActor
    func testTheScrollRoomIsTheWholeRunAtOnce() throws {
        let host = UIKitRenderer.running { LazyRowsPage() }
        defer { host.finish() }
        let scroll = try XCTUnwrap(host.views(UIKitScrollView.self).first)
        host.settle { scroll.scroller.contentSize.height > 1_000 }

        // A thousand forty-point rows: the document's height is their run.
        XCTAssertEqual(scroll.scroller.contentSize.height, 40_000, accuracy: 4_000)
    }

    /// Outside a scroller there is no window to narrow by: every child is
    /// built, as a plain stack's would be.
    @MainActor
    func testALazyStackWithNoScrollerBuildsAll() throws {
        let host = UIKitRenderer.running { LazyRowsPage(count: 30, scrolls: false) }
        defer { host.finish() }
        host.settle { host.views(UIKitLabelView.self).count == 30 }

        XCTAssertEqual(host.views(UIKitLabelView.self).count, 30)
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
