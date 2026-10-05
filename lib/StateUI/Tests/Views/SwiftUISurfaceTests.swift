// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The SwiftUI-surface additions that compose on what the library already
// knows: `Font.default`, `UnevenRoundedRectangle`, `ContentUnavailableView`,
// `defaultFocus`, `geometryGroup`, the `urlOpened` application event a host
// raises for `.onOpenURL`, and a window scene's `defaultPosition`.

import XCTest
@_spi(Host) @testable import StateUI

private struct MainWindow: WindowScene {
    var page: any Page { ModifiedContent(node: label("main")) }
}

final class SwiftUISurfaceTests: XCTestCase {
    // MARK: - Font.default

    /// `Font.default` reads as ordinary body text, as SwiftUI's does.
    func testFontDefaultIsTheBodyTextStyle() {
        XCTAssertEqual(Font.default, .body)
    }

    // MARK: - UnevenRoundedRectangle

    /// Each corner's radius crosses in its own place - leading and trailing
    /// by the platform's language direction, which here is left to right.
    func testUnevenRoundedRectangleCarriesEachCornersRadius() {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 4, topTrailingRadius: 2,
            style: .continuous)

        XCTAssertEqual(shape.node.type, "Rectangle")
        XCTAssertEqual(
            shape.node.props[RectangleContract.cornerRadius.token],
            CornerRadius.corners(topLeft: 8, topRight: 2, bottomLeft: 0, bottomRight: 4).propValue)
    }

    /// A `RectangleCornerRadii` names the same four corners.
    func testRectangleCornerRadiiNamesAllFourCorners() {
        let radii = RectangleCornerRadii(topLeading: 1, topTrailing: 2, bottomLeading: 3, bottomTrailing: 4)
        let shape = UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)

        XCTAssertEqual(shape.cornerRadii, radii)
        XCTAssertEqual(
            shape.node.props[RectangleContract.cornerRadius.token],
            CornerRadius.corners(topLeft: 1, topRight: 2, bottomLeft: 3, bottomRight: 4).propValue)
    }

    // MARK: - ContentUnavailableView

    /// A label, a description and the actions stand in a column.
    func testContentUnavailableViewBuildsItsParts() throws {
        var node = ContentUnavailableView(
            "No Results", systemImage: "magnifyingglass", description: "Try again"
        ).body.node
        node.materialize()

        var texts: [String] = []
        walkTexts(in: node, into: &texts)
        XCTAssertTrue(texts.contains { $0.contains("No Results") })
        XCTAssertTrue(texts.contains { $0.contains("Try again") })
    }

    /// Collects every `Text` node's words, depth first.
    private func walkTexts(in node: Node, into texts: inout [String]) {
        if node.type == "Text", let words = node.props[TextElementContract.text.token]?.string {
            texts.append(words)
        }
        for child in node.children {
            var child = child
            child.materialize()
            walkTexts(in: child, into: &texts)
        }
    }

    // MARK: - defaultFocus

    /// `defaultFocus` asks for the focus when the element stands - an
    /// `onAppear` written on the node.
    func testDefaultFocusAsksWhenTheElementStands() {
        let binding = Binding<Bool>(get: { false }, set: { _ in })

        let node = Text("field")
            .defaultFocus(binding, true)
            .node

        XCTAssertFalse(node.created.isEmpty, "the default-focus ask stands on the element's creation")
    }

    // MARK: - geometryGroup

    /// `geometryGroup` adds nothing - the space is already one.
    func testGeometryGroupLeavesTheNodeAlone() {
        let plain = Text("words").node
        let grouped = Text("words").geometryGroup().node

        XCTAssertEqual(grouped.type, plain.type)
        XCTAssertEqual(grouped.props.count, plain.props.count)
        XCTAssertEqual(grouped.events.count, plain.events.count)
    }

    // MARK: - urlOpened

    /// A view hears the application's URL-opened event - the road
    /// `.onOpenURL` rides, built where Foundation's `URL` may stand.
    func testURLOpenedIsHeardThroughHearing() async throws {
        var heard: String?
        let node = Text("page").hearing(AppContract.urlOpened) { text in
            heard = text
        }.node

        let handler = try XCTUnwrap(node.events[.urlOpened])
        EventBuffer.current = MemberValues.encode("file:///tmp/place")
        defer { EventBuffer.current = [] }
        try await handler()

        XCTAssertEqual(heard, "file:///tmp/place")
    }

    // MARK: - defaultPosition

    /// `.defaultPosition` writes the anchor on the group.
    func testDefaultPositionWritesTheAnchor() {
        let group = WindowGroup(WindowType("main")) { MainWindow() }
            .defaultPosition(.center)

        XCTAssertEqual(group.defaultPosition, .center)
    }

    /// The fractions spelling writes the same anchor.
    func testDefaultPositionByFractions() {
        let group = WindowGroup(WindowType("main")) { MainWindow() }
            .defaultPosition(x: 0.25, y: 0.75)

        XCTAssertEqual(group.defaultPosition, UnitPoint(x: 0.25, y: 0.75))
    }
}
