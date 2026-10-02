// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The colour and letter spacing of a control's text, without the text
/// itself - worn by the pickers too, which format a value rather than show a
/// text of their own. A control that says something wears `TextElement`.
public protocol TextStyleElement: PropertyContainer {}

extension TextStyleElement {
    /// The colour of the text; a `Color(light:dark:)` follows the system color scheme.
    public func foregroundStyle(_ value: Color) -> Modified { setValue(TextStyleElementContract.foregroundStyle, value) }

    /// The space added between letters, in device units.
    public func characterSpacing(_ value: Double) -> Modified { setValue(TextStyleElementContract.characterSpacing, value) }
}

extension TextStyleElement where Self: VisualElement {
    /// `characterSpacing` from a state, `$x`: the host animates the property to
    /// each new value, and no view is rebuilt for it.
    public func characterSpacing(_ state: Binding<Double>) -> Modified {
        journey(TextStyleElementContract.characterSpacing, by: state)
    }

    /// `foregroundStyle` from a state, `$x`: the host animates the property to each
    /// new value, and no view is rebuilt for it.
    public func foregroundStyle(_ state: Binding<Color>) -> Modified {
        journey(TextStyleElementContract.foregroundStyle, by: state)
    }
}
