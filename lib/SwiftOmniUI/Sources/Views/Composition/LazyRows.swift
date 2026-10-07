// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A view that can name its children without building them - what a lazy
/// container asks of its content before anything is made. `ForEach` is the
/// one: it keeps its items and the row closure, so a lazy stack learns every
/// identity up front and runs the closure only for the ones a scroller's
/// window asks for. Any other content is read eagerly - the laziness then is
/// in mounting, not in building.
protocol LazyRows: Element {
    /// The rows' nodes, all of them - the eager reading, for a container that
    /// does not ask lazily.
    var lazyChildren: [Node] { get }

    /// How many rows there are.
    var lazyRowCount: Int { get }

    /// The identity `index`'s row carries - `nil` for one with none.
    func lazyRowIdentity(at index: Int) -> String?

    /// Whether a fresh source can reuse the previous source's identity index.
    /// Row builders are always refreshed, even when this answers true.
    func hasSameLazyIdentities(as other: any LazyRows) -> Bool

    /// The row at `index`, built only when asked.
    func lazyRow(at index: Int) -> any Element
}

/// A `LazyRows` under one more path segment - a statement's number, or a
/// branch's name, on the front of every row's key.
struct LazyKeyed: LazyRows {
    let segment: String
    let rows: any LazyRows

    var node: Node {
        Node(type: .fragment, children: rows.lazyChildren.map { child in
            var child = child
            child.key = child.key.map { "\(segment).\($0)" } ?? segment
            return child
        })
    }

    var lazyChildren: [Node] { node.asChildren }

    var lazyRowCount: Int { rows.lazyRowCount }

    func lazyRowIdentity(at index: Int) -> String? {
        rows.lazyRowIdentity(at: index).map { "\(segment).\($0)" }
    }

    func hasSameLazyIdentities(as other: any LazyRows) -> Bool {
        guard let other = other as? Self, segment == other.segment else { return false }
        return rows.hasSameLazyIdentities(as: other.rows)
    }

    /// The row under this segment - the key gains it; a `manual` id is the
    /// author's own name and keeps it.
    func lazyRow(at index: Int) -> any Element {
        SegmentKeyed(segment: segment, raw: rows.lazyRow(at: index))
    }
}

/// A lazy row under one more path segment, as `LazyKeyed.lazyRow` wraps it.
private struct SegmentKeyed: Element {
    let segment: String
    let raw: Element

    var node: Node {
        var node = raw.node
        if node.type == .fragment {
            node.children = node.children.map { child in
                var child = child
                child.key = child.key.map { "\(segment).\($0)" } ?? segment
                return child
            }
        } else {
            node.key = node.key.map { "\(segment).\($0)" } ?? segment
        }
        return node
    }
}
