// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// `Text`'s own properties, shared by the control and its `Style<Text>`.
public protocol TextProperties: PropertyContainer {}

extension TextProperties {
    /// What happens to text too long for the space: wrap it, or cut it and say
    /// so.
    @_spi(Host) public func lineBreak(_ value: LineBreak) -> Modified {
        setValue(TextContract.lineBreak, value)
    }

    /// Where a too-long line is cut, the SwiftUI spelling of the truncating
    /// `lineBreak`s.
    public func truncationMode(_ mode: TruncationMode) -> Modified {
        lineBreak(mode.lineBreak)
    }

    /// How many lines to show before the text is cut - what the cut LOOKS like
    /// is `lineBreak`'s business. A count of -1 means no limit, which is
    /// the default.
    public func lineLimit(_ value: Int) -> Modified {
        setValue(TextContract.lineLimit, value)
    }

    /// Whether the user can drag a range out of the text and copy it.
    ///
    ///     Text(output).textSelection(.enabled)
    public func textSelection(_ selectability: some TextSelectability) -> Modified {
        setValue(TextContract.selectable, selectability.isSelectable)
    }

    /// The fraction of its own size the text may shrink to fit the room it
    /// was given before the host cuts it: 0 shrinks it to nothing said, 1
    /// keeps it whole.
    ///
    ///     Text(longName).minimumScaleFactor(0.5)
    public func minimumScaleFactor(_ factor: Double) -> Modified {
        setValue(TextContract.minimumScaleFactor, factor)
    }
}

extension View {
    /// Whether the text inside this view lets the user drag a range out of it
    /// and copy it - a `Text` keeping its own wins over the inherited one.
    ///
    ///     Text(output).textSelection(.enabled)
    @_disfavoredOverload
    public func textSelection(_ selectability: some TextSelectability) -> ModifiedContent {
        revised { $0.writeInherited(TextContract.selectable, selectability.isSelectable) }
    }

    /// The fraction `Text`s inside this view may shrink to before they are
    /// cut - a `Text` keeping its own wins over the inherited one.
    ///
    ///     Text(longName).minimumScaleFactor(0.5)
    @_disfavoredOverload
    public func minimumScaleFactor(_ factor: Double) -> ModifiedContent {
        revised { $0.writeInherited(TextContract.minimumScaleFactor, factor) }
    }
}

/// A read-only piece of text.
///
///     Text("Total")
///         .fontSize(20)
///         .fontAttributes(.bold)
///         .multilineTextAlignment(.center)
public struct Text: VisualElement, TextElement, FontElement, TextAlignmentElement, PaddingElement, LineHeightElement, DecorableTextElement, TextProperties{
    /// The node this control describes.
    public var node: Node

    /// An empty one - what a `Style<Text>` is written against.
    public init() {
        node = Node(contract: TextContract.self)
    }

    /// A label showing `text`.
    public init(_ text: String) {
        node = Node(contract: TextContract.self)
        node.write(TextElementContract.text, text)
    }

    /// A label whose text is carried from a state, written by the host as it
    /// changes, at no render.
    ///
    /// - Parameter text: the state the words are read from.
    public init(_ text: Binding<String>) {
        self = Text().text(text)
    }

    /// Text made of runs, each with a look of its own.
    ///
    ///     Text()
    ///         .spans {
    ///             TextSpan("let ").foregroundStyle(.purple)
    ///             TextSpan("counter").foregroundStyle(.steelBlue)
    ///             TextSpan(" = 0")
    ///         }
    ///
    /// The one way to colour part of a label: text in two colours is two runs.
    /// A `ForEach` builds them, keyed by where each sits, since two tokens may
    /// read the same:
    ///
    ///     Text().spans {
    ///         ForEach(Array(highlighted(code).enumerated()), id: \.offset) { token in
    ///             TextSpan(token.element.text).foregroundStyle(token.element.colour)
    ///         }
    ///     }
    ///
    /// A Text given both runs and a `text` shows the runs.
    @_spi(Host) public func spans(@ViewBuilder _ spans: () -> any View) -> Self {
        modified {
            $0.children = [Node(contract: SpansContract.self, children: spans().node.asChildren)]
        }
    }
}

/// One run of text inside a Text, with its own colour, size and weight.
///
///     TextSpan("Sold out")
///         .foregroundStyle(.firebrick)
///         .fontAttributes(.bold)
///
/// Not a view: a run has text and font properties and nothing else, and it
/// goes only in a Text's `spans`.
public struct TextSpan: View, ModifiableElement, TextElement, FontElement,
    LineHeightElement, DecorableTextElement {
    /// The node this run describes.
    public var node: Node

    /// An empty one, for a run built up by modifiers.
    public init() {
        node = Node(contract: SpanContract.self)
    }

    /// A run showing `text`.
    public init(_ text: String) {
        node = Node(contract: SpanContract.self)
        node.write(TextElementContract.text, text)
    }

    /// What is drawn behind this run - a highlight over part of a line.
    public func background(_ value: Color) -> Self {
        setValue(SpanContract.background, value)
    }
}

extension Text {
    /// `lineLimit` from a state, `$x`: the host sets each new value as it
    /// stands, and no view is rebuilt for it.
    public func lineLimit(_ state: Binding<Int>) -> Modified {
        plain(.lineLimit, by: state)
    }
}

extension Text {
    /// A custom renderer for this text, as `.textRenderer` names one:
    ///
    ///     Text(body)
    ///         .textRenderer(MyRenderer())
    ///
    /// The renderer is a code object: it rides the node and a host that draws
    /// text natively keeps its own drawing, so a renderer that only watches
    /// layout still works but its draw pass does not run.
    public func textRenderer(_ renderer: some TextRenderer) -> Self {
        var copy = self
        copy.node.write(TextContract.textRenderer, "custom")
        copy.node.textRenderer = renderer
        return copy
    }
}

extension Text {
    /// The words a `Text` node carries - what `navigationTitle` reads of one
    /// written for it.
    var words: String {
        node.props[TextElementContract.text.token]?.string ?? ""
    }
}
