// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The desktop menu bar: a page writes its menus into its session, and the
// platform puts them where it puts menus. A phone shows none of it.

/// A menu: a caption and the entries it opens - on the menu bar, or one level
/// down inside another menu.
///
///     page.menuBar = [
///         Menu("File") {
///             MenuItem("New").onClicked { create() }
///             Menu("Recent") {
///                 ForEach(recent) { file in
///                     MenuItem(file).onClicked { open(file) }
///                 }
///             }
///             Divider()
///             MenuItem("Close").onClicked { close() }
///         },
///     ]
///
/// Not a view: a menu belongs to a page, written into the page's session.
public struct Menu: View {
    /// The node this menu describes.
    public var node: Node

    /// A menu captioned `text`, holding whatever the closure lists.
    ///
    /// What goes inside is a `MenuItem`, a `Menu` or a `Divider`, with an
    /// `if` or a `ForEach` among them.
    ///
    /// - Parameter text: the caption - "File", "Edit", "View" on the bar, or the
    ///   row that opens it inside another menu.
    /// - Parameter items: the entries, in the order they are written.
    public init(_ text: String, @ViewBuilder items: () -> any View) {
        node = Node(contract: MenuContract.self, children: items().node.asChildren)
        node.write(MenuContract.text, text)
    }

    /// The node, as every element answers it.

    /// Who this menu is among the page's others, so it stays matched to itself
    /// when the menus around it come and go; without one it is matched by
    /// position.
    public func id(_ value: some Hashable) -> Self {
        var copy = self
        copy.node.id = String(describing: value)
        return copy
    }

    /// Whether the menu opens at all.
    public func disabled(_ value: Bool) -> Self {
        var copy = self
        copy.node.write(MenuContract.isEnabled, value)
        return copy
    }
}

/// One entry in a menu.
///
///     MenuItem("Save")
///         .icon("nav_media.png")
///         .onClicked { save() }
public struct MenuItem: View, MenuItemElement {
    /// The node this entry describes.
    public var node: Node

    /// An entry captioned `text`. Give it an `.onClicked`: an entry that does
    /// nothing is one that looks broken.
    public init(_ text: String) {
        node = Node(contract: MenuItemContract.self)
        node.write(MenuItemElementContract.text, text)
    }

    /// The node, as every element answers it.

    /// Who this entry is among the menu's others, so it stays matched to itself
    /// when the entries around it come and go; without one it is matched by
    /// position.
    public func id(_ value: some Hashable) -> Self {
        modified { $0.id = String(describing: value) }
    }
}

/// A line between entries, grouping the ones above it apart from the ones
/// below.
///
///     Menu("File") {
///         MenuItem("New").onClicked { create() }
///         Divider()
///         MenuItem("Close").onClicked { close() }
///     }
///
/// It has no caption and nothing to click; the platform draws whatever a
/// separator looks like there.
public struct Divider: View {
    /// The node this separator describes.
    public var node: Node

    /// A line.
    public init() {
        node = Node(contract: DividerContract.self)
    }

    /// The node, as every element answers it.

    /// Who this separator is, among the menu's others - worth giving one when
    /// entries come and go around it.
    public func id(_ value: some Hashable) -> Self {
        var copy = self
        copy.node.id = String(describing: value)
        return copy
    }
}

