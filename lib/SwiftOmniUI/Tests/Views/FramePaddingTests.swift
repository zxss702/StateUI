// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import XCTest
@_spi(Host) @testable import SwiftOmniUICore

private struct PaddedFrameLabel: View {
    var body: some View { Text("card").padding(16) }
}

@MainActor final class FramePaddingTests: XCTestCase {
    func testAFramePreservesItsComposedContentsAndLaterFont() {
        let patch = Renders().render(PaddedFrameLabel().frame(width: 256, height: 256).font(.system(size: 24)).node)
        XCTAssertEqual(patch.props["width"], .number(256))
        XCTAssertEqual(patch.props["height"], .number(256))
        XCTAssertEqual(patch.children.first?.props["text"], .string("card"))
        XCTAssertEqual(patch.children.first?.props["padding"], .numbers([16, 16, 16, 16]))
        XCTAssertEqual(patch.children.first?.props["fontSize"], .number(24))
    }

    func testAFramedControlStillAcceptsItsNativePadding() {
        let node = Button(icon: "test.png").padding(16).frame(width: 40).frame(height: 40)
            .contentPadding(8).onClicked {}.node
        XCTAssertEqual(node.props[.width], .number(40))
        XCTAssertEqual(node.props[.height], .number(40))
        XCTAssertEqual(node.children.first?.props[.contentPadding], .numbers([8, 8, 8, 8]))
        XCTAssertNotNil(node.children.first?.events[.clicked])
    }
}
