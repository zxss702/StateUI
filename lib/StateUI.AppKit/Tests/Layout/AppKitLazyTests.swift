// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) @testable import StateUI
@_spi(Host) @testable import StateUIHost
@testable import StateUIAppKit
import StateUIConformance
import XCTest

/// A `LazyVStack` is lazy twice over: it builds a row's own view only for the
/// identities the host's window asked for, and it mounts only those. The
/// window's reach - the visible stretch plus an overscan - is what a thousand
/// rows cost, not the thousand.
final class AppKitLazyTests: XCTestCase {
    /// Of a thousand rows a window's worth are built, and no more.
    @MainActor
    func testOnlyTheWindowedRowsAreBuilt() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyRowsPage(built: built) }
        defer { renderer.closeForTesting() }
        settle(renderer)

        let labels = renderer.nativeViews(AppKitLabelView.self)
        XCTAssertEqual(labels.count, built.rows.count, accuracy: 2)
        XCTAssertLessThan(built.rows.count, 60, "a window's reach of a thousand rows")
        XCTAssertGreaterThan(built.rows.count, 4)
    }

    /// The room is the run's whole length before most of its rows exist: the
    /// estimate carries the unscrolled distance.
    @MainActor
    func testTheScrollRoomIsTheWholeRunAtOnce() throws {
        let renderer = AppKitRenderer.running { LazyRowsPage(built: LazyCounter()) }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroller = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)

        XCTAssertEqual(
            scroller.documentView?.frame.height ?? 0, 40_000,
            accuracy: 2_000, "a thousand forty-point rows, estimated")
    }

    /// Scrolling asks the rows the window moved to be built, and lets the ones
    /// it left go.
    @MainActor
    func testScrollingBuildsAheadAndLetsGoBehind() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyRowsPage(built: built) }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroller = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
        XCTAssertTrue(built.rows.contains(0))

        scroller.contentView.scroll(to: NSPoint(x: 0, y: 20_000))
        scroller.reflectScrolledClipView(scroller.contentView)
        settle(renderer)

        let standing = renderer.nativeViews(AppKitLabelView.self).map(\.stringValue)
        XCTAssertFalse(standing.contains("Row 0"), "the first row was let go")
        XCTAssertTrue(standing.contains("Row 500"), "the row the window moved to was built")
        XCTAssertLessThan(standing.count, 150, "still a window's reach")
    }

    /// Outside a scroller there is no window to narrow by: every child is
    /// built, as a plain stack's would be.
    @MainActor
    func testALazyStackWithNoScrollerBuildsAll() {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running {
            LazyRowsPage(built: built, count: 30, scrolls: false)
        }
        defer { renderer.closeForTesting() }
        settle(renderer)

        XCTAssertEqual(built.rows.count, 30)
    }

    /// A row the window left and came back to is built again under its own
    /// name - the identity is the item's, so the new subtree stands for the
    /// same row.
    @MainActor
    func testARowTheWindowComesBackToStandsAgain() throws {
        let renderer = AppKitRenderer.running { LazyRowsPage(built: LazyCounter()) }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroller = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)

        scroller.contentView.scroll(to: NSPoint(x: 0, y: 20_000))
        scroller.reflectScrolledClipView(scroller.contentView)
        settle(renderer)
        XCTAssertFalse(renderer.nativeViews(AppKitLabelView.self).contains { $0.stringValue == "Row 0" })

        scroller.contentView.scroll(to: NSPoint(x: 0, y: 0))
        scroller.reflectScrolledClipView(scroller.contentView)
        settle(renderer)
        XCTAssertTrue(renderer.nativeViews(AppKitLabelView.self).contains { $0.stringValue == "Row 0" })
    }

    /// Rows of their own heights: the run's room is the sum of them, and a
    /// scroll to a distant point still lands by the rows standing there.
    @MainActor
    func testRowsOfTheirOwnHeights() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyRowsPage(built: built, tallEvery: 10) }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroller = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)

        // A tenth of the rows are 120 long, the rest 40: the run is 48,000.
        XCTAssertEqual(
            scroller.documentView?.frame.height ?? 0, 48_000,
            accuracy: 6_000, "a hundred tall rows among the short ones, estimated")

        // Row 500 is tall: scroll to where the run's own arithmetic stands
        // it - the estimate's answer first, then again to where it moved as
        // the measures landed - until the window holds it.
        let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyStackView.self).first)
        for _ in 0..<4 {
            scroller.contentView.scroll(to: NSPoint(x: 0, y: lazy.cells.offset(of: 500)))
            scroller.reflectScrolledClipView(scroller.contentView)
            settle(renderer, turns: 6)
            let standing = renderer.nativeViews(AppKitLabelView.self).map(\.stringValue)
            if standing.contains("Row 500") { break }
        }
        let standing = renderer.nativeViews(AppKitLabelView.self).map(\.stringValue)
        XCTAssertTrue(standing.contains("Row 500"), "the distant row built under its own name")
        XCTAssertLessThan(standing.count, 150, "still a window's reach")
    }

    /// A lazy stack inside a lazy row narrows by its own window: only the
    /// shelves the outer window reaches mount tiles, and each shelf mounts
    /// only the tiles ITS scroller reaches.
    @MainActor
    func testANestedLazyStackNarrowsByItsOwnWindow() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyShelvesPage(built: built) }
        defer { renderer.closeForTesting() }
        settle(renderer)

        let labels = Set(renderer.nativeViews(AppKitLabelView.self).map(\.stringValue))
        XCTAssertTrue(labels.contains("0.0"), "the first shelf's first tile")
        XCTAssertFalse(labels.contains("20.0"), "a shelf far outside the window")
        XCTAssertFalse(labels.contains("0.35"), "a tile far outside its shelf's window")
        XCTAssertLessThan(labels.count, 24 * 40, "nothing like the whole of it")
    }

    /// A row removed from the data leaves under its own name: its identity
    /// goes with the item, and the ones standing close over where it was.
    @MainActor
    func testADeletedRowLeavesAndTheRestStand() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyDeletePage(built: built) }
        defer { renderer.closeForTesting() }
        settle(renderer)

        let button = try XCTUnwrap(
            renderer.nativeViews(NSButton.self).first { $0.title == "Drop row 1" })
        button.performClick(nil)
        settle(renderer)

        let standing = renderer.nativeViews(AppKitLabelView.self).map(\.stringValue)
        XCTAssertFalse(standing.contains("Row 1"), "the deleted row's subtree is let go")
        XCTAssertTrue(standing.contains("Row 0"))
        XCTAssertTrue(standing.contains("Row 2"), "its neighbour still stands")
    }

    /// A lazy grid realizes a run at a time: of five hundred cells a few
    /// rows stand, and the scroll room is the whole grid's.
    @MainActor
    func testAGridRealizesARunAtATime() throws {
        let built = LazyCounter()
        let renderer = AppKitRenderer.running { LazyGridPage(built: built) }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroller = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)

        XCTAssertLessThan(built.rows.count, 120, "a few rows of five hundred cells")
        XCTAssertGreaterThan(built.rows.count, 8)
        // Four 90-wide columns of 48-long cells: 125 rows.
        XCTAssertEqual(
            scroller.documentView?.frame.height ?? 0, 6_000,
            accuracy: 1_200, "a hundred and twenty-five runs, estimated")
    }
}

/// Which rows' own views were ever built.
private final class LazyCounter: @unchecked Sendable {
    var rows: Set<Int> = []
}

/// A thousand forty-point rows in a scroller - or thirty, where it does not
/// scroll; `tallEvery` names every nth row one twenty instead.
private struct LazyRowsPage: View {
    let built: LazyCounter
    var count = 1_000
    var scrolls = true
    var tallEvery = 0

    /// The rows themselves.
    private var rows: some View {
        LazyVStack {
            ForEach(0..<count) { row in
                let _ = built.rows.insert(row)
                Text("Row \(row)")
                    .frame(height: tallEvery > 0 && row % tallEvery == 0 ? 120 : 40)
            }
        }
    }

    var body: some View {
        if scrolls {
            ScrollView { rows }.frame(height: 300)
        } else {
            rows
        }
    }
}

/// Twenty-four shelves of forty tiles - a lazy column whose rows each hold a
/// lazy row, each narrowed by the scroller that shows it.
private struct LazyShelvesPage: View {
    let built: LazyCounter

    /// One shelf: its title, then its tiles' own scroller.
    private func shelf(_ shelf: Int) -> some View {
        VStack {
            Text("Shelf \(shelf)").font(.system(size: 11))
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(0..<40) { tile in
                        let _ = built.rows.insert(shelf * 1_000 + tile)
                        Text("\(shelf).\(tile)")
                            .frame(width: 80, height: 56)
                    }
                }
            }
            .frame(height: 72)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<24) { number in
                    shelf(number)
                }
            }
        }
        .frame(height: 300)
    }
}

/// A hundred rows whose first neighbours can be dropped from the data.
private struct LazyDeletePage: View {
    let built: LazyCounter
    @State private var gone: Set<Int> = []

    var body: some View {
        VStack {
            Button("Drop row 1", action: { gone.insert(1) })

            ScrollView {
                LazyVStack {
                    ForEach((0..<100).filter { !gone.contains($0) }) { row in
                        let _ = built.rows.insert(row)
                        Text("Row \(row)").frame(height: 40)
                    }
                }
            }
            .frame(height: 300)
        }
    }
}

/// Five hundred cells in four fixed columns - a hundred and twenty-five runs
/// of forty-eight points.
private struct LazyGridPage: View {
    let built: LazyCounter

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.fixed(90)), GridItem(.fixed(90)),
                          GridItem(.fixed(90)), GridItem(.fixed(90))],
                spacing: 0
            ) {
                ForEach(0..<500) { cell in
                    let _ = built.rows.insert(cell)
                    Text("Cell \(cell)").frame(height: 48)
                }
            }
        }
        .frame(height: 300)
    }
}

/// Runs the loop until the tree has answered every window question and the
/// new rows stand - the tell, the render it asks, and the layout after.
@MainActor
private func settle(_ renderer: AppKitRenderer, turns: Int = 30) {
    for _ in 0..<turns {
        autoreleasepool {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
            _ = renderer.runtime.core.runJobs()
            renderer.runtime.pump.turn()
            renderer.displayFrameForTesting()
            for controller in renderer.windowsForTesting {
                controller.window?.layoutIfNeeded()
            }
        }
    }
}
#endif
