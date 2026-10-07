// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
@testable import SwiftOmniUIWinUI
import XCTest

final class WinUIGridViewTests: XCTestCase {
    /// Words with a margin in a cell are measured at the cell's width less the margin, once: on one line, as tall
    /// as without it, and the pass settles.
    func testWordsWithAMarginStandOnOneLineInTheirCell() {
        onUIThread {
            let host = WinUIRenderer.running {
                VStack {
                    Grid { Text("Waiting for the first render of this scene") }
                    Grid { Text("Waiting for the first render of this scene").padding(8, 4) }
                }
                .horizontalAlignment(.start)
            }
            let labels = host.views(WinUILabelView.self)
            XCTAssertEqual(labels.count, 2)
            XCTAssertEqual(labels[1].frame.height, labels[0].frame.height, "on one line")
            XCTAssertEqual(labels[1].frame.y, 4)
        }
    }
}
