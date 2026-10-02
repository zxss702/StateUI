// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// One view per item of a collection, each keyed by its item - never by the
/// position it happened to be built at.
///
///     VStack {
///         ForEach(names) { name in
///             Text(name)
///         }
///     }
///
/// A collection that gains, loses or reorders items moves the views that
/// stayed - text, caret, focus and `@State` riding along - rather than
/// rewriting what every position shows. A view's own `.id()` wins. Items must
/// be distinct within their parent; where they repeat, name the distinct part
/// with `id:`.
///
/// A plain `for` does not compile inside a view builder, so this is where
/// repetition is written.
public struct ForEach<Items: RandomAccessCollection, Id: Hashable, Content: View>: View {
    /// The views, one per item, each wearing its item's identity - a fragment
    /// whose children the differ splices into the parent element's list.
    public var node: Node

    /// One view per item, the item its identity.
    ///
    ///     ForEach(0..<5) { turn in
    ///         Text("Turn \(turn)")
    ///     }
    ///
    /// A range works: its numbers are the items.
    public init(
        _ items: Items,
        @ViewBuilder content: (Items.Element) -> Content
    ) where Items.Element == Id {
        self.init(items, id: \.self, content: content)
    }

    /// One view per item, identified by the part of it `id` names.
    ///
    ///     ForEach(files, id: \.path) { file in
    ///         Text(file.name)
    ///     }
    ///
    /// For items that are not `Hashable` whole, or that repeat - an enumerated
    /// sequence's offsets being the usual case:
    /// `ForEach(Array(titles.enumerated()), id: \.offset)`.
    ///
    /// An identity is compared as text, `String(describing:)`: a `description`
    /// that says less than the value gives two items one identity.
    ///
    /// - Parameter id: which part of an item is its identity - distinct
    ///   across the items, stable while the item means the same row.
    public init(
        _ items: Items,
        id: KeyPath<Items.Element, Id>,
        @ViewBuilder content: (Items.Element) -> Content
    ) {
        node = Node(type: .fragment, children: items.map { item in
            Identified(identity: String(describing: item[keyPath: id]), element: content(item)).node
        })
    }
}

/// One turn's view, wearing its item's identity unless the author wrote an
/// `.id()` of their own.
/// Design: docs/design/views/builders.md#the-path-rides-a-wrapper
struct Identified: Element {
    /// The item's identity, rendered to the id namespace authors write in.
    let identity: String

    /// The view as the author wrote it, modifiers and all.
    let element: Element

    /// The element's own node, identified. A row that is a fragment carries
    /// its identity on its only child - or scopes each child's path by it -
    /// since the fragment itself splices away.
    var node: Node {
        var node = element.node

        guard node.type == .fragment else {
            if node.id == nil {
                node.id = identity
            }

            return node
        }

        if node.children.count == 1 {
            if node.children[0].id == nil {
                node.children[0].id = identity
            }

            return node
        }

        node.children = node.children.map { child in
            var child = child
            if child.id == nil {
                child.key = child.key.map { "\(identity).\($0)" } ?? identity
            }
            return child
        }
        return node
    }
}
