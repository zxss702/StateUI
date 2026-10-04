// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIGTK

/// A `.mask` realized: the mask's widget held like any child - measured and
/// allocated in the same room - but drawn only inside the mask's own pass, its
/// alpha cutting the content's.
@MainActor
final class GTKMaskedView: GTKZStackView {
    /// The mask's own view: a child the panel holds and places, never drawn
    /// beside the content.
    private var maskView: GTKView? {
        didSet { gtk_widget_queue_draw(widget) }
    }

    /// The first item is the content and drawn; every further item is the
    /// mask, held so it is measured and allocated, painted only as the mask.
    @discardableResult
    override func setItems(_ items: [GTKLayoutItem]) -> Bool {
        maskView = items.count > 1 ? items[1].view : nil
        return super.setItems(items)
    }

    /// The box as the layout's, then the content under the mask's alpha: the
    /// mask rendered into the mask slot, the children into the source - the
    /// mask's own widget skipped in that pass.
    override func draw(_ snapshot: OpaquePointer, width: Double, height: Double) {
        guard let mask = maskView else {
            super.draw(snapshot, width: width, height: height)
            return
        }

        let bounds = graphene_rect_t(
            origin: graphene_point_t(x: 0, y: 0),
            size: graphene_size_t(width: Float(width), height: Float(height)))
        var outline = box.outline.rounded(bounds)
        let rounded = box.outline != .rectangle

        if box.fill != .none {
            if rounded { gtk_snapshot_push_rounded_clip(snapshot, &outline) }
            box.fill.paint(snapshot, bounds)
            if rounded { gtk_snapshot_pop(snapshot) }
        }
        if box.width > 0, let color = box.stroke.firstColor {
            var widths: [Float] = Array(repeating: Float(box.width), count: 4)
            var colors: [GdkRGBA] = Array(repeating: color, count: 4)
            gtk_snapshot_append_border(snapshot, &outline, &widths, &colors)
        }

        if box.clips { gtk_snapshot_push_rounded_clip(snapshot, &outline) }
        gtk_snapshot_push_mask(snapshot, GSK_MASK_MODE_ALPHA)
        gtk_widget_snapshot_child(widget, mask.widget, snapshot)
        gtk_snapshot_pop(snapshot)
        var child = gtk_widget_get_first_child(widget)
        while let each = child {
            if each != mask.widget {
                gtk_widget_snapshot_child(widget, each, snapshot)
            }
            child = gtk_widget_get_next_sibling(each)
        }
        gtk_snapshot_pop(snapshot)
        if box.clips { gtk_snapshot_pop(snapshot) }
    }
}
