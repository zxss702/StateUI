// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIGTK

/// The GTK runtime: the mounted tree over GTK widgets, the window around it, and the turn.
/// Design: docs/design/platforms/gtk/runtime.md#the-gtk-runtime
@MainActor
final class GTKRenderer {
    /// The one runtime of the process, made when the application is activated.
    static var shared: GTKRenderer?

    /// What the host says for whoever reads its log: standard error, or wherever a test listens.
    static var log = HostLog(host: "GTK")

    let frameClock: GTKFrameClock

    /// Whether the user asked for less animation: every animation arrives at once.
    private let reducesMotion: () -> Bool

    /// The application the windows belong to.
    let application: UnsafeMutablePointer<GtkApplication>

    /// The parts every host holds alike - the core's link, the motions, the display cycle, the mounted tree and
    /// the turn - each element's GTK half a `GTKElement`.
    private(set) lazy var runtime = HostRuntime(
        clock: frameClock, reducesMotion: reducesMotion,
        makeNative: { [unowned self] element in GTKElement(element, host: self) }, log: { GTKRenderer.log.error($0) },
        localization: { key in GTKStrings.resolve(key) },
        views: { GTKView.liveCount })

    /// What performs the acts the application calls, and answers them.
    private(set) lazy var acts = GTKActPerformer(core: runtime.core)

    /// The application's ID, which the desktop knows it by.
    var applicationID: String {
        g_application_get_application_id(application.of(GApplication.self)).map { String(cString: $0) } ?? ""
    }

    /// The window the first window element shows in; nil before it says it is there.
    private(set) var window: GTKWindow?

    /// What the window shows, by the host layer's rule: its arrangement of pages, its overlay, and that it was made.
    private let presentation = WindowPresentation()

    /// A sheet for each page the window's modal stack presents, the last on top.
    private(set) var sheets: [(element: MountedElement, sheet: GTKSheet)] = []

    /// The page the window shows the user, whose menus its main menu is.
    var windowPage: MountedElement? { presentation.arrangement?.visiblePage }

    /// Whether the screen the window stands on has been told.
    private var reportedDisplay = false

    /// A runtime whose windows belong to `application`, on GLib's monotonic clock or on `clock`, with the animation
    /// `reducesMotion` allows.
    init(
        application: UnsafeMutablePointer<GtkApplication>,
        clock: (() -> Double)? = nil,
        reducesMotion: @escaping () -> Bool = { MainActor.assumeIsolated { GTKEnvironment.reducesMotion } }
    ) {
        self.application = application
        let frameClock = clock.map { GTKFrameClock(now: $0, ticksWithGTK: false) } ?? GTKFrameClock()
        self.frameClock = frameClock
        self.reducesMotion = reducesMotion
        runtime.displayCycle.presenter = self
        runtime.pump.presenter = self
    }

    /// The application was activated on GLib's thread: the first time, the first drain makes it MainActor's and
    /// the host starts; after that, a second launch brings the window forward.
    /// Design: docs/design/platforms/gtk/runtime.md#starting
    nonisolated static func activated(_ application: UnsafeMutablePointer<GtkApplication>) {
        let core = CoreLink()
        _ = core.needsRender
        _ = core.runJobs()
        nonisolated(unsafe) let application = application

        MainActor.assumeIsolated {
            if let window = shared?.window {
                window.present()
            } else {
                start(application: application)
            }
        }
    }

    /// The platform handed the application files to open - a launch under `HANDLES_OPEN` emits `open` instead of
    /// `activate`, so the host starts here where it never did; then every `onOpenURL` listener hears each URL.
    nonisolated static func opened(_ application: UnsafeMutablePointer<GtkApplication>, urls: [String]) {
        nonisolated(unsafe) let application = application
        MainActor.assumeIsolated {
            if shared == nil { start(application: application) }
            guard let runtime = shared?.runtime else { return }
            for url in urls {
                runtime.core.raise(AppContract.urlOpened, url)
            }
            runtime.pump.turn()
        }
    }

    /// Starts the host: the application rendered whole, then the doorbell for everything after.
    @discardableResult
    static func start(application: UnsafeMutablePointer<GtkApplication>) -> GTKRenderer {
        shared?.runtime.tree.root?.leave()

        let renderer = GTKRenderer(application: application)
        shared = renderer
        renderer.runtime.core.setRealization(GTKRegistrations.registry.realization, unrealized: GTKRealization.unmade)
        renderer.show()
        GTKDoorbell.install()
        return renderer
    }

    /// Renders the application whole, connecting its scene first, told what the host stands on.
    func show() {
        GTKEnvironment.report(to: runtime.core, applicationID: applicationID)
        GTKKeptValues.restore(into: runtime.core, applicationID: applicationID)
        GTKEnvironment.watch { [weak self] in self?.environmentChanged() }
        runtime.core.connectScene()
        runtime.pump.turn()
    }

    /// The desktop's style turned dark or light: the core hears it, and renders what it changed.
    func environmentChanged() {
        GTKEnvironment.reportChanging(to: runtime.core)
        runtime.pump.turn()
    }

    /// Shows the first window's arrangement of pages in a GTK window - a page by itself in a frame of its own - its
    /// pages hearing that they show, and tells the window it was made, once, in its turn.
    /// Design: docs/design/platforms/gtk/runtime.md#the-window
    private func showWindow() {
        guard let element = runtime.tree.root?.first(type: .windowScene) else { return }

        let window = self.window ?? GTKWindow(application: application)
        if self.window == nil {
            self.window = window
            frameClock.widget = window.widget
        }
        if !reportedDisplay, gtk_widget_get_realized(window.widget) != 0 {
            reportedDisplay = true
            GTKEnvironment.reportDisplay(to: runtime.core, window: window.widget)
        }
        window.setSize(width: element.value(.width)?.number, height: element.value(.height)?.number)
        window.setMinimumSize(width: element.value(.minimumWidth)?.number, height: element.value(.minimumHeight)?.number)
        window.setResizable(element.value(.resizability)?.enumeration)

        let changes = presentation.show(element, in: runtime.lifecycle)
        if let (_, arrangement) = changes.arrangement {
            if let arrangement, GTKElement.framedTypes.contains(arrangement.type) {
                window.show(page: arrangement.gtk.view)
            } else {
                window.show(arrangement?.gtk.view)
            }
        }
        if let overlay = changes.overlay { window.showOverlay(overlay?.gtk.view) }
        if let pages = changes.sheets { showSheets(pages) }
        refreshChrome()
    }

    /// Keeps a sheet for each page presented, in its order: a sheet gone closes, the last first, and one new is
    /// shown over those before it.
    /// Design: docs/design/platforms/gtk/pages.md#sheets
    private func showSheets(_ pages: [MountedElement]) {
        guard let window else { return }
        let kept = sheets.filter { entry in
            pages.contains { $0 === entry.element && $0.gtk.view === entry.sheet.page }
        }
        for entry in sheets.reversed() where !kept.contains(where: { $0.sheet === entry.sheet }) { entry.sheet.close() }
        sheets = pages.compactMap { page in
            if let entry = kept.first(where: { $0.element === page }) { return entry }
            guard let view = page.gtk.view else { return nil }
            let sheet = GTKSheet(page: view, framed: GTKElement.framedTypes.contains(page.type))
            sheet.onClosedByUser = { [weak self] in self?.dismissTopSheet() }
            sheet.present(over: window)
            return (page, sheet)
        }
    }

    /// The user took the top sheet away - Escape, its close button: the modal stack is told how many remain.
    private func dismissTopSheet() {
        guard let element = runtime.tree.root?.first(type: .windowScene), !presentation.sheets.isEmpty
        else { return }
        runtime.goBack(.dismissSheet(remaining: presentation.sheets.count - 1), in: element)
    }

    /// Writes every shown page's chrome on its header bar, and names the window after the page the user sees.
    /// Design: docs/design/platforms/gtk/pages.md#the-chrome
    func refreshChrome() {
        guard let window, let element = runtime.tree.root?.first(type: .windowScene)?.gtk else { return }

        let arrangement = presentation.arrangement?.gtk
        if let arrangement, GTKElement.framedTypes.contains(arrangement.type) {
            window.pageFrame?.show(arrangement.chrome)
        }
        arrangement?.composeChrome()
        adaptSplitViews(in: window)
        for (page, sheet) in sheets {
            let chrome = page.gtk.chrome
            sheet.frame?.show(chrome)
            sheet.setTitle(page.visiblePage?.value(.title)?.string ?? chrome.title)
            page.gtk.composeChrome()
        }
        let chrome = WindowChrome(window: element.element, arrangement: presentation.arrangement)
        window.setTitle(chrome.title.flatMap { $0.isEmpty ? nil : $0 } ?? element.value(.title)?.string)
        window.setBackground(chrome.windowBackground)
    }

    /// Collapses the window's split view where the window is narrow.
    private func adaptSplitViews(in window: GTKWindow) {
        guard let split = presentation.arrangement?.gtk, split.type == .navigationSplitView, let view = split.view as? GTKSplitView
        else { return }

        view.adapt(in: window.widget)
    }

    /// Goes the way back the window offers (`WindowPresentation.wayBack`), as the user does: a stack's top page
    /// going in GTK first, the path then told; a sheet going through the host layer. Whether there was one.
    /// Design: docs/design/host/pages.md#the-way-back
    func goBack() -> Bool {
        guard let element = runtime.tree.root?.first(type: .windowScene), let way = presentation.wayBack
        else { return false }
        switch way {
        case .pop(let stack):
            return (stack.gtk.view as? GTKNavigationView)?.popByUser() ?? false
        case .dismissSheet:
            runtime.goBack(way, in: element)
            return true
        }
    }
}

extension GTKRenderer: TurnPresenter {
    func presentRendered() {
        showWindow()
    }

    func perform(_ call: HostActCall) {
        acts.perform(call, in: runtime.tree, window: window, applicationID: applicationID)
    }
}

extension GTKRenderer: FramePresenter {
    var wantsFrames: Bool {
        runtime.frames.wantsFrames
    }

    func commitUserReports(now: Double) {
        runtime.frames.commit(now: now)
    }

    func present(states: [Int32: HostStateValue], properties: [UInt64: Set<Prop>]) {
        runtime.tree.present(states: states, properties: properties)
    }

    func renderIfNeeded() {
        if runtime.core.needsRender { runtime.pump.turn() }
    }
}
