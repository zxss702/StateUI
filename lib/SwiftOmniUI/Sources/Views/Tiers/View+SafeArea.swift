// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.safeAreaInset(edge:) {}` reserves an edge by laying the bar beside the
// content. Geometry reports that content's reduced bounds, without another inset.
// Design: docs/design/views/modifiers.md#composed-modifiers

extension View {
    /// A bar pinned to `edge`, reserving space in the content's safe area:
    ///
    ///     page.safeAreaInset(edge: .top) { Header() }
    ///
    /// `content` sits at `alignment` across the bar, `spacing` between the
    /// bar and the rest. Inside a scroll view the inset the content scrolls
    /// under is `.safeAreaPadding(_:_:)` instead.
    ///
    /// - Parameters:
    ///   - edge: `.top` or `.bottom`.
    ///   - alignment: where the bar sits across.
    ///   - spacing: the gap between the bar and the rest.
    ///   - content: the bar.
    public func safeAreaInset<Content: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let bar = content().frame(
            maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        return SafeAreaInsetContent(base: self, bar: bar,
                                    edge: edge == .top ? .top : .bottom, spacing: spacing ?? 0)
    }

    /// The same, on the horizontal axis:
    ///
    ///     page.safeAreaInset(edge: .leading) { Sidebar() }
    ///
    /// - Parameters:
    ///   - edge: `.leading` or `.trailing`.
    ///   - alignment: where the bar sits down it.
    ///   - spacing: the gap between the bar and the rest.
    ///   - content: the bar.
    public func safeAreaInset<Content: View>(
        edge: HorizontalEdge,
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let bar = content().frame(
            maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: alignment))
        return SafeAreaInsetContent(base: self, bar: bar,
                                    edge: edge == .leading ? .leading : .trailing, spacing: spacing ?? 0)
    }
}

private struct SafeAreaInsetContent<Base: View, Bar: View>: View {
    let base: Base
    let bar: Bar
    let edge: Edge
    let spacing: Double

    init(base: Base, bar: Bar, edge: Edge, spacing: Double) {
        self.base = base
        self.bar = bar
        self.edge = edge
        self.spacing = spacing
    }

    var body: some View {
        let edge = edge, spacing = spacing
        let vertical = edge == .top || edge == .bottom
        let inset = bar
        let content = base
        if vertical {
            var stack = VStack()
            stack.node.write(StackBaseContract.spacing, spacing)
            stack.node.producer = {
                edge == .top ? [inset.node, content.node] : [content.node, inset.node]
            }
            return AnyView(stack)
        }
        var stack = HStack()
        stack.node.write(StackBaseContract.spacing, spacing)
        stack.node.producer = {
                edge == .leading ? [inset.node, content.node] : [content.node, inset.node]
        }
        return AnyView(stack)
    }
}
