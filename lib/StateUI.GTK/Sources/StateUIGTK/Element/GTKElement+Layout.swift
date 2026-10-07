// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIGTK

/// Children placed: the layout item each child gives its parent.
extension GTKElement {
    /// The view lays out, and its control writes, in the element's direction.
    func directionChanged() {
        view?.setDirection(element.layoutDirection == .rightToLeft ? GTK_TEXT_DIR_RTL : GTK_TEXT_DIR_LTR)
    }

    /// Hands a layout its children's items, in order - a page's slots furnish its header bar and stand in none of
    /// its room - and a label the runs of its spans.
    func arrangeChildren() {
        if let items = view as? GTKItemsView { return items.childrenChanged() }
        if let lazy = view as? GTKLazyView {
            if lazy.cells.takeItems() {
                lazy.measured = [:]
                lazy.invalidateMeasurements()
            }
            lazy.direction = element.layoutDirection
            lazy.setItems(element.arrangedChildren.compactMap { child in
                guard case .manual(let identity) = child.id, let item = child.gtk.layoutItem
                else { return nil }
                return (identity, item)
            })
            return
        }
        if let label = view as? GTKLabelView {
            return arrangeRuns(of: label)
        }
        let arranged = element.arrangedChildren.map(\.gtk)

        if let menu = view as? GTKMenuButtonView {
            menu.setFace(arranged.first { $0.type != .contextMenu }?.view?.widget)
            menu.setEntries(
                arranged.first { $0.type == .contextMenu }
                    .map { MenuEntry.entries(of: $0.element) } ?? [],
                clicked: { entry in entry.gtk.send(.clicked, []) })
            return
        }
        (view as? GTKNavigationView)?.titles = arranged.map { child in
            // A badge stands by its page's title in brackets, the way the
            // platform counts in tab labels.
            let title = child.element.visiblePage?.value(.title)?.string ?? ""
            guard let badge = child.element.visiblePage?.value(.badge)?.string, !badge.isEmpty else { return title }
            return title.isEmpty ? badge : "\(title) (\(badge))"
        }
        (view as? GTKSplitView)?.framedPanes = arranged.map { Self.framedTypes.contains($0.type) }
        (view as? GTKSplitView)?.sidebarWidthBounds = arranged.first?.element.value(.preferredColumnWidth)?.numbers
        (view as? GTKSplitView)?.contentWidthBounds = arranged.count > 2
            ? arranged[1].element.value(.preferredColumnWidth)?.numbers
            : nil
        if let custom = view as? GTKCustomLayoutView {
            custom.direction = element.layoutDirection
            custom.setItems(
                arranged.compactMap(\.layoutItem),
                layout: CoreLink().customLayout(for: element.id))
            return
        }
        let layout = view as? GTKLayoutView
        layout?.direction = element.layoutDirection
        layout?.setItems(arranged.compactMap(\.layoutItem))
    }

    /// A label's spans as runs of its words (`MountedElement.textRuns`); without spans, its own words, once the runs
    /// are gone.
    private func arrangeRuns(of label: GTKLabelView) {
        guard let runs = element.textRuns else {
            if hasRuns {
                hasRuns = false
                label.setRuns(nil)
            }
            return
        }
        hasRuns = true
        label.setRuns(runs)
    }

    /// What this element gives the layout it stands in: its view, or the first view of an element drawn by its parent.
    var layoutItem: GTKLayoutItem? {
        guard let view else { return children.lazy.compactMap(\.layoutItem).first }

        var item = GTKLayoutItem(view: view, values: element.layoutValues, isShown: isShown)
        item.mount = element.mount
        item.codeId = element.id
        item.departing = element.isDeparting
        if fadesIn {
            item.fadeIn = { [weak self] animation, room in self?.fadeIn(under: animation, room: room) }
        }
        return item
    }

    /// Whether the view is shown: as the tree says, or while it fades out.
    var isShown: Bool {
        element.standsShown
    }

    /// The element whose layout places this one: the nearest above it with a view.
    var layoutParent: GTKElement? {
        guard let parent else { return nil }
        return parent.view != nil ? parent : parent.layoutParent
    }
}
