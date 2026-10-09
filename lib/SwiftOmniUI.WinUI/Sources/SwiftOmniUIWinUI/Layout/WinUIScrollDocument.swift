// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
import CSwiftOmniUIWinUI

/// What a ScrollView's scroller moves: its content where the core's scroll arithmetic puts it, in a document the
/// scroller makes at least as large as its viewport.
/// Design: docs/design/platforms/winui/layout.md#scrolling
@MainActor
final class WinUIScrollDocument: WinUILayoutView {
    /// The ScrollView this document is the content of; a lazy run under it
    /// climbs to it for the window.
    weak var scrollView: WinUIScrollView?

    /// The room inside the scroller's own edge, in DIPs.
    var padding = EdgeInsets(0) {
        didSet { if padding != oldValue { invalidateMeasurements() } }
    }

    var orientation = Axis.vertical {
        didSet { if orientation != oldValue { invalidateMeasurements() } }
    }

    override func contentSize(width: Double?) -> LayoutSize {
        ScrollArithmetic.contentSize(of: items.first, padding: padding, orientation: orientation, width: width)
    }

    /// Its own size is the document's: never smaller than the viewport, which the scroller sees to.
    override func arrange(in bounds: Rect) {
        guard let item = items.first, item.isShown else { return }

        let arranged = ScrollArithmetic.arrange(
            item, padding: padding, orientation: orientation,
            in: LayoutSize(width: bounds.width, height: bounds.height))
        item.view.layout(arranged.place)
        if let scrollView {
            let virtualized = scrollView.scroller.ears.contains { $0.owner is WinUILazyView }
            let offset = scrollView.scroller.nextOffset ?? scrollView.scroller.standing.offset
            swiftomniui_winui_scroller_commit(handle, offset.x, offset.y, virtualized)
        }
    }
}
