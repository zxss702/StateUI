// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

extension WinUIRegistrations {
    /// An List: WinUI's own List, which the host makes itself - its cells ask the tree for what they hold
    /// (`ItemsCells`). Its entries, layout and choice; the user's choosing, invoking and reaching the end; and the
    /// cells it holds.
    static func items(_ registry: Registry<WinUIView>) {
        registry.add(ListContract.self, madeByHost: WinUIItemsView.self) { list in
            list.applies([
                ListContract.items, ListContract.itemsLayout, ListContract.selectionMode,
                ListContract.selectedItems, ListContract.endReachedWithin,
            ]) { view, values in
                view.apply(
                    layout: values[ListContract.itemsLayout] ?? .list(),
                    mode: values[ListContract.selectionMode] ?? .none)
            }
            list.raises(ListContract.selectionChanged)
            list.raises(ListContract.itemActivated)
            list.raises(ListContract.endReached)
            list.raises(ListContract.realizedChanged)
        }
    }
}
