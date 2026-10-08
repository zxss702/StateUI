// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The clipboard, asked as an act like every question for the platform.

/// The clipboard: text the user carries between applications.
///
///     try await Pasteboard.copy(commit.hex)
///
public enum Pasteboard {
    /// Puts `text` on the clipboard, replacing what it held.
    ///
    /// - Throws: `SwiftOmniUIError` when there is no page on screen to ask
    ///   through.
    public static nonisolated(nonsending) func copy(_ text: String) async throws {
        try await stateUICall(AppContract.copyText, text)
    }
}
