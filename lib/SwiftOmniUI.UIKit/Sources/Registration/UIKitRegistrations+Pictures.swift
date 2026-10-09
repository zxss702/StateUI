// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

extension UIKitRegistrations {
    /// An Image - one of the application's pictures, filling its room as its aspect says - and a ColorPicker: one colour
    /// with its corners rounded.
    static func pictures(_ registry: Registry<UIView>) {
        registry.add(ImageContract.self, create: { _ in UIKitImageView() }) { image in
            image.applies([ImageContract.source, ImageElementContract.aspect, ImageContract.isResizable]) { view, values in
                let aspect = values[ImageContract.isResizable] == true
                    ? values[ImageElementContract.aspect] ?? .stretch : .center
                view.apply(source: values[ImageContract.source], aspect: aspect)
            }
        }
        registry.add(ColorPickerContract.self, create: { _ in UIKitColorBoxView() }) { box in
            box.applies([ColorPickerContract.color, ColorPickerContract.cornerRadius]) { view, values in
                view.apply(
                    color: values[ColorPickerContract.color]?.propValue,
                    corners: values[ColorPickerContract.cornerRadius]?.propValue)
            }
        }
    }
}
#endif
