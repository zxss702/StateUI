// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// An action in the page's native navigation or toolbar surface.
///
///     struct NotesPage: View {
///         @Environment private var page: PageSession
///
///         var content: any View {
///             VStack { … }
///                 .onAppear {
///                     page.title = "Notes"
///                     page.toolbarItems = [
///                         ToolbarItem("Save")
///                             .onClicked { save() },
///
///                         ToolbarItem("Delete")
///                             .placement(.overflow)
///                             .isDestructive(true)
///                             .onClicked { delete() },
///                     ]
///                 }
///         }
///     }
///
/// A toolbar item is page furniture rather than a layout view. It carries a
/// caption, an optional image, presentation policy and a handler, and is
/// written into the page's session whenever that collection changes.
public struct ToolbarItem: View, MenuItemElement {
    /// The node this item describes.
    public var node: Node

    /// An item captioned `text`. Give it an `.onClicked`: an item that does
    /// nothing is one that looks broken.
    public init(_ text: String) {
        node = Node(contract: ToolbarItemContract.self)
        node.write(MenuItemElementContract.text, text)
    }

    /// An item captioned `text`, running `action` when it is picked.
    public init(_ text: String, action: @escaping EventHandler) {
        self.init(text)
        node.addHandler(MenuItemElementContract.clicked.token, action)
    }

    /// An item captioned `text`, in `placement`, running `action`.
    public init(_ text: String, placement: ToolbarItemPlacement, action: @escaping EventHandler) {
        self.init(text, action: action)
        node.write(ToolbarItemContract.placement, placement)
    }

    /// An icon item running `action`, its caption as the platform's tooltip -
    /// `ToolbarItem("Back", icon: .symbol("chevron.left")) { back() }`.
    public init(_ text: String, icon: ImageSource, action: @escaping EventHandler) {
        self.init(text, action: action)
        node.write(MenuItemElementContract.icon, icon)
    }

    /// The same, a system symbol by name - the SwiftUI `systemImage` spelling.
    ///
    ///     ToolbarItem("Home", systemImage: "house") { nav.home() }
    public init(_ text: String, systemImage: String, action: @escaping EventHandler) {
        self.init(text, icon: .symbol(systemImage), action: action)
    }

    /// An icon item in `placement`, running `action`.
    public init(_ text: String, systemImage: String, placement: ToolbarItemPlacement, action: @escaping EventHandler) {
        self.init(text, systemImage: systemImage, action: action)
        node.write(ToolbarItemContract.placement, placement)
    }

    /// The node this item describes.

    /// Who this item is among the page's others, so an item inserted in the
    /// middle is matched to itself rather than to whichever item stood there.
    ///
    /// - Parameter value: distinct among the page's items, and the same value
    ///   across renders.
    public func id(_ value: some Hashable) -> Self {
        var copy = self
        copy.node.id = String(describing: value)
        return copy
    }

    /// Whether it sits on the bar itself or behind the overflow menu.
    @_spi(Host) public func placement(_ value: ToolbarItemPlacement) -> Self { setValue(ToolbarItemContract.placement, value) }

    /// Where this item sorts among items in the same order group.
    ///
    /// Lower values appear first; items of equal priority keep their order.
    @_spi(Host) public func priority(_ value: Int) -> Self { setValue(ToolbarItemContract.priority, value) }
}
