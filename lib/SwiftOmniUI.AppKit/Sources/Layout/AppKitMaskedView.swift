// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import QuartzCore
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// A `.mask` realized: the content laid out in the room, and the mask laid
/// out in the same room but never shown - where the mask draws opaque the
/// content shows, its alpha cut out of a snapshot the layer's mask holds.
@MainActor
final class AppKitMaskedView: AppKitZStackView {
    /// The mask's own view, laid out with the rest but never put on screen.
    private var maskView: NSView?

    /// The layer the snapshot is handed to the compositor through.
    private let maskLayer = CALayer()

    /// The first item is the content and shown; every further item is the
    /// mask, kept off the tree and drawn only for its alpha.
    override func setItems(_ items: [AppKitLayoutItem]) {
        maskView = items.count > 1 ? items[1].view : nil
        super.setItems(Array(items.prefix(1)))
        needsLayout = true
    }

    override func layout() {
        super.layout()

        guard let mask = maskView, bounds.width > 0, bounds.height > 0 else {
            layer?.mask = nil
            return
        }

        mask.frame = NSRect(origin: .zero, size: bounds.size)
        mask.layoutSubtreeIfNeeded()

        guard let rep = mask.bitmapImageRepForCachingDisplay(in: mask.bounds) else {
            layer?.mask = nil
            return
        }
        mask.cacheDisplay(in: mask.bounds, to: rep)

        maskLayer.frame = NSRect(origin: .zero, size: bounds.size)
        maskLayer.contents = rep.cgImage
        wantsLayer = true
        layer?.mask = maskLayer
    }
}

#endif
