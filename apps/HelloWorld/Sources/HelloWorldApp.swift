@_spi(Host) import SwiftOmniUI

/// The application: one window, one page.
///
/// An application is its state and the scene built from it - here a window
/// alone, which is a scene of one window. What the window SHOWS - its page and
/// the arrangement inside it - is the window's own declaration below; what it
/// is called and how big it opens are its session's, written from a view in it
/// (`@Environment private var window: WindowSession`).
struct HelloWorldApp: App {
    /// The application as it runs - where its styles go.
    @Environment private var application: ApplicationSession

    /// The application's styles - see Styles/AppStyles.swift - written
    /// as the application is made. A colour in one follows the color scheme by
    /// itself.
    init() {
        application.styles = AppStyles.sheet
    }

    var body: some Scene { Window { MainPage() } }
}

// Everything on screen is described in Swift and materialized by the selected
// host as native controls. The page it opens is MainPage.swift beside this
// file - and where an app wants a stack, tabs or a menu, a `NavigationStack`,
// a `TabView` or a `NavigationSplitView` goes in the window's closure instead,
// each over state the app owns. The sample app in the SwiftOmniUI repository is
// written that way throughout.

/// The one thing this module exports - the line that names this application to
/// the host. It cannot move into the library: the dependency runs app ->
/// library, and a host that loads the app as a separate native library finds it
/// by this name.
@_cdecl("swiftomniui_app_register")
public func swiftomniui_app_register() {
    stateUIUseApp(HelloWorldApp())
}
