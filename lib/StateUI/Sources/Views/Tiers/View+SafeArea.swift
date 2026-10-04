// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.safeAreaInset(edge:) {}` and `.safeAreaPadding(_:_:)` - the safe area the
// way SwiftUI names it, written out as the stack or the content padding the
// same thing is.
// Design: docs/design/views/modifiers.md#composed-modifiers

extension View {
    /// A bar pinned to `edge` the rest of the view stands clear of - the
    /// SwiftUI spelling for the stack it makes:
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
        var stack = VStack()
        if let spacing { stack.node.write(StackBaseContract.spacing, spacing) }
        let base = self
        stack.node.producer = {
            edge == .top ? [bar.node, base.node] : [base.node, bar.node]
        }
        return stack
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
        var stack = HStack()
        if let spacing { stack.node.write(StackBaseContract.spacing, spacing) }
        let base = self
        stack.node.producer = {
            edge == .leading ? [bar.node, base.node] : [base.node, bar.node]
        }
        return stack
    }
}
