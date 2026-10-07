// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

extension AppKitRegistrations {
    /// An List: AppKit's collection view, which the host makes itself - its cells ask the tree for what they
    /// hold (`ItemsCells`). Its entries, layout and choice; the user's choosing, opening and reaching the end; the
    /// cells it holds; and scrolling to an item.
    static func items(_ registry: Registry<NSView>) {
        registry.add(ListContract.self, madeByHost: AppKitItemsView.self) { list in
            list.applies([
                ListContract.items, ListContract.itemsLayout, ListContract.listStyle,
                ListContract.selectionMode, ListContract.selectedItems, ListContract.endReachedWithin,
                ScrollContentElementContract.scrollContentBackground,
            ]) { view, values in
                view.apply(
                    layout: values[ListContract.itemsLayout] ?? .list(),
                    style: values[ListContract.listStyle] ?? .automatic,
                    mode: values[ListContract.selectionMode] ?? .none)
                if let background = values[ScrollContentElementContract.scrollContentBackground] {
                    view.scroller.drawsBackground = background != .hidden
                }
            }
            list.raises(ListContract.selectionChanged)
            list.raises(ListContract.itemActivated)
            list.raises(ListContract.endReached)
            list.raises(ListContract.realizedChanged)
        }
    }
}
#endif
