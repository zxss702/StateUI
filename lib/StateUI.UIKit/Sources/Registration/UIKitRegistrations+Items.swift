// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

extension UIKitRegistrations {
    /// An List: UIKit's collection view, which the host makes itself - its cells ask the tree for what they
    /// hold (`ItemsCells`). Its entries, layout and choice; the user's choosing, opening and reaching the end; the
    /// cells it holds; and scrolling to an item.
    static func items(_ registry: Registry<UIView>) {
        registry.add(ListContract.self, madeByHost: UIKitItemsView.self) { list in
            list.applies([
                ListContract.items, ListContract.itemsLayout, ListContract.listStyle,
                ListContract.selectionMode,
                ListContract.selectedItems, ListContract.endReachedWithin,
            ]) { view, values in
                view.apply(
                    layout: values[ListContract.itemsLayout] ?? .list(),
                    style: values[ListContract.listStyle] ?? .automatic,
                    mode: values[ListContract.selectionMode] ?? .none)
            }
            list.raises(ListContract.selectionChanged)
            list.raises(ListContract.itemActivated)
            list.raises(ListContract.endReached)
            list.raises(ListContract.realizedChanged)
        }
    }

    /// The acts an List answers itself.
    static let itemsActs: [any ContractMember] = [ListContract.scrollTo, ScrollViewContract.scrollToDescendant]
}
#endif
