// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// Where the element stands, said to the tree that reads it by the host layer's rule: after anything was laid out,
/// on the display's next frame.
/// Design: docs/design/host/runtime.md#where-a-view-stands
extension UIKitElement: FrameReporter {
    /// Whether the tree reads where this element stands, and it has a view to stand.
    var readsFrame: Bool {
        view != nil && element.readsOwnFrame
    }

    /// Says where the element stands, where that changed (`MountedElement.reportFrame`).
    func reportFrame() {
        guard let host, let numbers = frameNumbers() else { return }
        let named = element.namedSpaceFrames { ancestor in
            guard let ancestorView = (ancestor.native as? UIKitElement)?.view,
                  let window = ancestorView.window else { return nil }
            let frame = ancestorView.convert(ancestorView.bounds, to: window)
            return Rect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
        }
        element.reportFrame(numbers, named: named, in: host.runtime)
    }

    /// Where the view stands now: in its parent, in its window, and from the safe area the window's pages stand in;
    /// nil for a view in no window, or one no layout placed yet - StateUI's, or UIKit's giving it a size.
    func frameNumbers() -> [Double]? {
        guard let view, let window = view.window, isPlaced || view.bounds.size != .zero else { return nil }
        let corner = view.convert(view.bounds, to: window).origin
        let insets = window.safeAreaInsets
        return MountedElement.frameNumbers(
            place: placedFrame, corner: Point(x: corner.x, y: corner.y),
            safeArea: Rect(
                x: insets.left, y: insets.top,
                width: window.bounds.width - insets.left - insets.right,
                height: window.bounds.height - insets.top - insets.bottom))
    }
}

extension UIKitScrollView: FramedScroller {}
#endif
