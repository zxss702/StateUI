// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
import CSwiftOmniUIGTK

/// What a ScrollView's scroller moves: its content where the core's scroll arithmetic puts it, in a document the
/// viewport makes at least as large as itself.
/// Design: docs/design/platforms/gtk/layout.md#scrolling
@MainActor
final class GTKScrollDocument: GTKLayoutView {
    /// The room inside the scroller's own edge.
    var padding = EdgeInsets(0) {
        didSet { if padding != oldValue { invalidateMeasurements() } }
    }

    var orientation = Axis.vertical {
        didSet { if orientation != oldValue { invalidateMeasurements() } }
    }

    override func contentSize(width: Double?) -> LayoutSize {
        ScrollArithmetic.contentSize(of: items.first, padding: padding, orientation: orientation, width: width)
    }

    override func arrange(in bounds: Rect) {
        guard let item = items.first, item.isShown else { return }

        let arranged = ScrollArithmetic.arrange(
            item, padding: padding, orientation: orientation,
            in: LayoutSize(width: bounds.width, height: bounds.height))
        #if DEBUG
        let parent = gtk_widget_get_parent(widget)
        let vp = parent.map { Double(gtk_widget_get_width($0)) } ?? -1
        let scroller = parent.flatMap { gtk_widget_get_parent($0) }
        var sx = 0.0, sy = 0.0
        if let scroller, let top = gtk_widget_get_toplevel(scroller) {
            var ox = 0.0, oy = 0.0
            if gtk_widget_translate_coordinates(scroller, top, 0, 0, &ox, &oy) != 0 { sx = ox; sy = oy }
        }
        let sa = scroller.map { "\(gtk_widget_get_allocated_width($0))x\(gtk_widget_get_allocated_height($0))" } ?? "nil"
        GTKRenderer.log.note("SCROLL-DOC scroller=\(sa)@\(sx),\(sy) viewport=\(vp) doc=\(bounds.width)x\(bounds.height) item=\(Swift.type(of: item.view)) h=\(item.values.horizontal) w=\(String(describing: item.values.width)) max=\(String(describing: item.values.maximumWidth)) place=\(arranged.place)")
        #endif
        item.view.layout(arranged.place)
    }
}
