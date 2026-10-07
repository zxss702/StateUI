// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
@testable import StateUIWinUI
import XCTest

/// Words `depth` grids deep, each grid with words and a stack of its own beside them.
private func nest(_ depth: Int, _ words: String) -> Node {
    guard depth > 0 else { return Text(words).padding(2).node }

    return Grid {
        nest(depth - 1, words)
        Text("beside \(depth)").gridRow(1)
        VStack {
            Text("a \(depth)")
            Text("b \(depth)")
        }
        .gridColumn(1)
    }
    .rows(.auto, .auto)
    .columns(.auto, .fill)
    .padding(2)
    .node
}

final class WinUIMeasurementTests: XCTestCase {
    func testArrangementUsesTheMeasurementForTheRequestedWidth() {
        onUIThread {
            let label = WinUILabelView()
            label.setText("Animate me")
            label.setTextFont(size: 17, attributes: nil, family: nil)
            let unconstrained = label.measure(width: nil, height: nil)
            let wide = label.measure(width: 400, height: nil)
            let narrow = label.measure(width: 40, height: nil)
            XCTAssertGreaterThan(narrow.height, wide.height)
            XCTAssertLessThan(narrow.width, wide.width)
            let clipped = label.measure(width: 400, height: 1)
            XCTAssertLessThan(clipped.height, wide.height)

            WinUIView.arranging += 1
            defer { WinUIView.arranging -= 1 }
            XCTAssertEqual(label.measure(width: nil, height: nil), unconstrained)
            XCTAssertEqual(label.measure(width: 400, height: nil), wide)
            XCTAssertEqual(label.measure(width: 399.7142857, height: nil), wide,
                           "native rounding must not fall back to the narrow or clipped measurement")
            XCTAssertEqual(label.measure(width: 40, height: nil), narrow)
            XCTAssertEqual(label.desiredSize, clipped, "reading a proposal must not remeasure XAML inside Arrange")
        }
    }

    func testANewArrangementWidthRepairsItsAncestorsAfterThePass() {
        onUIThread {
            let label = WinUILabelView()
            label.setText("Animate me")
            label.setTextFont(size: 17, attributes: nil, family: nil)
            let parent = WinUIZStackView()
            var item = WinUILayoutItem(view: label)
            item.values.margin = EdgeInsets(24, 16)
            parent.setItems([item])
            let grandparent = WinUIStackView(axis: .vertical)
            grandparent.setItems([WinUILayoutItem(view: parent)])
            let narrow = grandparent.naturalSize(width: 88)

            WinUIView.arranging += 1
            // This proposal has not been measured. Both ancestors must forget the provisional result,
            // even if repeated layout calculations asked for it more than once in the same pass.
            _ = grandparent.naturalSize(width: 448)
            _ = parent.naturalSize(width: 448)
            WinUIView.arranging -= 1
            WinUIDoorbell.turn()

            WinUIView.arranging += 1
            let wide = grandparent.naturalSize(width: 448)
            WinUIView.arranging -= 1
            XCTAssertGreaterThan(wide.width, narrow.width)
            XCTAssertLessThan(wide.height, narrow.height)
            let sizings = WinUILayoutView.sizings
            WinUIDoorbell.turn()
            XCTAssertEqual(grandparent.naturalSize(width: 448), wide)
            XCTAssertEqual(WinUILayoutView.sizings, sizings, "a known proposal must settle without another turn")
        }
    }

    func testChangedWordsAndFontDiscardMeasurementsAtOtherWidths() {
        onUIThread {
            let label = WinUILabelView()
            label.setText("short")
            label.setTextFont(size: 12, attributes: nil, family: nil)
            let before = label.measure(width: 400, height: nil)
            label.setText("Words changed after both wide and narrow proposals were cached")
            label.setTextFont(size: 24, attributes: nil, family: nil)
            // A measured property patch invalidates its native view through WinUIElement.
            label.invalidateMeasure()
            _ = label.measure(width: 80, height: nil)

            let reference = WinUILabelView()
            reference.setText(label.text)
            reference.setTextFont(size: 24, attributes: nil, family: nil)
            let expected = reference.measure(width: 400, height: nil)
            XCTAssertNotEqual(expected, before)

            WinUIView.arranging += 1
            _ = label.measure(width: 400, height: nil)
            WinUIView.arranging -= 1
            WinUIDoorbell.turn()
            WinUIView.arranging += 1
            defer { WinUIView.arranging -= 1 }
            XCTAssertEqual(label.measure(width: 400, height: nil), expected)
        }
    }

    func testGalleryTextKeepsItsNaturalSizeAndScrollSummaryHeight() throws {
        try onUIThread {
            let width = State(wrappedValue: 480.0)
            let words = State(wrappedValue: "Animate me")
            let font = State(wrappedValue: 17.0)
            let summary = "Fade, move, scale and spin a view - a state write inside withAnimation."
            let host = WinUIRenderer.running(reducesMotion: true) {
                ScrollView {
                    VStack {
                        Text(summary).font(.system(size: 15)).id("summary")
                        Text("Example")
                        ZStack {
                            VStack {
                                ZStack {
                                    Text(words.wrappedValue)
                                        .font(.system(size: font.wrappedValue))
                                        .padding(EdgeInsets(24, 16))
                                        .id("animated-label")
                                }
                                .background(Color("#4828D6"))
                                .shape(.roundedRectangle(32))
                                .clipsContent(true)
                                .horizontalAlignment(.center)
                                .id("capsule")
                                HStack { Button("Fade"); Button("Move"); Button("Scale"); Button("Spin") }
                                    .spacing(8)
                                    .horizontalAlignment(.center)
                            }
                            .spacing(12)
                            .contentPadding(16)
                        }
                        Text("Notes below the example").frame(height: 900)
                    }
                    .spacing(24)
                    .contentPadding(24)
                }
                .frame(width: width.wrappedValue)
                .horizontalAlignment(.start)
            }
            let label = try XCTUnwrap(host.view(id: .manual("animated-label")) as? WinUILabelView)
            let heading = try XCTUnwrap(host.view(id: .manual("summary")) as? WinUILabelView)
            let capsule = try XCTUnwrap(host.view(id: .manual("capsule")))
            let probe = WinUILabelView()
            let summaryProbe = WinUILabelView()
            summaryProbe.setText(summary)
            summaryProbe.setTextFont(size: 15, attributes: nil, family: nil)

            for (index, offered) in [480.0, 280.0, 480.0].enumerated() {
                withAnimation(nil) {
                    width.wrappedValue = offered
                    if index == 2 {
                        words.wrappedValue = "Animate again"
                        font.wrappedValue = 20
                    }
                }
                for _ in 0..<8 { host.step(); host.layOut() }
                probe.setText(words.wrappedValue)
                probe.setTextFont(size: font.wrappedValue, attributes: nil, family: nil)
                let oneLine = probe.measure(width: nil, height: nil)
                let expectedSummary = summaryProbe.measure(width: offered - 48, height: nil)
                let labelPlace = try XCTUnwrap(label.placed)
                let summaryPlace = try XCTUnwrap(heading.placed)
                let capsulePlace = try XCTUnwrap(capsule.placed)

                XCTAssertEqual(labelPlace.width, oneLine.width, accuracy: 1, "padding must not narrow the words")
                XCTAssertEqual(labelPlace.height, oneLine.height, accuracy: 1, "the capsule stays on one line")
                XCTAssertEqual(capsulePlace.width, oneLine.width + 48, accuracy: 1)
                XCTAssertEqual(capsulePlace.height, oneLine.height + 32, accuracy: 1)
                XCTAssertEqual(summaryPlace.height, expectedSummary.height, accuracy: 1, "no clipped summary")
                XCTAssertEqual(heading.laidOutFrame.height, expectedSummary.height, accuracy: 1)
                XCTAssertEqual(summaryPlace.y, 24, accuracy: 1)
                let sizings = WinUILayoutView.sizings
                for _ in 0..<4 { host.step(); host.layOut() }
                XCTAssertEqual(WinUILayoutView.sizings, sizings, "the text layout must settle")
            }
        }
    }

    /// A change sizes only the layouts above it, each once for each width it is asked about: words changing six
    /// grids deep leave every layout beside them as it was sized - a layout measured at every width asked of it
    /// sized its whole subtree again each time.
    func testAChangeSizesOnlyTheLayoutsAboveIt() {
        onUIThread {
            let words = State(wrappedValue: "short")
            let host = WinUIRenderer.running { ModifiedContent(node: nest(6, words.wrappedValue)) }
            host.layOut()

            let before = WinUILayoutView.sizings
            words.wrappedValue = "words a good deal longer"
            host.settle { host.views(WinUILabelView.self).contains { $0.text == "words a good deal longer" } }
            host.layOut()

            XCTAssertLessThanOrEqual(WinUILayoutView.sizings - before, 60, "a few for each grid above it, none beside")
        }
    }
}
