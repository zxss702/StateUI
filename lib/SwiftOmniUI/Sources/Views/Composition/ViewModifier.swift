// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// A reusable bundle of modifiers, named and shared: the SwiftUI `ViewModifier`
// shape - `body(content:)` takes the view it was written on and hands back
// the composition to stand in its place.

/// A modifier that composes a view from the one it is applied to: a bundle of
/// ordinary modifiers and structure behind one name.
///
///     struct Blurred: ViewModifier {
///         func body(content: Content) -> some View {
///             content.blur(radius: 8)
///         }
///     }
///
///     Text("Ready").modifier(Blurred())
@preconcurrency @MainActor public protocol ViewModifier {
    /// What `body(content:)` builds in the content's place.
    associatedtype Body: View

    /// The view the modifier was written on.
    typealias Content = _ViewModifier_Content<Self>

    /// Builds the composition that stands for `content`.
    @ViewBuilder func body(content: Content) -> Self.Body
}

/// What a `ViewModifier`'s `body(content:)` is handed: the view the modifier
/// was applied to, wrapped so it composes inside the modifier's own tree.
public struct _ViewModifier_Content<Modifier: ViewModifier>: View {
    /// The view the modifier was applied to.
    let view: AnyView

    /// The content, standing as itself inside the modifier's composition.
    public var node: Node { view.node }
}

extension View {
    /// Applies `modifier` to this view: whatever its `body` composes from this
    /// view stands in its place.
    ///
    ///     Text("Ready").modifier(Blurred())
    ///
    /// - Parameter modifier: The bundle of changes to apply.
    @ViewBuilder public func modifier<M: ViewModifier>(_ modifier: M) -> some View {
        modifier.body(content: _ViewModifier_Content(view: AnyView(self)))
    }
}
