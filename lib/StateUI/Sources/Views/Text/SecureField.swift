// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A text field whose text is hidden behind the platform's secure-entry
/// marks - a `TextField` marked `isPassword`, given SwiftUI's name for one.
///
///     @State private var apiKey = ""
///
///     SecureField("Paste the key here", text: $apiKey)
///
/// Every `TextField` modifier applies to it - it is one wearing a flag -
/// through the modifiers `View` gives every view; the field's own set is
/// reached through `TextField` itself where `Style<TextField>` needs it.
public struct SecureField: View {
    /// The words the field shows while empty.
    let title: String

    /// The two-way state the text rides.
    let text: Binding<String>

    /// A secure field captioned `title` while it is empty, two-way on `text`.
    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self.text = text
    }

    /// The field, captioned and marked.
    public var body: some View {
        TextField(title, text: text).isPassword(true)
    }
}
