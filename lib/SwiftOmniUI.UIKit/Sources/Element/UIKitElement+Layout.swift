// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// What a layout holds: its children's views, each as the item the host layer's arithmetic places; and a label, the
/// runs of its spans.
extension UIKitElement {
    /// The view lays out, and its control writes, in the element's direction.
    func directionChanged() {
        view?.semanticContentAttribute = element.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    }

    func arrangeChildren() {
        if let items = view as? UIKitItemsView { return items.childrenChanged() }
        if let lazy = view as? UIKitLazyView {
            if lazy.cells.takeItems() {
                lazy.measured = [:]
                lazy.invalidateMeasurements()
            }
            lazy.direction = element.layoutDirection
            lazy.laidOut = { [weak host] in host?.runtime.frames.laidOut() }
            lazy.setItems(element.arrangedChildren.compactMap { child in
                guard case .manual(let identity) = child.id, let item = child.uiKit.layoutItem
                else { return nil }
                return (child.lazyIdentity ?? identity, item)
            })
            return
        }
        if let label = view as? UIKitLabelView { return label.setRuns(element.textRuns) }
        guard let layout = view as? UIKitLayoutView else { return }
        layout.direction = element.layoutDirection
        layout.laidOut = { [weak host] in host?.runtime.frames.laidOut() }
        layout.setItems(element.arrangedChildren.compactMap { $0.uiKit.layoutItem })
    }

    /// What this element gives the layout it stands in: its view, or the first view of an element drawn by its
    /// parent.
    var layoutItem: UIKitLayoutItem? {
        guard let view else { return children.lazy.compactMap(\.layoutItem).first }

        var item = UIKitLayoutItem(view: view, values: element.layoutValues, isShown: element.standsShown)
        item.mount = element.mount
        item.departing = element.isDeparting
        item.placed = self
        item.drawing = drawing
        if fadesIn {
            item.fadeIn = { [weak self] animation, room in self?.fadeIn(under: animation, room: room) }
        }
        return item
    }
}
#endif
