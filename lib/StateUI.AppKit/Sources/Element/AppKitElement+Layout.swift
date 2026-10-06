// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// Children placed: the layout item each child gives its parent.
extension AppKitElement {
    /// The view lays out, and its control writes, in the element's direction.
    func directionChanged() {
        view?.userInterfaceLayoutDirection = element.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    func arrangeChildren() {
        guard let view else { return }
        if let items = view as? AppKitItemsView { return items.childrenChanged() }
        let items = children.compactMap(\.layoutItem)
        (view as? AppKitDirectedLayout)?.direction = element.layoutDirection

        if let label = view as? AppKitLabelView {
            label.apply(
                attributedText: attributedLabelText(),
                padding: insets(.contentPadding),
                horizontalAlignment: textAlignment(enumeration(.multilineTextAlignment)),
                verticalAlignment: AppKitVerticalTextAlignment(
                    rawValue: enumeration(.verticalTextAlignment) ?? 0) ?? .start,
                breaking: lineBreak,
                maximumNumberOfLines: lineLimit(),
                selectable: value(.selectable)?.bool ?? false)
            return
        }

        if let stack = view as? AppKitStackView {
            stack.setItems(items)
            return
        }

        if let lazy = view as? AppKitLazyView {
            lazy.cells.takeItems()
            lazy.setItems(children.compactMap { child in
                guard case .manual(let identity) = child.id, let item = child.layoutItem
                else { return nil }
                return (identity, item)
            })
            return
        }

        if let split = view as? AppKitSplitView {
            split.apply(
                sidebarWidth: children.first?.value(.preferredColumnWidth)?.numbers,
                contentWidth: children.count > 2 ? children[1].value(.preferredColumnWidth)?.numbers : nil,
                detailWidth: children.count > 1 ? children[children.count - 1].value(.preferredColumnWidth)?.numbers : nil)
            split.setItems(items)
            return
        }

        if let navigation = view as? AppKitNavigationView {
            navigation.setItems(items)
            return
        }

        if let tabs = view as? AppKitTabbedView {
            arrangeTabs(tabs)
            return
        }

        if let menu = view as? AppKitMenuButtonView {
            menu.setItem(items.occupying.first)
            return
        }

        if let custom = view as? AppKitCustomLayoutView {
            custom.setItems(items, layout: CoreLink().customLayout(for: element.id))
            return
        }

        if let page = view as? AppKitSingleChildView {
            page.setItem(items.occupying.first)
            return
        }

        if let grid = view as? AppKitGridView {
            grid.setItems(items)
            return
        }

        if let layers = view as? AppKitZStackView {
            layers.setItems(items)
            return
        }

        if let scroll = view as? AppKitScrollView {
            scroll.setItems(items)
        }
    }

    var layoutItem: AppKitLayoutItem? {
        guard let view = presentableViews.first else { return nil }
        var item = AppKitLayoutItem(view: view)
        item.values = element.layoutValues
        item.codeId = element.id
        item.drawing = presentableDrawing
        item.mount = mount
        item.placed = presentableNode
        item.departing = element.isDeparting
        item.matchedStart = matchedStart()
        if fadesIn {
            item.fadeIn = { [weak self] animation, room in self?.fadeIn(under: animation, room: room) }
        }
        return item
    }

    /// The element whose view `presentableViews` puts first.
    var presentableNode: AppKitElement? {
        if view != nil { return self }
        return children.lazy.compactMap(\.presentableNode).first
    }

    /// The drawing of the view `presentableViews` puts first.
    var presentableDrawing: AppKitViewDrawing? {
        if view != nil { return drawing }
        return children.lazy.compactMap(\.presentableDrawing).first
    }

    var presentableViews: [NSView] {
        if let view { return [view] }
        return children.flatMap(\.presentableViews)
    }

    /// The first native view authored into one structural child slot.
    func firstView(in slot: NodeType) -> NSView? {
        self.slot(slot)?.presentableViews.first
    }

    func slot(_ type: NodeType) -> AppKitElement? {
        children.first { $0.type == type }
    }
}
#endif
