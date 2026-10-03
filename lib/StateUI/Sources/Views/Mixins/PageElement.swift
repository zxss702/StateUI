// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The title and icon of an arrangement - a `NavigationStack`, a `TabView`
/// or a `NavigationSplitView` - read where it is shown as an item of something else,
/// such as a tab:
///
///     TabView(Tab.allCases) { tab in
///         switch tab {
///         case .home:
///             NavigationStack($homePath) {
///                 HomePage()
///             } destination: { … }
///             .title("Home")                    // the tab's caption
///             .icon("house.png")                // and its picture
///
///         case .settings:
///             SettingsPage()                    // a written page sets
///         }                                     // `page.title` instead
///     }
///
/// A page the author writes says the same through its `PageSession`.
public protocol PageElement: PropertyContainer {}

extension PageElement {
    /// What the page is called: a tab's caption, and the window's title where
    /// a platform takes one from the page.
    ///
    /// Not the text on a navigation bar, which belongs to the page on top of
    /// the stack; a title on the `NavigationStack` itself names the whole stack.
    public func title(_ value: String) -> Modified {
        setValue(PageElementContract.title, value)
    }

    /// The picture that stands for the page: a tab's icon. A page not shown as
    /// an item of something else has nowhere to draw it.
    public func icon(_ value: ImageSource) -> Modified {
        setValue(PageElementContract.icon, value)
    }

    /// The mark the item wears on its icon - a count or a short word, drawn as
    /// the container draws one:
    ///
    ///     NavigationStack($path) { MailPage() }
    ///         .title("Mail")
    ///         .badge("3")
    public func badge(_ value: String) -> Modified {
        setValue(PageElementContract.badge, value)
    }

    /// `badge` from a state, `$x`: the host writes each new mark, and no view
    /// is rebuilt for it.
    public func badge(_ state: Binding<String>) -> Modified {
        words(PageElementContract.badge, by: state)
    }

}

extension View {
    /// The title the page holding this view shows - on its navigation bar,
    /// and on a tab or the window where the platform takes one from the page:
    ///
    ///     Form { … }
    ///         .navigationTitle("Settings")
    ///
    /// Written on a page's root view it names the page itself, as `page.title`
    /// does from inside.
    public func navigationTitle(_ value: String) -> ModifiedContent {
        setting(PageElementContract.title, value)
    }

    /// `navigationTitle` from a state, `$x`: the host writes each new title,
    /// and no view is rebuilt for it.
    @_disfavoredOverload
    public func navigationTitle(_ state: Binding<String>) -> ModifiedContent {
        revised { $0.driveWords(PageElementContract.title, by: state) }
    }
}

extension View {
    /// The heights the sheet holding this view may stand at, first the one
    /// preferred:
    ///
    ///     SheetForm()
    ///         .presentationDetents([.height(220), .large])
    ///
    /// Written on a presented page's root. A platform without detents takes
    /// the largest it can as the sheet's own size.
    public func presentationDetents(_ detents: [PresentationDetent]) -> ModifiedContent {
        setting(PageElementContract.presentationDetents, detents)
    }

    /// `presentationDetents` from a state, `$x`: each new list is written as
    /// the state renders this view again.
    @_disfavoredOverload
    public func presentationDetents(_ state: Binding<[PresentationDetent]>) -> ModifiedContent {
        setting(PageElementContract.presentationDetents, state.wrappedValue)
    }

    /// Whether the sheet holding this view shows its drag handle:
    ///
    ///     SheetForm()
    ///         .presentationDragIndicator(.hidden)
    ///
    /// Written on a presented page's root.
    public func presentationDragIndicator(_ visibility: Visibility) -> ModifiedContent {
        setting(PageElementContract.presentationDragIndicator, visibility)
    }

    /// `presentationDragIndicator` from a state, `$x`: the host writes each
    /// new visibility, and no view is rebuilt for it.
    @_disfavoredOverload
    public func presentationDragIndicator(_ state: Binding<Visibility>) -> ModifiedContent {
        revised { $0.drivePlain(PageElementContract.presentationDragIndicator, by: state) }
    }

    /// Whether the user may not dismiss the sheet holding this view - its
    /// gestures, close button and backdrop press all off:
    ///
    ///     CloningSheet()
    ///         .interactiveDismissDisabled(cloning)
    ///
    /// Written on a presented page's root. `true` where the argument is left
    /// out, as SwiftUI's no-argument form is.
    public func interactiveDismissDisabled(_ disabled: Bool = true) -> ModifiedContent {
        setting(PageElementContract.interactiveDismissDisabled, disabled)
    }

    /// `interactiveDismissDisabled` from a state, `$x`: the host writes each
    /// new answer, and no view is rebuilt for it.
    @_disfavoredOverload
    public func interactiveDismissDisabled(_ state: Binding<Bool>) -> ModifiedContent {
        revised { $0.drivePlain(PageElementContract.interactiveDismissDisabled, by: state) }
    }
}
