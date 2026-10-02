// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A window whose page is written in place - the one line of scene a
/// one-window application needs:
///
///     @main
///     struct NotesApp: App {
///         var body: some Scene { Window { MainPage() } }
///     }
///
/// The window's own declarations - a type that sizes, shows a sheet, answers
/// its lifecycle - are still written as a `WindowScene` of their own, which
/// `page` here stands in for.
public struct Window<Content: View>: WindowScene {
    /// The page's view, rebuilt when a state the closure reads changes.
    let content: () -> Content

    /// A window showing what the closure builds.
    ///
    /// - Parameter content: the window's page - a view, or an arrangement such
    ///   as a `NavigationStack`, `TabView` or `NavigationSplitView`.
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// The window's page: the closure's view, whatever a session's build asks.
    public var page: any Page { content() }
}
