// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A `VStack` built as a scroller shows it: a child's subtree is mounted
/// when the child stands in view or within reach of it, and let go when it
/// leaves - so a column as long as the data asks for keeps the cost of the
/// room on screen, not the length of the data.
///
///     ScrollView {
///         LazyVStack(spacing: 12) {
///             ForEach(messages) { message in
///                 MessageRow(message: message)
///             }
///         }
///     }
///
/// The scroll room is known before the children exist: the host stands the
/// unbuilt ones for by the measure of the ones it holds, and scrolls the
/// whole length at once. Each child names itself the way its writer named
/// it - a `ForEach` item's identity, an `.id()`, else the place it was
/// written at - and only a mounted child holds a view or a state.
public struct LazyVStack: View {
    /// What the stack shows, as the builder described it.
    private let content: () -> any View

    /// Where a child stands across the stack's width.
    private let alignment: HorizontalAlignment

    /// The room between neighbours; nil is the platform's own.
    private let spacing: Double?

    /// The children the host has asked for.
    @State private var realized: [String] = []

    /// A lazy column of whatever the closure describes.
    /// The closure is kept and run when the differ describes the stack.
    public init(@ViewBuilder content: @escaping () -> any View) {
        self.init(alignment: .center, spacing: nil, content: content)
    }

    /// A lazy column whose children stand at `alignment` across its width -
    /// a child that names its own `horizontalAlignment` keeps it.
    ///
    ///     ScrollView {
    ///         LazyVStack(alignment: .leading, spacing: 8) {
    ///             ForEach(messages) { MessageRow(message: $0) }
    ///         }
    ///     }
    public init(
        alignment: HorizontalAlignment,
        spacing: Double?,
        @ViewBuilder content: @escaping () -> any View
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    /// The same, with the stack's own spacing - the SwiftUI spelling.
    public init(spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        self.init(alignment: .center, spacing: spacing, content: content)
    }

    /// The stack's element, built for the window the host last named.
    public var body: some View {
        var element = LazyVStackElement()
        if let spacing { element.node.write(StackBaseContract.spacing, spacing) }
        let held = $realized
        let axis = alignment.axis
        element.node.write(
            LazyVStackContract.items,
            LazyChildren.take(content(), into: &element.node, realized: realized) { child, _ in
                if child.props[.horizontalAlignment] == nil {
                    child.write(ViewContract.horizontalAlignment, axis)
                }
            }
        )
        element.node.addHandler(LazyVStackContract.realizedChanged.token) {
            guard let identities = MemberValues.carried(
                EventBuffer.current, by: LazyVStackContract.realizedChanged.name, as: [String].self),
                identities != held.wrappedValue
            else { return }

            held.wrappedValue = identities
        }
        return element
    }
}

/// An `HStack` built as a scroller shows it - `LazyVStack` across.
///
///     ScrollView(.horizontal) {
///         LazyHStack(spacing: 12) { … }
///     }
public struct LazyHStack: View {
    /// What the stack shows, as the builder described it.
    private let content: () -> any View

    /// Where a child stands down the stack's height.
    private let alignment: VerticalAlignment

    /// The room between neighbours; nil is the platform's own.
    private let spacing: Double?

    /// The children the host has asked for.
    @State private var realized: [String] = []

    /// A lazy row of whatever the closure describes.
    public init(@ViewBuilder content: @escaping () -> any View) {
        self.init(alignment: .center, spacing: nil, content: content)
    }

    /// A lazy row whose children stand at `alignment` down its height -
    /// a child that names its own `verticalAlignment` keeps it.
    ///
    ///     ScrollView(.horizontal) {
    ///         LazyHStack(alignment: .top, spacing: 8) {
    ///             ForEach(cards) { CardView(card: $0) }
    ///         }
    ///     }
    public init(
        alignment: VerticalAlignment,
        spacing: Double?,
        @ViewBuilder content: @escaping () -> any View
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    /// The same, with the stack's own spacing - the SwiftUI spelling.
    public init(spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        self.init(alignment: .center, spacing: spacing, content: content)
    }

    /// The stack's element, built for the window the host last named.
    public var body: some View {
        var element = LazyHStackElement()
        if let spacing { element.node.write(StackBaseContract.spacing, spacing) }
        let held = $realized
        let axis = alignment.axis
        element.node.write(
            LazyHStackContract.items,
            LazyChildren.take(content(), into: &element.node, realized: realized) { child, _ in
                if child.props[.verticalAlignment] == nil {
                    child.write(ViewContract.verticalAlignment, axis)
                }
            }
        )
        element.node.addHandler(LazyHStackContract.realizedChanged.token) {
            guard let identities = MemberValues.carried(
                EventBuffer.current, by: LazyHStackContract.realizedChanged.name, as: [String].self),
                identities != held.wrappedValue
            else { return }

            held.wrappedValue = identities
        }
        return element
    }
}

/// The element a `LazyVStack` describes - the stack the host virtualizes.
struct LazyVStackElement: StackBase {
    var node = Node(contract: LazyVStackContract.self)
}

/// The element a `LazyHStack` describes - the row the host virtualizes.
struct LazyHStackElement: StackBase {
    var node = Node(contract: LazyHStackContract.self)
}

/// The children a lazy element describes: every one named, only the asked
/// ones built.
///
/// A child's identity is the one it was written with - a `ForEach` item's
/// or an `.id()`'s - or the place it stands at, told apart from an equal
/// one before it the way an `List` item's is. The names cross as the `items`
/// prop; the host answers with `realizedChanged`, and the producer gives the
/// differ only the children the host asks for.
///
/// A `ForEach` - alone, or a statement among others - is a `LazyRows`: it
/// names every row without building any, and its rows are made one at a
/// time, only for the identities the host asks for. Anything else is read
/// eagerly, and the laziness is in mounting alone.
enum LazyChildren {
    /// One child's description: a node made already, or a row a `LazyRows`
    /// makes on asking.
    private enum Owned {
        case node(Node)
        case row(any LazyRows, local: Int, place: Int)
    }

    /// One flat piece of a lazy container's content.
    private enum Segment {
        /// Rows named and built on asking - a `ForEach`, possibly under
        /// statement keys.
        case rows(any LazyRows)
        /// Children read already - static content.
        case nodes([Node])
    }

    /// The pieces `content` flattens to: a `LazyRows` stays one, everything
    /// else is read eagerly. A `TupleView` the builder kept its statements
    /// for is walked statement by statement; anything else is one eager read.
    private static func segments(of content: any View) -> [Segment] {
        var segments: [Segment] = []
        var children: [Node] = []

        for element in (content as? TupleView)?.lazyElements ?? [content] {
            if let rows = element as? any LazyRows {
                if !children.isEmpty { segments.append(.nodes(children)); children = [] }
                segments.append(.rows(rows))
            } else {
                children.append(contentsOf: element.node.asChildren)
            }
        }
        if !children.isEmpty { segments.append(.nodes(children)) }
        return segments
    }

    /// Names the children of `content` - `prepare` dressing each as its
    /// container asks - and sets `node`'s producer to the ones `realized`
    /// names, in the order they show. Answers every child's identity in the
    /// order it shows.
    static func take(
        _ content: any View, into node: inout Node, realized: [String],
        prepare: @escaping (inout Node, Int) -> Void
    ) -> [String] {
        var taken: Set<String> = []
        var identities: [String] = []
        var owned: [String: Owned] = [:]
        var index = 0

        /// `base` stood for by its own name, told apart from an equal one
        /// before it the way a repeated `.id()` is.
        func unique(_ base: String) -> String {
            var identity = base
            var variant = 1
            while taken.contains(identity) {
                identity = "\(base)\u{0}\(variant)"
                variant += 1
            }
            taken.insert(identity)
            return identity
        }

        for segment in segments(of: content) {
            switch segment {
            case .rows(let rows):
                for local in 0..<rows.lazyRowCount {
                    let identity = unique(rows.lazyRowIdentity(at: local) ?? "#\(index)")
                    owned[identity] = .row(rows, local: local, place: index)
                    identities.append(identity)
                    index += 1
                }

            case .nodes(var children):
                for local in children.indices {
                    prepare(&children[local], index)
                    let identity = unique(
                        children[local].id
                            ?? children[local].key.map { "#\($0)" }
                            ?? "#\(index)")
                    identify(&children[local], as: identity)
                    owned[identity] = .node(children[local])
                    identities.append(identity)
                    index += 1
                }
            }
        }

        let asked = Set(realized)
        node.producer = {
            identities.compactMap { identity in
                guard asked.contains(identity), let owner = owned[identity] else { return nil }
                switch owner {
                case .node(let child):
                    return child
                case .row(let rows, let local, let place):
                    var child = rows.lazyRow(at: local).node
                    prepare(&child, place)
                    identify(&child, as: identity)
                    return child
                }
            }
        }
        return identities
    }

    /// Writes `identity` onto `node` - the row's own `.id()` where it carried
    /// one, the name it was asked by where it carried none. A fragment's row
    /// splices, so every child of it answers to the name: the first plainly,
    /// the rest under the same variant mark the names were told apart by.
    private static func identify(_ node: inout Node, as identity: String) {
        guard node.type == .fragment else {
            if node.id == nil { node.id = identity }
            return
        }

        var variant = 0
        for index in node.children.indices where node.children[index].id == nil {
            node.children[index].id = variant == 0 ? identity : "\(identity)\u{0}\(variant)"
            variant += 1
        }
    }
}
