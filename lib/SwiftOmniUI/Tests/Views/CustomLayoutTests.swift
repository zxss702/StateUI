// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) @testable import SwiftOmniUI
import XCTest

/// A `Layout`'s calls are code, so the differ keeps the object by element
/// identity and the host pulls it back; `.layoutValue` rides the same
/// registry on the child that wrote it.
@MainActor final class CustomLayoutTests: XCTestCase {
    /// A tag for the tests.
    private enum SpacingKey: LayoutValueKey {
        static let defaultValue = 0.0
    }

    /// A second tag, for the default answer.
    private enum TagKey: LayoutValueKey {
        static let defaultValue = "none"
    }

    /// A layout that records each pass it is asked to run.
    private final class SpyLayout: Layout, @unchecked Sendable {
        typealias Cache = Int

        /// The times `makeCache` ran.
        var made = 0

        /// The proposals `sizeThatFits` was asked.
        var measured: [ProposedViewSize] = []

        /// The bounds `placeSubviews` was given.
        var placed: [(Rect, ProposedViewSize)] = []

        /// The times `updateCache` ran, and the cache it left.
        var updated: [Int] = []

        func makeCache(subviews: Subviews) -> Int {
            made += 1
            return 7
        }

        func updateCache(_ cache: inout Int, subviews: Subviews) {
            cache += 1
            updated.append(cache)
        }

        func sizeThatFits(
            proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache
        ) -> SwiftOmniUI.Size {
            measured.append(proposal)
            return Size(width: 10 * Double(subviews.count) + Double(cache), height: 20)
        }

        func placeSubviews(
            in bounds: Rect, proposal: ProposedViewSize,
            subviews: Subviews, cache: inout Cache
        ) {
            placed.append((bounds, proposal))
            var y = bounds.y
            for subview in subviews {
                subview.place(at: Point(x: bounds.x, y: y), proposal: .unspecified)
                y += 20
            }
        }
    }

    /// A differ's patch and registry for `view`.
    private func differed(_ view: some View) -> (Differ, HostPatch) {
        let differ = Differ()
        let result = differ.reconcile(nil, with: view.node)
        return (differ, result.patch)
    }

    func testACallAsFunctionOnALayoutMakesACustomLayoutContainer() {
        let layout = SpyLayout()
        let (_, patch) = differed(layout { Text("a") })

        XCTAssertEqual(patch.type, "CustomLayout")
        XCTAssertEqual(patch.children.count, 1)
        XCTAssertEqual(patch.children.first?.type, "Text")
    }

    func testTheLayoutObjectRidesTheRegistryByElementId() {
        let layout = SpyLayout()
        let (differ, patch) = differed(layout { Text("a") })

        XCTAssertNotNil(differ.codeObjects(for: patch.id)?.layout)
    }

    func testALayoutValueRidesTheChildThatWroteIt() {
        let layout = SpyLayout()
        let (differ, patch) = differed(layout {
            Text("a").layoutValue(key: SpacingKey.self, value: 5)
            Text("b")
        })

        let tagged = patch.children[0]
        let plain = patch.children[1]
        XCTAssertEqual(
            differ.codeObjects(for: tagged.id)?.values[ObjectIdentifier(SpacingKey.self)] as? Double, 5)
        XCTAssertNil(differ.codeObjects(for: plain.id)?.values[ObjectIdentifier(SpacingKey.self)])
    }

    func testAFragmentSpreadsTheValueToTheChildrenItStandsFor() {
        let layout = SpyLayout()
        let (differ, patch) = differed(layout {
            Group {
                Text("a")
                Text("b")
            }
            .layoutValue(key: SpacingKey.self, value: 3)
        })

        for child in patch.subtree where child.type == "Text" {
            XCTAssertEqual(
                differ.codeObjects(for: child.id)?.values[ObjectIdentifier(SpacingKey.self)] as? Double, 3)
        }
    }

    func testTheCodeObjectDiesWithItsElement() {
        let layout = SpyLayout()
        let differ = Differ()
        let first = differ.reconcile(nil, with: layout { Text("a") }.id("flow").node)
        XCTAssertNotNil(differ.codeObjects(for: first.patch.id)?.layout)

        _ = differ.reconcile(first.node, with: Text("gone").id("flow").node)
        XCTAssertNil(differ.codeObjects(for: .manual("flow")))
    }

    func testTheBoxRunsMeasureAndPlaceWithOneCache() {
        let layout = SpyLayout()
        let box = LayoutBox(layout)
        var placedAt: [Point] = []
        let subviews = LayoutSubviews([
            LayoutSubview(
                layoutValues: [:], priority: 0,
                measureSize: { _ in Size(width: 5, height: 5) },
                measureDimensions: { _ in ViewDimensions() },
                placeView: { position, _, _ in placedAt.append(position) })
        ])

        let size = box.measure(
            proposal: ProposedViewSize(width: 50), subviews: subviews)
        box.place(
            in: Rect(x: 1, y: 2, width: 50, height: 20),
            proposal: ProposedViewSize(width: 50, height: 20), subviews: subviews)
        box.update(subviews: subviews)

        XCTAssertEqual(layout.made, 1, "one arrangement makes the cache once")
        XCTAssertEqual(size, Size(width: 17, height: 20))
        XCTAssertEqual(layout.measured, [ProposedViewSize(width: 50)])
        XCTAssertEqual(layout.placed.count, 1)
        XCTAssertEqual(placedAt, [Point(x: 1, y: 2)])
        XCTAssertEqual(layout.updated, [8])
    }

    func testASubviewAnswersTheTagOrTheKeysDefault() {
        var read: (spacing: Double, tag: String)?
        let subview = LayoutSubview(
            layoutValues: [ObjectIdentifier(SpacingKey.self): 9.0], priority: 4,
            measureSize: { _ in Size(width: 0, height: 0) },
            measureDimensions: { _ in ViewDimensions() },
            placeView: { _, _, _ in })
        read = (subview[SpacingKey.self], subview[TagKey.self])

        XCTAssertEqual(read?.spacing, 9)
        XCTAssertEqual(read?.tag, "none")
        XCTAssertEqual(subview.priority, 4)
    }
}
