// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

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
    /// nil for a view in no window, or one no layout placed yet - SwiftOmniUI's, or UIKit's giving it a size.
    func frameNumbers() -> [Double]? {
        guard let view, let window = view.window, isPlaced || view.bounds.size != .zero else { return nil }
        let corner = view.convert(view.bounds, to: window).origin
        let safe = Self.safeCorner(of: view, in: window)
        return MountedElement.frameNumbers(
            place: placedFrame, corner: Point(x: corner.x, y: corner.y),
            safeArea: Rect(
                x: safe.x, y: safe.y,
                width: window.bounds.width - window.safeAreaInsets.left - window.safeAreaInsets.right,
                height: window.bounds.height - window.safeAreaInsets.top - window.safeAreaInsets.bottom))
    }

    /// The window's safe area's corner in its own coordinates, down to the page's: a page stands clear of the
    /// window's own controls too.
    private static func safeCorner(of view: UIView, in window: UIWindow) -> CGPoint {
        var responder: UIResponder? = view
        while let each = responder, !(each is UIKitPageController) { responder = each.next }
        guard let page = responder as? UIKitPageController, let view = page.view else {
            return CGPoint(x: window.safeAreaInsets.left, y: window.safeAreaInsets.top)
        }
        return view.convert(view.bounds.inset(by: page.safeInsets).origin, to: window)
    }
}

extension UIKitScrollView: FramedScroller {}
#endif
