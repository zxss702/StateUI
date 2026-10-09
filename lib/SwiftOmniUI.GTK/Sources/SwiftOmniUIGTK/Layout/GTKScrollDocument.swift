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
        let sa = scroller.map { "\(gtk_widget_get_width($0))x\(gtk_widget_get_height($0))" } ?? "nil"
        GTKRenderer.log.note("SCROLL-DOC scroller=\(sa) viewport=\(vp) doc=\(bounds.width)x\(bounds.height) item=\(Swift.type(of: item.view)) h=\(item.values.horizontal) w=\(String(describing: item.values.width)) max=\(String(describing: item.values.maximumWidth)) place=\(arranged.place)")
        dumpOnce()
        #endif
        item.view.layout(arranged.place)
    }
}

#if DEBUG
@MainActor private var dumped = 0
@MainActor private func dumpOnce() {
    dumped += 1
    guard dumped == 12, let any = GTKRenderer.shared?.window?.widget else { return }
    func name(of w: GTKWidget) -> String {
        let inst: UnsafeMutablePointer<GTypeInstance> = w.of()
        return inst.pointee.g_class.flatMap { g_type_name($0.pointee.g_type) }.map { String(cString: $0) } ?? "?"
    }
    func walk(_ w: GTKWidget?, _ depth: Int) {
        guard let w else { return }
        var x = 0.0, y = 0.0
        if let top = gtk_widget_get_native(w) {
            let dest: GTKWidget = UnsafeMutablePointer<GtkWidget>(OpaquePointer(top))
            _ = gtk_widget_translate_coordinates(w, dest, 0, 0, &x, &y)
        }
        GTKRenderer.log.note("TREE \(String(repeating: " ", count: depth))\(name(of: w)) \(gtk_widget_get_width(w))x\(gtk_widget_get_height(w))@\(Int(x)),\(Int(y))")
        walk(gtk_widget_get_first_child(w), depth + 1)
        walk(gtk_widget_get_next_sibling(w), depth)
    }
    walk(any, 0)
}
#endif
