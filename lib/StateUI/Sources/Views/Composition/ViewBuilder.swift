// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The result builder behind the nested syntax. Besides joining statements into
// a child list, every method records where each view was written - a path such
// as "1.else.0" that `Node.key` carries to the differ as the view's key.
// Design: docs/design/views/builders.md#every-statement-records-where-it-stood

/// Collects the views written as consecutive statements into one view - a
/// `TupleView`, whose children the differ splices into the parent.
///
/// `if`, `if/else`, `switch`, `ForEach`, `for`/`in` and `if #available` work
/// inside one.
///
///     VStack {
///         Text("Files")
///
///         ForEach(files, id: \.path) { file in
///             Text(file.name)
///         }
///     }
@resultBuilder
public enum ViewBuilder {
    /// A single view written as a statement.
    public static func buildExpression<Content: View>(_ expression: Content) -> Content {
        expression
    }

    /// A view whose concrete type was given up, written as a statement.
    @_disfavoredOverload
    public static func buildExpression(_ expression: any View) -> AnyView {
        AnyView(expression)
    }

    /// One element written as a statement.
    @_disfavoredOverload
    public static func buildExpression(_ expression: Element) -> TupleView {
        TupleView([expression])
    }

    /// Several, from something that already produced a list - a `ForEach`'s
    /// items, or a hand-built element array.
    @_disfavoredOverload
    public static func buildExpression(_ expression: [Element]) -> TupleView {
        TupleView(expression)
    }

    /// The statements of the closure, in the order they are written, each
    /// keyed by its statement's number whatever the others produce.
    public static func buildBlock(_ components: (any View)...) -> TupleView {
        TupleView(components.enumerated().flatMap { at($0.offset, $0.element) })
    }

    /// Nothing written: an empty group.
    public static func buildBlock() -> TupleView {
        TupleView([])
    }

    /// An `if` without an `else`; what it builds is keyed apart from the
    /// statement after it.
    public static func buildOptional(_ component: TupleView?) -> TupleView {
        component?.tagged("some") ?? TupleView([])
    }

    /// The `if` branch of an if/else.
    public static func buildEither(first component: TupleView) -> TupleView {
        component.tagged("if")
    }

    /// The `else` branch. Its views are keyed apart from the `if` branch's, so
    /// switching branches replaces the control rather than editing it.
    public static func buildEither(second component: TupleView) -> TupleView {
        component.tagged("else")
    }

    /// A `for` statement's turns, each keyed by its turn number.
    public static func buildArray(_ components: [TupleView]) -> TupleView {
        TupleView(components.enumerated().flatMap { turn in
            turn.element.node.asChildren.map { child in
                Keyed(segment: String(turn.offset), raw: child)
            }
        })
    }

    /// A `TupleView` where the call already produced one.
    public static func buildFinalResult(_ component: TupleView) -> TupleView {
        component
    }

    /// A statement's own type through, so a leaf's `Body` names it: a body of
    /// one expression is that expression's type, not a `TupleView`.
    public static func buildFinalResult<Content: View>(_ component: Content) -> Content {
        component
    }

    /// What an `if #available(…)` block builds, keyed like every other branch.
    public static func buildLimitedAvailability(_ component: TupleView) -> TupleView {
        component.tagged("available")
    }

    /// The views written under one statement, keyed by the statement's number.
    /// Design: docs/design/views/builders.md#several-views-from-one-statement
    private static func at(_ index: Int, _ view: any View) -> [Element] {
        let nodes = view.node.asChildren

        guard nodes.count > 1 else {
            return nodes.map { Keyed(segment: String(index), raw: $0) }
        }

        return nodes.enumerated().map { Keyed(segment: "\(index).\($0.offset)", raw: $0.element) }
    }
}

/// One more segment on a node's path, added without touching anything else.
/// Design: docs/design/views/builders.md#the-path-rides-a-wrapper
struct Keyed: Element {
    /// What to put in front of whatever path the node already has.
    let segment: String

    /// The node the statement produced.
    let raw: Node

    /// The same node, with the segment on the front of its path.
    var node: Node {
        var node = raw
        node.key = node.key.map { "\(segment).\($0)" } ?? segment
        return node
    }
}
