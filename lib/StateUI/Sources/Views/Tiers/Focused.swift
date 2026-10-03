// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The keyboard focus as a two-way binding: heard off the element and asked of it.
// Design: docs/design/core/acts.md#focus-and-the-keyboard

extension View {
    /// Whether this view holds the keyboard focus, both ways.
    ///
    ///     @State private var editing = false
    ///
    ///     TextField($name)
    ///         .focused($editing)
    ///
    /// The platform's move of the focus writes `editing`, and writing it asks
    /// the platform to move the focus here - or off it - through the `focus`
    /// and `unfocus` acts. A write that changes nothing asks for nothing, and
    /// asking the focus of a view no longer on screen is dropped rather than
    /// reported: by the time the ask lands, the answer would be stale anyway.
    ///
    /// An `.aim` of the author's wins where the two are written on one view:
    /// the binding still reports, but a write cannot be aimed after the aim
    /// was given to somebody else.
    public func focused(_ condition: Binding<Bool>) -> ModifiedContent {
        let aim = AimBox()
        return revised { $0.aim = $0.aim ?? aim }
            .hearing(VisualElementContract.isFocusedChanged) { focused in
                condition.wrappedValue = focused
            }
            .onChange(of: condition.wrappedValue) { _, focused in
                guard let target = try? aim.target else { return }
                do {
                    if focused {
                        _ = try await Renderer.shared.call(VisualElementContract.focus.token, [target])
                    } else {
                        _ = try await Renderer.shared.call(VisualElementContract.unfocus.token, [target])
                    }
                } catch {}
            }
    }
}
