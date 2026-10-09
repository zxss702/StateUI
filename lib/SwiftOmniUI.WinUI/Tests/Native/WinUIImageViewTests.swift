// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import CSwiftOmniUIWinUI
import Foundation
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
@testable import SwiftOmniUIWinUI
import XCTest

final class WinUIImageViewTests: XCTestCase {
    /// A new file is decoded before apply returns, without pumping the UI queue or relying on its metadata.
    func testABitmapIsDecodedBeforeApplyReturns() throws {
        try onUIThread {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(atPath: WinUITestHost.pictures + "/test_dot.png", toPath: folder.path + "/dot.png")
            swiftomniui_winui_set_pictures(folder.path)
            defer {
                swiftomniui_winui_set_pictures(WinUITestHost.pictures)
                try? FileManager.default.removeItem(at: folder)
            }
            let image = WinUIImageView()
            image.apply(source: ImageSource("dot.png"), aspect: .fit)
            var size = [0.0, 0.0]
            swiftomniui_winui_image_size(image.handle, &size)
            XCTAssertEqual(size, [6, 4])
            XCTAssertEqual(image.measure(width: nil, height: nil), LayoutSize(width: 6, height: 4))
        }
    }

    /// A decoded bitmap gives its ancestors their final size at the first layout.
    func testABitmapSizesItsAncestorsAtTheFirstLayout() throws {
        try onUIThread {
            let host = WinUIRenderer.running {
                VStack { HStack { Image("test_dot.png") } }
                    .horizontalAlignment(.start)
                    .verticalAlignment(.start)
            }
            let row = try XCTUnwrap(host.views(WinUIStackView.self).last)
            XCTAssertTrue(row.frame == (0, 0, 6, 4), "\(row.frame)")
            host.step()
            XCTAssertTrue(row.frame == (0, 0, 6, 4), "\(row.frame)")
        }
    }

    /// An SVG stands at the size it declares: its width and height, the one it leaves out taken from its viewBox's
    /// proportions, or its viewBox alone.
    func testAnSVGStandsAtTheSizeItDeclares() throws {
        try onUIThread {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("swiftomniui-winui-svg")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let figure = "<rect width=\"10\" height=\"10\" fill=\"red\"/></svg>"
            let pictures: [(name: String, tag: String, width: Double, height: Double)] = [
                ("sized.svg", "width=\"30\" height=\"20\" viewBox=\"0 0 3 2\"", 30, 20),
                ("boxed.svg", "viewBox=\"0 0 40 10\"", 40, 10),
                ("wide.svg", "width=\"60\" viewBox=\"0,0,40,10\"", 60, 15),
                ("tall.svg", "height=\"30pt\" viewBox=\"0 0 10 20\"", 20, 40),
            ]
            for picture in pictures {
                try "<svg xmlns=\"http://www.w3.org/2000/svg\" \(picture.tag)>\(figure)".write(
                    to: folder.appendingPathComponent(picture.name), atomically: true, encoding: .utf8)
            }
            swiftomniui_winui_set_pictures(folder.path)
            defer { swiftomniui_winui_set_pictures("") }

            for picture in pictures {
                let host = WinUIRenderer.running {
                    VStack { HStack { Image(ImageSource(picture.name)) } }
                        .horizontalAlignment(.start)
                        .verticalAlignment(.start)
                }
                let row = try XCTUnwrap(host.views(WinUIStackView.self).last)
                host.settle { row.frame.width == picture.width }

                XCTAssertTrue(row.frame == (0, 0, picture.width, picture.height), "\(picture.name): \(row.frame)")
            }
        }
    }
}
