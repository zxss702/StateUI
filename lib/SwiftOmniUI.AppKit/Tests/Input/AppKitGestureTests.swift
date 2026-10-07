// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) @testable import SwiftOmniUI
@_spi(Host) @testable import SwiftOmniUIHost
@testable import SwiftOmniUIAppKit
import SwiftOmniUIConformance
import XCTest

final class AppKitGestureTests: XCTestCase {
    @MainActor
    func testRemovingPointerEventsDetachesTheNativeRecognizer() throws {
        let renderer = testRenderer(resourceDirectory: nil, presentsWindows: false)
        defer { renderer.closeForTesting() }
        var box = HostPatch(id: .manual("box"), type: .colorPicker)
        box.events = .replace([.pointerEntered: 20])
        renderer.applyForTesting(tree(box))
        let native = try XCTUnwrap(renderer.viewForTesting(id: .manual("box")))
        XCTAssertEqual(
            native.gestureRecognizers.compactMap { $0 as? AppKitPointerRecognizer }.count,
            1)

        var changed = HostPatch(id: .manual("box"), type: .colorPicker)
        changed.events = .replace([:])
        renderer.applyForTesting(changedTree(changed))

        XCTAssertTrue(
            native.gestureRecognizers.compactMap { $0 as? AppKitPointerRecognizer }.isEmpty)
    }

    /// A pan asked of one pointer is recognised and reaches its handler. A
    /// pan asked of two leaves the view no pan recogniser: AppKit recognises a
    /// one-pointer drag only, so it cannot honour that count.
    @MainActor
    func testOnlyAOnePointerPanIsRecognised() throws {
        let totals = Received<Double>()
        let renderer = AppKitRenderer.running {
            VStack {
                ColorPicker(.red).onPanUpdated(touchCount: 1) { totals.values.append($0.totalX) }
                ColorPicker(.blue).onPanUpdated(touchCount: 2) { totals.values.append($0.totalX) }
            }
        }
        defer { renderer.closeForTesting() }
        let boxes = renderer.nativeViews(AppKitColorBoxView.self)
        XCTAssertEqual(boxes.count, 2)
        guard boxes.count == 2 else { return }
        let onePointer = boxes[0].gestureRecognizers.compactMap { $0 as? AppKitPanRecognizer }
        let twoPointers = boxes[1].gestureRecognizers.compactMap { $0 as? AppKitPanRecognizer }

        XCTAssertEqual(onePointer.count, 1)
        XCTAssertTrue(twoPointers.isEmpty)

        onePointer.first?.dragged(
            .running, x: 8, y: 5, at: Point(x: 18, y: 15), from: Point(x: 10, y: 10))

        XCTAssertEqual(totals.values, [8])
    }

    /// A view that answers a tap takes the first click into an inactive window,
    /// as a native control does - so a row opens wherever it is clicked, not only
    /// on its text. A view that answers nothing leaves that click to activate
    /// the window.
    @MainActor
    func testAViewThatAnswersATapTakesTheFirstClick() throws {
        let renderer = AppKitRenderer.running {
            VStack {
                HStack { Text("Fundamentals") }.onTapGesture {}
                HStack { Text("Plain") }
            }
        }
        defer { renderer.closeForTesting() }
        let stacks = renderer.nativeViews(AppKitStackView.self)
        XCTAssertEqual(stacks.count, 3)

        XCTAssertTrue(stacks[1].acceptsFirstMouse(for: nil), "the row that answers a tap")
        XCTAssertFalse(stacks[2].acceptsFirstMouse(for: nil), "the row that answers nothing")
        XCTAssertFalse(stacks[0].acceptsFirstMouse(for: nil), "the stack around them")
    }
}

#endif
