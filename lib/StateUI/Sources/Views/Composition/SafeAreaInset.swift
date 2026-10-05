// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.safeAreaInset`: a bar pinned to an edge of the window, over the content.

extension View {
    /// A bar pinned to an edge of the window, drawn over the content.
    ///
    ///     List(items) { Row($0) }
    ///         .safeAreaInset(edge: .bottom) { NowPlayingBar() }
    ///
    /// The inset is the window's own overlay - it rides the window rather
    /// than the view it was written on, so it holds its place over a
    /// navigation's pushes and pops alike. A second `.safeAreaInset` written
    /// for the same edge replaces the first, as a window's edge is one place.
    ///
    /// - Parameters:
    ///   - edge: the window's edge the bar stands on.
    ///   - alignment: where on the edge it goes - the edge's other two
    ///     directions are the window's corners.
    ///   - content: the bar.
    public func safeAreaInset<Content: View>(
        edge: Edge,
        alignment: AxisAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        SafeAreaInsetAnchor(
            base: self, edge: edge, alignment: alignment, inset: content)
    }
}

/// The anchor `.safeAreaInset` leaves in the tree: the view it was written
/// on, plus a hook that writes the window's overlay for that edge.
struct SafeAreaInsetAnchor<Content: View>: View {
    /// The view `.safeAreaInset` was written on.
    let base: any View

    /// The edge the inset stands on.
    let edge: Edge

    /// Where on the edge it goes.
    let alignment: AxisAlignment

    /// The bar.
    let inset: () -> Content

    /// The window the overlay rides.
    @Environment var window: WindowSession

    /// The overlay key this edge answers: one place per edge of the window.
    private var key: OverlayKey { OverlayKey("stateui.safeAreaInset.\(edge.rawValue)") }

    var body: some View {
        base
            .onAppear {
                window.overlays[key] = InsetView(edge: edge, alignment: alignment, inset: inset)
            }
            .onDisappear {
                window.overlays[key] = nil
            }
    }
}

/// What the overlay shows: the bar, laid along its edge.
private struct InsetView<Content: View>: View {
    /// The edge the inset stands on.
    let edge: Edge

    /// Where on the edge it goes.
    let alignment: AxisAlignment

    /// The bar.
    let inset: () -> Content

    var body: some View {
        // The overlay's own stack: the bar at its edge, the window's whole
        // room behind it letting touches through. On the edge's own axis it
        // fills; across it the alignment says where.
        let pinned = inset()
        return pinned
            .verticalAlignment(edge == .top ? .start : edge == .bottom ? .end : alignment)
            .horizontalAlignment(edge == .leading ? .start : edge == .trailing ? .end : alignment)
    }
}

extension View {
    /// Lets this view under parts of the screen's unsafe strip - the notch,
    /// the bars, the on-screen keyboard:
    ///
    ///     Color.cornflowerBlue.ignoresSafeArea()
    ///     DocView().ignoresSafeArea(.container, edges: .top)
    ///
    /// The SwiftUI form; `ignoresSafeArea(_:)` on a `Layout`, which says what
    /// the layout stays clear of, is the same thing said the other way. As
    /// there, the page's own layout is the one the strip is real for - deeper
    /// views stand where the page puts them, and a platform with no unsafe
    /// strip draws no difference.
    ///
    /// - Parameters:
    ///   - regions: which strips to ignore - `.container`, `.keyboard` or
    ///     `.all`, the last the default.
    ///   - edges: which edges it counts on, `.all` the default.
    public func ignoresSafeArea(
        _ regions: SafeAreaRegions = .all,
        edges: Edge.Set = .all
    ) -> ModifiedContent {
        let answer = regions.stayingClearOf
        let edges: SafeAreaEdges = edges == .all
            ? .uniform(answer)
            : .edges(
                left: edges.contains(.leading) ? answer : .container,
                top: edges.contains(.top) ? answer : .container,
                right: edges.contains(.trailing) ? answer : .container,
                bottom: edges.contains(.bottom) ? answer : .container)
        return setting(LayoutContract.ignoresSafeArea, edges)
    }
}
