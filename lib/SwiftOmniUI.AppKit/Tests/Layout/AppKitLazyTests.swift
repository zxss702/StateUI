// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) @testable import SwiftOmniUI
@_spi(Host) @testable import SwiftOmniUIHost
@testable import SwiftOmniUIAppKit
import SwiftOmniUIConformance
import XCTest

/// A `LazyVStack` is lazy twice over: it builds a row's own view only for the
/// identities the host's window asked for, and it mounts only those. The
/// window's reach - the visible stretch plus an overscan - is what a thousand
/// rows cost, not the thousand.
final class AppKitLazyTests: XCTestCase {
    @MainActor
    func testAddingToAnEmptyLazyStackRunsTheInsertionTransition() throws {
        let clock = TestClock()
        let rows = State(wrappedValue: [Int]())
        stateUIUseApp(OneWindowApplication(page: {
            LazyVStack(spacing: 0) {
                ForEach(rows.wrappedValue) { number in
                    Text("Row \(number)").frame(height: 40)
                }
            }
            .animation(.eased(200, .linear))
            .frame(width: 240, height: 240)
        }))
        let host = testRenderer(clock: { clock.now })
        host.startForTesting()
        settle(host, turns: 8)
        let lazy = try XCTUnwrap(host.nativeViews(AppKitLazyView.self).first)
        for number in 0..<2 {
            rows.wrappedValue = [number]
            settle(host, turns: 8)
            let row = try XCTUnwrap(lazy.held.values.first?.view)
            XCTAssertEqual(row.alphaValue, 0, accuracy: 0.01)
            clock.now += 100
            settle(host, turns: 8)
            XCTAssertEqual(row.alphaValue, 0.5, accuracy: 0.01)
            clock.now += 100
            settle(host, turns: 8)
            XCTAssertEqual(row.alphaValue, 1, accuracy: 0.01)
            rows.wrappedValue = []
            settle(host, turns: 8)
        }
        host.closeForTesting()
    }

    @MainActor
    func testDeletingBeforeTheViewportKeepsThePresentedAnchor() throws {
        for kind in 0..<4 {
            let horizontal = kind % 2 == 1
            let perRun = kind < 2 ? 1 : 2
            let clock = TestClock()
            let rows = State(wrappedValue: Array(0..<100))
            stateUIUseApp(OneWindowApplication(page: {
                let content = ForEach(rows.wrappedValue) { number in
                    Text("Row \(number)").frame(width: 40, height: 40)
                }
                return ScrollView(horizontal ? .horizontal : .vertical) {
                    Group {
                        if kind == 0 { LazyVStack(spacing: 0) { content } }
                        else if kind == 1 { LazyHStack(spacing: 0) { content } }
                        else if kind == 2 {
                            LazyVGrid(columns: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 0) { content }
                        } else {
                            LazyHGrid(rows: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 0) { content }
                        }
                    }
                    .animation(.eased(200, .linear))
                }
                .frame(width: 240, height: 240)
            }))
            let host = testRenderer(clock: { clock.now })
            host.startForTesting()
            settle(host, turns: 8)
            let scroll = try XCTUnwrap(host.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(host.nativeViews(AppKitLazyView.self).first)
            scroll.contentView.scroll(to: NSPoint(x: horizontal ? 400 : 0, y: horizontal ? 0 : 400))
            scroll.reflectScrolledClipView(scroll.contentView)
            settle(host, turns: 8)
            let identity = lazy.cells.identities[10 * perRun]
            let retained = try XCTUnwrap(lazy.held[identity]?.view)
            for removed in [11, 9, 0] {
                let relative = (horizontal ? retained.frame.minX : retained.frame.minY)
                    - (horizontal ? scroll.contentView.bounds.minX : scroll.contentView.bounds.minY)
                let began = clock.now
                rows.wrappedValue.removeAll { (removed * perRun..<((removed + 1) * perRun)).contains($0) }
                for tick in stride(from: 0.0, through: 240.0, by: 40) {
                    clock.now = began + tick
                    for _ in 0..<8 {
                        settle(host, turns: 1)
                        XCTAssertEqual((horizontal ? retained.frame.minX : retained.frame.minY)
                                       - (horizontal ? scroll.contentView.bounds.minX : scroll.contentView.bounds.minY),
                                       relative, accuracy: 1,
                                       "removing \(removed), at \(tick) ms must keep the visible anchor in place")
                    }
                }
            }
            host.closeForTesting()
        }
    }

    @MainActor
    func testDataChangesAnimateInEveryLazyDirection() throws {
        for kind in 0..<4 {
            let clock = TestClock()
            let rows = State(wrappedValue: Array(0..<40))
            let extent = State(wrappedValue: 40.0)
            let horizontal = kind % 2 == 1
            let perRun = kind < 2 ? 1 : 2
            stateUIUseApp(OneWindowApplication(page: {
                let content = ForEach(rows.wrappedValue) { number in
                    ResizingLazyRow(number: number, varies: number < perRun,
                                    horizontal: horizontal, extent: extent.projectedValue)
                }
                return ScrollView(horizontal ? .horizontal : .vertical) {
                    Group {
                        if kind == 0 { LazyVStack(spacing: 0) { content } }
                        else if kind == 1 { LazyHStack(spacing: 0) { content } }
                        else if kind == 2 {
                            LazyVGrid(columns: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 0) { content }
                        } else {
                            LazyHGrid(rows: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 0) { content }
                        }
                    }
                    .animation(.eased(200, .linear))
                }
                .frame(width: 240, height: 240)
            }))
            let host = testRenderer(clock: { clock.now })
            host.startForTesting()
            settle(host, turns: 8)
            let lazy = try XCTUnwrap(host.nativeViews(AppKitLazyView.self).first)
            let identity = lazy.cells.identities[perRun * 2]
            let retained = try XCTUnwrap(lazy.held[identity]?.view)
            for operation in 0..<5 {
                let before = horizontal ? retained.frame.origin.x : retained.frame.origin.y
                let began = clock.now
                let leaving = lazy.held[lazy.cells.identities[perRun]]?.view
                if operation == 0 { rows.wrappedValue.removeSubrange(perRun..<perRun * 2) }
                else if operation == 1 { rows.wrappedValue.insert(contentsOf: 100..<100 + perRun, at: perRun) }
                else if operation == 2 { rows.wrappedValue.swapAt(perRun * 2, perRun * 3) }
                else if operation == 3 { extent.wrappedValue = 80 }
                else { extent.wrappedValue = 40 }
                settle(host, turns: 8)
                let joining = operation == 1 ? lazy.held[lazy.cells.identities[perRun]]?.view : nil
                if operation == 0 { XCTAssertEqual(try XCTUnwrap(leaving).alphaValue, 1, accuracy: 0.01) }
                if let joining { XCTAssertEqual(joining.alphaValue, 0, accuracy: 0.01) }
                let target = before + (operation == 0 || operation == 4 ? -40 : 40)
                XCTAssertEqual(horizontal ? retained.frame.origin.x : retained.frame.origin.y, before, accuracy: 1,
                               "kind \(kind), operation \(operation) must start at the old position")
                clock.now = began + 100
                settle(host, turns: 8)
                XCTAssertEqual(horizontal ? retained.frame.origin.x : retained.frame.origin.y, (before + target) / 2, accuracy: 1,
                               "kind \(kind), operation \(operation) must pass through the midpoint")
                if operation == 0 { XCTAssertEqual(try XCTUnwrap(leaving).alphaValue, 0.5, accuracy: 0.01) }
                if let joining { XCTAssertEqual(joining.alphaValue, 0.5, accuracy: 0.01) }
                clock.now = began + 200
                settle(host, turns: 8)
                XCTAssertEqual(horizontal ? retained.frame.origin.x : retained.frame.origin.y, target, accuracy: 1)
                XCTAssertTrue(lazy.held[identity]?.view === retained)
                if let joining { XCTAssertEqual(joining.alphaValue, 1, accuracy: 0.01) }
            }
            let scroll = try XCTUnwrap(host.nativeViews(AppKitScrollView.self).first)
            scroll.contentView.scroll(to: NSPoint(x: horizontal ? 480 : 0, y: horizontal ? 0 : 480))
            scroll.reflectScrolledClipView(scroll.contentView)
            settle(host, turns: 8)
            XCTAssertFalse(host.runtime.animator.isMoving, "scrolling must not start data transitions")
            for item in lazy.held.values { XCTAssertEqual(item.view.alphaValue, 1, accuracy: 0.01) }

            host.closeForTesting()
        }
    }

    @MainActor
    func testExactWindowsRetainViewsAndStayIdleInEveryDirection() throws {
        for kind in 0..<4 {
            let renderer = AppKitRenderer.running { ExactLazyPage(kind: kind) }
            defer { renderer.closeForTesting() }
            settle(renderer)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
            let horizontal = kind % 2 == 1
            let perRun = kind < 2 ? 1 : 4
            let extent = horizontal ? 80.0 : 40.0
            XCTAssertEqual(scroll.contentView.bounds.width, 480, accuracy: 1)
            XCTAssertEqual(scroll.contentView.bounds.height, 240, accuracy: 1)
            XCTAssertEqual(horizontal ? scroll.documentView!.frame.width : scroll.documentView!.frame.height,
                           1_000 / Double(perRun) * extent, accuracy: 1)
            var previous: [String: NSView] = [:]
            for offset in [0.0, extent * 20, extent * 21, extent * 21 + 1,
                           extent * 20, extent * 150, extent * 5, 0] {
                scroll.contentView.scroll(to: NSPoint(x: horizontal ? offset : 0, y: horizontal ? 0 : offset))
                scroll.reflectScrolledClipView(scroll.contentView)
                settle(renderer, turns: 3)
                let span = try XCTUnwrap(lazy.span)
                let first = Int(floor(span.lowerBound / extent))
                let last = Int(ceil(span.upperBound / extent))
                let expected = max(0, first - 1) * perRun..<min(1_000, (last + 1) * perRun)
                XCTAssertEqual(lazy.cells.built, expected, "kind \(kind), offset \(offset)")
                XCTAssertEqual(lazy.held.count, expected.count)
                for (identity, item) in lazy.held {
                    if let kept = previous[identity] { XCTAssertTrue(kept === item.view) }
                    XCTAssertEqual(item.view.alphaValue, 1)
                    XCTAssertTrue(item.view.layer?.animationKeys()?.isEmpty ?? true)
                    XCTAssertFalse(item.view.frame.isEmpty)
                }
                previous = lazy.held.mapValues(\.view)
                if kind == 1 && offset == 1_600 { XCTAssertEqual(lazy.held.count, 8) }
            }
            let work = [lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements]
            settle(renderer, turns: 100)
            XCTAssertEqual([lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements], work,
                           "a stationary lazy container does no work, kind \(kind)")
        }
    }

    @MainActor
    func testGalleryCompositionUsesViewportAndNaturalRows() throws {
        let renderer = AppKitRenderer.running { NaturalLazyPage() }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
        let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyStackView.self).first)
        XCTAssertGreaterThan(scroll.contentView.bounds.height, 200)
        XCTAssertLessThan(scroll.contentView.bounds.height, 400)
        XCTAssertEqual(scroll.contentView.bounds.height, lazy.visibleRect.height, accuracy: 1)
        XCTAssertGreaterThan(scroll.documentView!.frame.height, 20_000)
        for offset in stride(from: 0.0, through: 1_200.0, by: 24.0) {
            scroll.contentView.scroll(to: NSPoint(x: 0, y: offset))
            scroll.reflectScrolledClipView(scroll.contentView)
            settle(renderer, turns: 1)
            let span = try XCTUnwrap(lazy.span)
            let visible = lazy.cells.places(in: span, overscan: 0)
            for place in visible {
                let item = try XCTUnwrap(lazy.held[lazy.cells.identities[place]])
                XCTAssertEqual(item.view.alphaValue, 1)
                XCTAssertGreaterThan(item.view.frame.height, 0)
            }
        }
        settle(renderer, turns: 6)
        let work = [lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements]
        settle(renderer, turns: 100)
        XCTAssertEqual([lazy.cells.searches, lazy.cells.requests, lazy.cells.measurements], work)
    }

    @MainActor
    func testNaturalRowsEndAtTheViewportAfterRepeatedDeletion() throws {
        for gallery in [false, true] {
            let renderer = AppKitRenderer.running {
                if gallery { return GalleryLazyPage(kind: 0) }
                return NaturalLazyPage()
            }
            defer { renderer.closeForTesting() }
            if gallery { renderer.windowsForTesting.first?.window?.setContentSize(NSSize(width: 900, height: 1_040)) }
            settle(renderer)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyStackView.self).first)
            for offset in stride(from: 0.0, through: 4_000, by: 320) {
                scroll.contentView.scroll(to: NSPoint(x: 0, y: offset))
                scroll.reflectScrolledClipView(scroll.contentView)
                settle(renderer, turns: 2)
            }
            for deletion in 0..<6 {
                if deletion > 0 {
                    try XCTUnwrap(renderer.nativeViews(NSButton.self).last).performClick(nil)
                    settle(renderer, turns: 40)
                }
                let document = try XCTUnwrap(scroll.documentView)
                if deletion == 0 {
                    scroll.contentView.scroll(to: NSPoint(x: 0, y: document.frame.height - scroll.contentView.bounds.height))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    settle(renderer, turns: 40)
                }
                let last = try XCTUnwrap(lazy.held[lazy.cells.identities.last!]?.view,
                                         "gallery=\(gallery), deletion=\(deletion), document=\(document.frame), total=\(lazy.cells.total), clip=\(scroll.contentView.bounds), lazy=\(lazy.frame), span=\(String(describing: lazy.span)), built=\(lazy.cells.built)")
                XCTAssertEqual(last.convert(last.bounds, to: scroll.contentView).maxY,
                               scroll.contentView.bounds.maxY, accuracy: 1,
                               "gallery=\(gallery), deletion=\(deletion): no empty space after the actual last child")
                XCTAssertEqual(document.frame.height, lazy.cells.total, accuracy: 1)
            }
        }
    }

    @MainActor
    func testChangingSizesDataAndAdaptiveTracksKeepsTheVisibleAnchor() throws {
        for grid in [false, true] {
            let renderer = AppKitRenderer.running { ChangingLazyPage(grid: grid) }
            defer { renderer.closeForTesting() }
            settle(renderer)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: 800))
            scroll.reflectScrolledClipView(scroll.contentView)
            settle(renderer, turns: 6)
            let span = try XCTUnwrap(lazy.span)
            let perRun = grid ? 2 : 1
            let first = Int(span.lowerBound / 40) * perRun
            let identity = lazy.cells.identities[first]
            let retained = try XCTUnwrap(lazy.held[identity]?.view)
            let inset = retained.convert(retained.bounds, to: scroll.contentView).minY - scroll.contentView.bounds.minY
            for action in ["Grow", "Shrink", "Insert", "Reorder", "Widen"] {
                let button = try XCTUnwrap(renderer.nativeViews(NSButton.self).first { $0.title == action })
                button.performClick(nil)
                settle(renderer, turns: 30)
                let item = try XCTUnwrap(lazy.held[identity], action)
                XCTAssertTrue(item.view === retained, action)
                let position = item.view.convert(item.view.bounds, to: scroll.contentView).minY - scroll.contentView.bounds.minY
                XCTAssertEqual(position, inset, accuracy: 1, action)
                let extent = action == "Grow" ? 80.0 : 20.0
                let tracks = grid ? (action == "Widen" ? 4 : 2) : 1
                let count = action == "Grow" || action == "Shrink" ? 200 : 202
                XCTAssertEqual(scroll.documentView!.frame.height,
                               Double((count + tracks - 1) / tracks) * extent, accuracy: 1, action)
            }
            let clear = try XCTUnwrap(renderer.nativeViews(NSButton.self).first { $0.title == "Clear" })
            clear.performClick(nil)
            settle(renderer, turns: 30)
            XCTAssertTrue(lazy.cells.identities.isEmpty)
            XCTAssertTrue(lazy.held.isEmpty)
            XCTAssertEqual(lazy.cells.built, 0..<0)
        }
    }

    @MainActor
    func testDeletedLeadingItemsAndMixedSizesCanReachTheEndInEveryDirection() throws {
        for kind in 0..<4 {
            for mixed in [false, true] {
                let renderer = AppKitRenderer.running { UnevenLazyPage(kind: kind, mixed: mixed) }
                defer { renderer.closeForTesting() }
                settle(renderer)
                let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
                let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
                let horizontal = kind % 2 == 1
                let drop = try XCTUnwrap(renderer.nativeViews(NSButton.self).first { $0.title == "Drop ten" })
                drop.performClick(nil)
                settle(renderer)
                for action in ["Original", "Grow", "Shrink"] {
                    if action != "Original" {
                        let button = try XCTUnwrap(renderer.nativeViews(NSButton.self).first { $0.title == action })
                        button.performClick(nil)
                        settle(renderer)
                    }
                    // Visit changing windows before going to the end, just as a real scroll does.
                    for offset in stride(from: 0.0, through: 2_000.0, by: 160) {
                        scroll.contentView.scroll(to: NSPoint(x: horizontal ? offset : 0, y: horizontal ? 0 : offset))
                        scroll.reflectScrolledClipView(scroll.contentView)
                        settle(renderer, turns: 2)
                        for item in lazy.held.values {
                            XCTAssertEqual(item.view.alphaValue, 1)
                            XCTAssertFalse(item.view.frame.isEmpty)
                        }
                    }
                    let document = try XCTUnwrap(scroll.documentView)
                    let end = horizontal ? document.frame.width - scroll.contentView.bounds.width
                        : document.frame.height - scroll.contentView.bounds.height
                    scroll.contentView.scroll(to: NSPoint(x: horizontal ? end : 0, y: horizontal ? 0 : end))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    settle(renderer)
                    guard let last = lazy.held[lazy.cells.identities.last!]?.view else {
                        XCTFail("last item missing: kind \(kind), mixed \(mixed), \(action)")
                        continue
                    }
                    let lastFrame = last.convert(last.bounds, to: scroll.contentView)
                    let clip = scroll.contentView.bounds
                    XCTAssertTrue(lastFrame.intersects(clip), "last item must be visible")
                    XCTAssertEqual(horizontal ? clip.maxX : clip.maxY,
                                   horizontal ? document.frame.width : document.frame.height,
                                   accuracy: 1, "kind \(kind), mixed \(mixed), \(action)")
                    let resting = scroll.contentView.bounds.origin
                    settle(renderer, turns: 30)
                    XCTAssertEqual(scroll.contentView.bounds.origin, resting, "the end must not jump backwards")
                }
            }
        }
    }

    @MainActor
    func testContinuousScrollingWorkAndFrameBudget() throws {
        var measurementCounts: [Int] = []
        for count in [1_000, 10_000] {
            let renderer = AppKitRenderer.running { ExactLazyPage(kind: 0, count: count) }
            defer { renderer.closeForTesting() }
            settle(renderer)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyStackView.self).first)
            let measured = lazy.cells.measurements
            let requested = lazy.cells.requests
            var durations: [Double] = []
            for frame in 0..<120 {
                let began = ContinuousClock.now
                let offset = Double(frame * 8 + (frame >= 60 ? 20_000 : 0))
                scroll.contentView.scroll(to: NSPoint(x: 0, y: offset))
                scroll.reflectScrolledClipView(scroll.contentView)
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.0001))
                _ = renderer.runtime.core.runJobs()
                renderer.runtime.pump.turn()
                renderer.displayFrameForTesting()
                for controller in renderer.windowsForTesting { controller.window?.layoutIfNeeded() }
                let elapsed = began.duration(to: .now).components
                durations.append(Double(elapsed.seconds) * 1_000 + Double(elapsed.attoseconds) / 1e15)
                let span = try XCTUnwrap(lazy.span)
                let first = Int((span.lowerBound / 40).rounded(.down))
                let last = Int((span.upperBound / 40).rounded(.up))
                for row in first..<last {
                    let item = try XCTUnwrap(lazy.held[lazy.cells.identities[row]], "frame \(frame), row \(row)")
                    XCTAssertEqual(item.view.alphaValue, 1)
                }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: max(0, (16.7 - durations.last!) / 1_000)))
            }
            let sorted = durations.sorted()
            let p95 = sorted[Int(Double(sorted.count - 1) * 0.95)]
            measurementCounts.append(lazy.cells.measurements - measured)
            print("LAZY_PERF count=\(count) frames=120 requests=\(lazy.cells.requests - requested) "
                  + "measurements=\(measurementCounts.last!) median_ms=\(sorted[60]) p95_ms=\(p95) max_ms=\(sorted.last!)")
            XCTAssertLessThan(measurementCounts.last!, 500)
            #if !DEBUG
            XCTAssertLessThan(p95, 16.7, "the native scrolling work must fit a 60 Hz frame in Release")
            #endif
        }
        XCTAssertLessThanOrEqual(measurementCounts[1], measurementCounts[0] + 20,
                                 "ten times the data must not multiply the viewport's measurement work")
    }

    @MainActor
    func testMixedSizeScrollingWorkByStageInEveryDirection() throws {
        for kind in 0..<4 {
            for count in [1_000, 10_000] {
                let renderer = AppKitRenderer.running { UnevenLazyPage(kind: kind, mixed: true, count: count) }
                defer { renderer.closeForTesting() }
                settle(renderer)
                let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
                let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
                let horizontal = kind % 2 == 1
                let perRun = kind < 2 ? 1 : 4
                let measured = lazy.cells.measurements
                let searched = lazy.cells.searches
                let requested = lazy.cells.requests
                var windowTimes: [Double] = [], layoutTimes: [Double] = [], totals: [Double] = []
                for frame in 0..<120 {
                    let start = ContinuousClock.now
                    let offset = Double(frame * 19 + (frame >= 60 ? 8_000 : 0))
                    scroll.contentView.scroll(to: NSPoint(x: horizontal ? offset : 0, y: horizontal ? 0 : offset))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    let requestedAt = ContinuousClock.now
                    _ = renderer.runtime.core.runJobs()
                    renderer.runtime.pump.turn()
                    renderer.displayFrameForTesting()
                    for controller in renderer.windowsForTesting { controller.window?.layoutIfNeeded() }
                    let end = ContinuousClock.now
                    let windowDuration = start.duration(to: requestedAt).components
                    let layoutDuration = requestedAt.duration(to: end).components
                    let windowMS = Double(windowDuration.seconds) * 1_000 + Double(windowDuration.attoseconds) / 1e15
                    let layoutMS = Double(layoutDuration.seconds) * 1_000 + Double(layoutDuration.attoseconds) / 1e15
                    windowTimes.append(windowMS)
                    layoutTimes.append(layoutMS)
                    totals.append(windowMS + layoutMS)
                    let span = try XCTUnwrap(lazy.span)
                    let visible = kind < 2 ? lazy.cells.places(in: span, overscan: 0)
                        : lazy.cells.runs.places(in: span, overscan: 0, count: (count + perRun - 1) / perRun)
                    for place in visible.lowerBound * perRun..<min(count, visible.upperBound * perRun) {
                        let item = try XCTUnwrap(lazy.held[lazy.cells.identities[place]], "kind \(kind), frame \(frame)")
                        XCTAssertEqual(item.view.alphaValue, 1)
                    }
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: max(0, (16.7 - totals.last!) / 1_000)))
                }
                windowTimes.sort()
                layoutTimes.sort()
                totals.sort()
                print("LAZY_MIXED kind=\(kind) count=\(count) requests=\(lazy.cells.requests - requested) "
                      + "searches=\(lazy.cells.searches - searched) measurements=\(lazy.cells.measurements - measured) "
                      + "window_p95_ms=\(windowTimes[113]) layout_p95_ms=\(layoutTimes[113]) total_p95_ms=\(totals[113]) max_ms=\(totals.last!)")
                #if !DEBUG
                XCTAssertLessThan(totals[113], 16.7, "mixed sizes and lifecycle counters must also fit the frame")
                #endif
            }
        }
    }

    @MainActor
    func testGallerySizedScrollingCostAndStanding() throws {
        let profiling = ProcessInfo.processInfo.environment["SWIFTOMNIUI_LAZY_PROFILE"] != nil
        for kind in 0..<3 {
            let renderer = AppKitRenderer.running { GalleryLazyPage(kind: kind) }
            defer { renderer.closeForTesting() }
            settle(renderer)
            for controller in renderer.windowsForTesting {
                controller.window?.setContentSize(NSSize(width: 1_000, height: 1_100))
            }
            settle(renderer, turns: 5)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
            let counter = try XCTUnwrap(renderer.nativeViews(AppKitLabelView.self).first { $0.stringValue.hasPrefix("standing ") })
            XCTAssertGreaterThan(scroll.contentView.bounds.width, 700)
            XCTAssertGreaterThan(scroll.contentView.bounds.height, kind == 1 ? 150 : 850)
            if profiling { _ = HostBoundary.takeInspectionLog() }
            var profile = ""
            var durations: [Double] = []
            var boundaryDurations: [Double] = []
            var counts: Set<Int> = []
            let measured = lazy.cells.measurements
            for frame in 0..<180 {
                let before = lazy.cells.requests
                let measuredBefore = lazy.cells.measurements
                let heldBefore = Set(lazy.held.keys)
                let start = ContinuousClock.now
                let offset = Double(1_520 + frame * (kind == 1 ? 8 : 5))
                scroll.contentView.scroll(to: NSPoint(x: kind == 1 ? offset : 0, y: kind == 1 ? 0 : offset))
                scroll.reflectScrolledClipView(scroll.contentView)
                _ = renderer.runtime.core.runJobs()
                renderer.runtime.pump.turn()
                renderer.displayFrameForTesting()
                for controller in renderer.windowsForTesting { controller.window?.layoutIfNeeded() }
                let duration = start.duration(to: .now).components
                let elapsed = Double(duration.seconds) * 1_000 + Double(duration.attoseconds) / 1e15
                durations.append(elapsed)
                if before != lazy.cells.requests { boundaryDurations.append(elapsed) }
                let standing = try XCTUnwrap(Int(counter.stringValue.dropFirst(9)))
                counts.insert(standing)
                XCTAssertEqual(standing, lazy.held.count, "kind \(kind), frame \(frame), built \(lazy.cells.built)")
                XCTAssertLessThanOrEqual(lazy.cells.measurements - measuredBefore,
                    Set(lazy.held.keys).subtracting(heldBefore).count,
                    "a lifetime counter update must not remeasure retained cells")
                if kind == 1 {
                    let visible = lazy.cells.places(in: try XCTUnwrap(lazy.span), overscan: 0)
                    XCTAssertEqual(standing, visible.count + 2)
                }
                if profiling { profile += "FRAME \(frame) ms=\(elapsed)\n" + HostBoundary.takeInspectionLog() }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: max(0, (16.7 - elapsed) / 1_000)))
            }
            let worst = durations.indices.max { durations[$0] < durations[$1] }!
            durations.sort()
            boundaryDurations.sort()
            print("LAZY_GALLERY kind=\(kind) viewport=\(scroll.contentView.bounds.size) standing=\(counts.sorted()) measurements=\(lazy.cells.measurements - measured) "
                  + "p95_ms=\(durations[170]) boundary_p95_ms=\(boundaryDurations[Int(Double(boundaryDurations.count - 1) * 0.95)]) "
                  + "max_ms=\(durations.last!) worst_frame=\(worst)")
            if profiling { try profile.write(toFile: "/tmp/swiftomniui-gallery-profile-\(kind).txt", atomically: true, encoding: .utf8) }
            #if !DEBUG
            XCTAssertLessThan(durations[170], 16.7)
            #endif
        }
    }

    @MainActor
    func testSelectingLazyTabsPopulatesTheFirstWindowWithoutScrolling() throws {
        let renderer = AppKitRenderer.running {
            TabView(0..<4) { kind in
                GeometryReader { proxy in
                    Grid {
                        Text("Lazy examples")
                        ZStack {
                            Grid { GalleryLazyPage(kind: kind) }
                                .rows(.fill)
                                .contentPadding(16)
                        }
                        .gridRow(1)
                    }
                    .rows(.auto, .fill)
                    .rowSpacing(16)
                    .contentPadding(24)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let tabs = try XCTUnwrap(renderer.nativeViews(AppKitTabbedView.self).first)
        for selected in [1, 3, 2, 0, 1, 3] {
            tabs.selectByUser(selected)
            settle(renderer)
            let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyView.self).first)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            XCTAssertFalse(lazy.held.isEmpty, "tab \(selected), viewport \(scroll.contentView.bounds), lazy \(lazy.frame), span \(String(describing: lazy.span))")
            XCTAssertEqual(scroll.contentView.bounds.origin, .zero, "no scroll is needed to initialize a tab")
            if selected == 2 {
                for item in lazy.held.values {
                    XCTAssertGreaterThanOrEqual(item.view.frame.width, 96,
                                               "adaptive cells must fill their track from the first presentation")
                }
            }
        }
    }

    @MainActor
    func testHorizontalScrollerKeepsNaturalContentHeight() throws {
        for grid in [false, true] {
            let renderer = AppKitRenderer.running {
                VStack {
                    Text("Counter")
                    ScrollView(.horizontal) {
                        if grid {
                            LazyHGrid(rows: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 0) {
                                ForEach(0..<200) { Text("Tile \($0)").frame(width: 80) }
                            }
                        } else {
                            LazyHStack {
                                ForEach(0..<200) { Text("Tile \($0)").frame(width: 80, height: 56) }
                            }
                        }
                    }
                }
                .frame(width: 480, height: 300)
            }
            defer { renderer.closeForTesting() }
            settle(renderer)
            let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
            XCTAssertEqual(scroll.contentView.bounds.height, grid ? 80 : 56, accuracy: 1)
            XCTAssertEqual(scroll.documentView!.frame.width, grid ? 8_000 : 16_000, accuracy: 1)
        }
    }

    @MainActor
    func testDeletingARowAnimatesPositionsWithoutFadingRetainedSubtrees() throws {
        let renderer = AppKitRenderer.running { NaturalLazyPage() }
        defer { renderer.closeForTesting() }
        settle(renderer)
        let lazy = try XCTUnwrap(renderer.nativeViews(AppKitLazyStackView.self).first)
        let row = try XCTUnwrap(renderer.nativeViews(AppKitLabelView.self).first { $0.stringValue == "Row 2" })
        let root = try XCTUnwrap(row.superview)
        let origin = root.frame.minY
        let button = try XCTUnwrap(renderer.nativeViews(NSButton.self).first { $0.title == "Delete 1" })
        button.performClick(nil)
        var positions: [CGFloat] = []
        for _ in 0..<35 {
            settle(renderer, turns: 1)
            XCTAssertTrue(row.superview === root)
            XCTAssertEqual(root.alphaValue, 1)
            for view in root.subviews { XCTAssertEqual(view.alphaValue, 1) }
            positions.append(root.frame.minY)
        }
        let end = root.frame.minY
        XCTAssertLessThan(end, origin)
        XCTAssertTrue(positions.contains { $0 > end + 0.5 && $0 < origin - 0.5 }, "deleting data closes the gap with animation")
        XCTAssertFalse(renderer.nativeViews(AppKitLabelView.self).contains { $0.stringValue == "Row 1" })
        let scroll = try XCTUnwrap(renderer.nativeViews(AppKitScrollView.self).first)
        for offset in stride(from: 0.0, through: 4_000.0, by: 170.0) {
            scroll.contentView.scroll(to: NSPoint(x: 0, y: offset))
            scroll.reflectScrolledClipView(scroll.contentView)
            settle(renderer, turns: 1)
            for item in lazy.held.values {
                XCTAssertEqual(item.view.alphaValue, 1)
                for view in item.view.subviews { XCTAssertEqual(view.alphaValue, 1) }
            }
        }
    }

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
        let scrolls = renderer.nativeViews(AppKitScrollView.self)
        let outer = try XCTUnwrap(scrolls.first { $0.orientation == .vertical })
        for shelf in scrolls where shelf.orientation == .horizontal {
            XCTAssertEqual(shelf.contentView.bounds.width, outer.contentView.bounds.width, accuracy: 1)
        }
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

private struct GalleryLazyPage: View {
    let kind: Int
    @State private var standing = 0
    @State private var gone: Set<Int> = []

    var body: some View {
        VStack {
            Text("standing \(standing)").font(.system(size: 13, design: .monospaced))
            ScrollView(kind % 2 == 1 ? .horizontal : .vertical) {
                if kind == 0 {
                    LazyVStack(spacing: 8) {
                        ForEach((0..<1_000).filter { !gone.contains($0) }) { row in
                            Grid {
                                Text("Row \(row)").font(.system(size: 14)).verticalAlignment(.center).gridColumn(0)
                                Button("Delete") { gone.insert(row) }
                                    .font(.system(size: 12)).contentPadding(EdgeInsets(10, 4)).gridColumn(1)
                            }
                            .columns(.fill, .auto)
                            .contentPadding(EdgeInsets(14, 4))
                            .background(.gray)
                            .onAppear { standing += 1 }
                            .onDisappear { standing -= 1 }
                        }
                    }
                } else if kind == 1 {
                    LazyHStack(spacing: 12) {
                        ForEach(1...200) { tile in
                            Text("Tile \(tile)").font(.system(size: 14)).verticalAlignment(.center)
                                .frame(width: 140).frame(height: 160).background(.gray)
                                .onAppear { standing += 1 }
                                .onDisappear { standing -= 1 }
                        }
                    }
                } else if kind == 2 {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                        ForEach(0..<500) { cell in
                            Text("\(cell)").font(.system(size: 13)).verticalAlignment(.center)
                                .frame(height: 64).frame(maxWidth: .infinity).background(.gray)
                                .onAppear { standing += 1 }
                                .onDisappear { standing -= 1 }
                        }
                    }
                } else {
                    LazyHGrid(rows: [GridItem(.fixed(64)), GridItem(.fixed(64))], spacing: 10) {
                        ForEach(0..<500) { cell in
                            Text("\(cell)").font(.system(size: 13))
                                .frame(width: 140).background(.gray)
                                .onAppear { standing += 1 }
                                .onDisappear { standing -= 1 }
                        }
                    }
                }
            }
            .frame(height: kind % 2 == 1 ? 200 : 900)
        }
        .spacing(10)
        .frame(width: 760)
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

private struct ChangingLazyPage: View {
    let grid: Bool
    @State private var rows = Array(0..<200)
    @State private var height = 40.0
    @State private var width = 200.0

    var body: some View {
        VStack {
            HStack {
                Button("Grow") { height = 80 }
                Button("Shrink") { height = 20 }
                Button("Insert") { rows.insert(contentsOf: [-2, -1], at: 0) }
                Button("Reorder") { rows.swapAt(0, 100) }
                Button("Widen") { width = 400 }
                Button("Clear") { rows = [] }
            }
            ScrollView {
                if grid {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 0) {
                        ForEach(rows) { Text("Row \($0)").frame(height: height) }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(rows) { Text("Row \($0)").frame(height: height) }
                    }
                }
            }
            .frame(width: width, height: 240)
        }
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
/// Its own state read changes the child without rebuilding the lazy source.
private struct ResizingLazyRow: View {
    let number: Int
    let varies: Bool
    let horizontal: Bool
    @Binding var extent: Double

    var body: some View {
        Text("Row \(number)")
            .frame(width: horizontal && varies ? extent : 40,
                   height: !horizontal && varies ? extent : 40)
            .transition(.opacity)
            .animation(.eased(200, .linear))
    }
}

#endif
