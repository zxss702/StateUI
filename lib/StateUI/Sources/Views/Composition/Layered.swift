// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.overlay {}` and `.background {}` - a view layered over or under another,
// composed as the ZStack the same thing is written out as.
// Design: docs/design/views/modifiers.md#composed-modifiers

extension View {
    /// A view drawn over this one, both aligned in the larger of the two.
    ///
    ///     Text("Draft")
    ///         .overlay { Rectangle().cornerRadius(4).stroke(.gray) }
    public func overlay<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> Layered<Self, Content> {
        Layered(base: self, layer: content(), alignment: .center, over: true)
    }

    /// The same, aligned by `alignment`.
    public func overlay<Content: View>(
        alignment: Alignment,
        @ViewBuilder content: () -> Content
    ) -> Layered<Self, Content> {
        Layered(base: self, layer: content(), alignment: alignment, over: true)
    }

    /// A view drawn behind this one, both aligned in the larger of the two.
    ///
    ///     Text("New")
    ///         .background { Rectangle().cornerRadius(4).fill(.whiteSmoke) }
    public func background<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> Layered<Self, Content> {
        Layered(base: self, layer: content(), alignment: .center, over: false)
    }

    /// The same, aligned by `alignment`.
    public func background<Content: View>(
        alignment: Alignment,
        @ViewBuilder content: () -> Content
    ) -> Layered<Self, Content> {
        Layered(base: self, layer: content(), alignment: alignment, over: false)
    }

    /// What the container this view's page stands in draws behind it - its
    /// window, its sheet - reaching the view's own background where the view
    /// is clear:
    ///
    ///     DetailView()
    ///         .containerBackground(for: .window) { Color.defaultBackground }
    ///
    /// Composed as a `.background` under the view: a solid colour reads the
    /// same, and where the content is a material the window's own
    /// `windowBackground` says it closer still.
    public func containerBackground<Content: View>(
        for placement: ContainerBackgroundPlacement,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) -> Layered<Self, Content> {
        Layered(base: self, layer: content(), alignment: alignment, over: false)
    }
}

/// What `.overlay {}` and `.background {}` make: two views in a `ZStack`, the
/// base and the layer in the order `over` says.
public struct Layered<Base: View, Content: View>: View {
    /// The view the modifier was written on.
    let base: Base

    /// The other view, over or under it.
    let layer: Content

    /// How the two align inside the stack.
    let alignment: Alignment

    /// `layer` over `base`; under it where false.
    let over: Bool

    /// The two as a ZStack.
    public var body: some View {
        ZStack(alignment: alignment) {
            if over {
                base
                layer
            } else {
                layer
                base
            }
        }
    }
}
