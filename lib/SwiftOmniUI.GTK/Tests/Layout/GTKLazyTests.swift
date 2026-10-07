// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
@testable import SwiftOmniUIGTK
import XCTest

/// A `LazyVStack` on GTK answers the same window questions as everywhere:
/// the rows the scroller's reach holds are mounted, and no more.
final class GTKLazyTests: XCTestCase {
    func testExactWindowsReachIdentityAndIdleInEveryDirection() throws {
        try onUIThread {
            for kind in 0..<4 {
                let host = GTKRenderer.running { ExactLazyPage(kind: kind) }
                for _ in 0..<30 { host.step() }
                let scroll = try XCTUnwrap(host.views(GTKScrollView.self).first)
                let lazy = try XCTUnwrap(host.views(GTKLazyView.self).first)
                let horizontal = kind % 2 == 1
                let perRun = kind < 2 ? 1 : 4
                let extent = horizontal ? 80.0 : 40.0
                let viewport = horizontal ? scroll.frame.width : scroll.frame.height
                let reach = scroll.scroller.standing.reach
                XCTAssertEqual(viewport, horizontal ? 480 : 240, accuracy: 1)
                XCTAssertEqual(horizontal ? reach.x : reach.y,
                               1_000 / Double(perRun) * extent - viewport, accuracy: 1)
                var previous: [String: GTKView] = [:]
                for offset in [0.0, extent * 20, extent * 21, extent * 21 + 1,
                               extent * 20, extent * 150, extent * 5, 0] {
                    scroll.scroller.move(to: Point(horizontal ? offset : 0, horizontal ? 0 : offset))
                    for _ in 0..<6 { host.step() }
                    let span = try XCTUnwrap(lazy.span)
                    let first = Int((span.lowerBound / extent).rounded(.down))
                    let last = Int((span.upperBound / extent).rounded(.up))
                    let expected = max(0, first - 1) * perRun..<min(1_000, (last + 1) * perRun)
                    XCTAssertEqual(lazy.cells.built, expected, "kind \(kind), offset \(offset)")
                    XCTAssertEqual(lazy.mounted.count, expected.count)
                    for (identity, item) in lazy.mounted {
                        if let kept = previous[identity] { XCTAssertTrue(kept === item.view) }
                        XCTAssertGreaterThan(item.view.frame.width, 0)
                        XCTAssertGreaterThan(item.view.frame.height, 0)
                    }
                    previous = lazy.mounted.mapValues(\.view)
                    if kind == 1 && offset == 1_600 { XCTAssertEqual(lazy.mounted.count, 8) }
                }
                let work = [lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements]
                for _ in 0..<200 { host.step() }
                XCTAssertEqual([lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements], work,
                               "stationary kind \(kind) must not recalculate")
            }
        }
    }

    func testNaturalRowsRetainSubtreesAndRenderThroughContinuousScroll() throws {
        try onUIThread {
            let host = GTKRenderer.running { NaturalLazyPage() }
            for _ in 0..<40 { host.step() }
            let scroll = try XCTUnwrap(host.views(GTKScrollView.self).first)
            let lazy = try XCTUnwrap(host.views(GTKLazyStackView.self).first)
            XCTAssertGreaterThan(scroll.frame.height, 200)
            XCTAssertLessThan(scroll.frame.height, 400)
            XCTAssertGreaterThan(scroll.scroller.standing.reach.y, 20_000)
            let row = try XCTUnwrap(host.views(GTKLabelView.self).first { $0.text == "Row 2" })
            let button = try XCTUnwrap(host.views(GTKButtonView.self).first { $0.text == "Delete 1" })
            button.click()
            for _ in 0..<40 {
                host.step()
                XCTAssertTrue(host.views(GTKLabelView.self).first { $0.text == "Row 2" } === row)
                XCTAssertEqual(row.opacity, 1)
            }
            for offset in stride(from: 0.0, through: 2_000.0, by: 80) {
                scroll.scroller.move(to: Point(0, offset))
                for _ in 0..<3 { host.step() }
                let span = try XCTUnwrap(lazy.span)
                let visible = lazy.cells.places(in: span, overscan: 0)
                XCTAssertFalse(visible.isEmpty)
                for place in visible {
                    let item = try XCTUnwrap(lazy.mounted[lazy.cells.identities[place]])
                    XCTAssertEqual(item.view.opacity, 1)
                    XCTAssertGreaterThan(item.view.frame.height, 0)
                }
                // Sample the actual GTK renderer, not merely the backing layout geometry.
                let middle = visible.lowerBound + visible.count / 2
                let painted = try XCTUnwrap(lazy.mounted[lazy.cells.identities[middle]])
                let point = (painted.view.frame.x + 3,
                             painted.view.frame.y - span.lowerBound + painted.view.frame.height / 2)
                let colors = GTKTestHost.pixels(of: scroll.widget, at: [point])
                XCTAssertTrue(colors.contains {
                    ($0 >> 24) == 255 && (($0 >> 16) & 255) >= 220 && ($0 & 0xFFFF) == 0
                },
                              "offset \(offset), point \(point), pixels \(colors)")
            }
            scroll.scroller.move(to: scroll.scroller.standing.reach)
            for _ in 0..<40 { host.step() }
            for _ in 0..<6 {
                try XCTUnwrap(host.views(GTKButtonView.self).last).click()
                for _ in 0..<40 { host.step() }
                let standing = scroll.scroller.standing
                XCTAssertEqual(standing.offset.y, standing.reach.y, accuracy: 1)
                XCTAssertEqual(standing.reach.y + scroll.frame.height, lazy.cells.total, accuracy: 1)
                let last = try XCTUnwrap(lazy.mounted[lazy.cells.identities.last!]?.view)
                XCTAssertEqual(last.frame.y + last.frame.height, lazy.cells.total, accuracy: 1)
            }
            for _ in 0..<10 { host.step() }
            let work = [lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements]
            for _ in 0..<200 { host.step() }
            XCTAssertEqual([lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements], work)
        }
    }

    func testMixedSizesAndLeadingDeletionCanStillReachTheEnd() throws {
        try onUIThread {
            for kind in 0..<4 {
                let host = GTKRenderer.running { UnevenLazyPage(kind: kind, mixed: true) }
                for _ in 0..<40 { host.step() }
                let scroll = try XCTUnwrap(host.views(GTKScrollView.self).first)
                let lazy = try XCTUnwrap(host.views(GTKLazyView.self).first)
                let horizontal = kind % 2 == 1
                let drop = try XCTUnwrap(host.views(GTKButtonView.self).first { $0.text == "Drop ten" })
                drop.click()
                for _ in 0..<40 { host.step() }
                for action in ["Original", "Grow", "Shrink"] {
                    if action != "Original" {
                        let button = try XCTUnwrap(host.views(GTKButtonView.self).first { $0.text == action })
                        button.click()
                        for _ in 0..<40 { host.step() }
                    }
                    for offset in stride(from: 0.0, through: 1_000.0, by: 160) {
                        scroll.scroller.move(to: Point(horizontal ? offset : 0, horizontal ? 0 : offset))
                        for _ in 0..<4 { host.step() }
                    }
                    scroll.scroller.move(to: scroll.scroller.standing.reach)
                    for _ in 0..<40 { host.step() }
                    let span = try XCTUnwrap(lazy.span)
                    let last = try XCTUnwrap(lazy.mounted[lazy.cells.identities.last!]?.view,
                                            "kind \(kind), \(action)")
                    let start = horizontal ? last.frame.x : last.frame.y
                    let extent = horizontal ? last.frame.width : last.frame.height
                    XCTAssertLessThan(start, span.upperBound)
                    XCTAssertGreaterThan(start + extent, span.lowerBound)
                    let standing = scroll.scroller.standing
                    let total = kind < 2 ? lazy.cells.total
                        : lazy.cells.runs.total(count: (lazy.cells.identities.count + 3) / 4)
                    XCTAssertEqual((horizontal ? standing.reach.x : standing.reach.y)
                                   + (horizontal ? scroll.frame.width : scroll.frame.height), total, accuracy: 1,
                                   "kind \(kind), \(action): the native document must shrink with the content")
                    XCTAssertEqual(horizontal ? standing.offset.x : standing.offset.y,
                                   horizontal ? standing.reach.x : standing.reach.y, accuracy: 1)
                    for _ in 0..<40 { host.step() }
                    XCTAssertEqual(scroll.scroller.standing.offset, standing.offset)
                }
            }
        }
    }

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

private struct ExactLazyPage: View {
    let kind: Int
    var count = 1_000

    var body: some View {
        ScrollView(kind % 2 == 1 ? .horizontal : .vertical) {
            if kind == 0 {
                LazyVStack(spacing: 0) {
                    ForEach(0..<count) { Text("Row \($0)").frame(width: 80, height: 40) }
                }
            } else if kind == 1 {
                LazyHStack(spacing: 0) {
                    ForEach(0..<count) { Text("Row \($0)").frame(width: 80, height: 40) }
                }
            } else if kind == 2 {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 4), spacing: 0) {
                    ForEach(0..<count) { Text("Row \($0)").frame(width: 80, height: 40) }
                }
            } else {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(40)), count: 4), spacing: 0) {
                    ForEach(0..<count) { Text("Row \($0)").frame(width: 80, height: 40) }
                }
            }
        }
        .frame(width: 480, height: 240)
    }
}


private struct NaturalLazyPage: View {
    @State private var standing: Set<Int> = []
    @State private var gone: Set<Int> = []

    var body: some View {
        Grid {
            VStack {
                Text("\(standing.count) standing")
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Text("Header")
                        ForEach((0..<1_000).filter { !gone.contains($0) }) { row in
                            Grid {
                                Text("Row \(row)")
                                Button("Delete \(row)") { gone.insert(row) }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(.red)
                            .animation(.inherited)
                            .onAppear { standing.insert(row) }
                            .onDisappear { standing.remove(row) }
                        }
                        Text("Footer")
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

private struct UnevenLazyPage: View {
    let kind: Int
    let mixed: Bool
    @State private var rows: [Int]
    @State private var extra = 0.0
    @State private var standing: Set<Int> = []

    init(kind: Int, mixed: Bool, count: Int = 200) {
        self.kind = kind
        self.mixed = mixed
        _rows = State(wrappedValue: Array(0..<count))
    }

    var body: some View {
        VStack {
            HStack {
                Text("\(standing.count) standing")
                Button("Drop ten") { rows.removeFirst(10) }
                Button("Grow") { extra = 70 }
                Button("Shrink") { extra = -20 }
            }
            ScrollView(kind % 2 == 1 ? .horizontal : .vertical) {
                if kind == 0 {
                    LazyVStack(spacing: 3) {
                        ForEach(rows) { row in
                            Text("Row \(row)")
                                .frame(width: 80, height: 40 + (mixed ? Double(row % 7) * 9 : 0) + (row % 3 == 0 ? extra : 0))
                                .onAppear { standing.insert(row) }
                                .onDisappear { standing.remove(row) }
                        }
                    }
                } else if kind == 1 {
                    LazyHStack(spacing: 3) {
                        ForEach(rows) { row in
                            Text("Row \(row)")
                                .frame(width: 40 + (mixed ? Double(row % 7) * 9 : 0) + (row % 3 == 0 ? extra : 0), height: 40)
                                .onAppear { standing.insert(row) }
                                .onDisappear { standing.remove(row) }
                        }
                    }
                } else if kind == 2 {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 4), spacing: 3) {
                        ForEach(rows) { row in
                            Text("Row \(row)")
                                .frame(height: 40 + (mixed ? Double(row % 7) * 9 : 0) + (row % 3 == 0 ? extra : 0))
                                .onAppear { standing.insert(row) }
                                .onDisappear { standing.remove(row) }
                        }
                    }
                } else {
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(40)), count: 4), spacing: 3) {
                        ForEach(rows) { row in
                            Text("Row \(row)")
                                .frame(width: 40 + (mixed ? Double(row % 7) * 9 : 0) + (row % 3 == 0 ? extra : 0))
                                .onAppear { standing.insert(row) }
                                .onDisappear { standing.remove(row) }
                        }
                    }
                }
            }
            .frame(width: 480, height: 240)
        }
    }
}
