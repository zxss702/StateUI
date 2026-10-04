// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// Two or more views standing together, made by a `ViewBuilder` block of more
/// than one statement - never written by hand.
///
/// A tuple view keeps no element of its own: the differ splices its children
/// into the parent element's list, so `VStack { A(); B() }` is three siblings
/// whether the two views were written in the stack or in a body's own braces.
public struct TupleView: View {
    /// The children, each a node - a fragment among them already unwrapped.
    public var node: Node

    /// The statements' views, in written order.
    init(_ elements: [Element]) {
        node = Node(type: .fragment, children: elements.flatMap { $0.node.asChildren })
    }

    /// One more segment on each child's path: the differ knows the child by
    /// where it was written, not by where the group lands.
    func tagged(_ segment: String) -> TupleView {
        var tagged = node
        tagged.children = tagged.children.map { child in
            var child = child
            child.key = child.key.map { "\(segment).\($0)" } ?? segment
            return child
        }
        return TupleView(node: tagged)
    }

    /// A tuple view over an already-fragmented node.
    init(node: Node) {
        self.node = node
    }
}

/// Several views named as one, for factoring a fixed group out of a layout.
///
///     var body: some View {
///         Group {
///             Text(title)
///             Text(subtitle).foregroundStyle(.secondary)
///         }
///         .contentPadding(12)
///     }
///
/// A group keeps no element of its own - its children stand in its parent's
/// list as though written there, and a modifier on the group is written on
/// each of them.
public struct Group<Content: View>: View {
    /// The children, each a node.
    public var node: Node

    /// The group's views.
    public init(@ViewBuilder content: () -> Content) {
        node = Node(type: .fragment, children: content().node.asChildren)
    }
}

/// A view that shows nothing: the empty case of an `if` with no `else`.
public struct EmptyView: View {
    /// An empty fragment - no children, nothing to splice.
    public var node: Node { Node(type: .fragment) }

    /// Makes one.
    public init() {}
}

/// A view whose type is hidden behind `AnyView`, for a value that can hold a
/// view of more than one kind.
///
///     let icon: AnyView = isFolder ? AnyView(FolderIcon()) : AnyView(FileIcon())
///
/// The wrapped view keeps its own identity in the tree; `AnyView` itself adds
/// none.
public struct AnyView: View {
    /// The wrapped view's node, as written.
    public var node: Node

    /// Wraps `content` without changing what it is.
    public init(_ content: any View) {
        node = content.node
    }
}

/// A view marked safe to build again only when its value has moved - what
/// `.equatable()` makes.
///
/// StateUI reads a view's stored properties as its inputs and rebuilds it
/// where they differ; an `Equatable` view's inputs already compare by value,
/// which is what the wrapper declares.
public struct EquatableView<Content: View & Equatable>: View, Equatable {
    /// The wrapped view.
    public var content: Content

    /// The wrapped view's node, as written.
    public var node: Node { content.node }

    /// Wraps `content`, declared `Equatable`.
    public init(content: Content) {
        self.content = content
    }
}

extension View where Self: Equatable {
    /// Marks this view safe to build again only when its value has moved:
    ///
    ///     Row(item: item)
    ///         .equatable()
    ///
    /// The view's `Equatable` conformance - often synthesized - is what the
    /// differ compares it by.
    public func equatable() -> EquatableView<Self> {
        EquatableView(content: self)
    }
}
