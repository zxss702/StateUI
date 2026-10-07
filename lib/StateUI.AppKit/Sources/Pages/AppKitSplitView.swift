// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// AppKit's presentation of a split view: the sidebar page in a native
/// sidebar, the detail page beside it.
///
/// The split view spans the whole window, under the title bar and toolbar, so
/// the sidebar runs the window's full height as a Mac sidebar does; each pane
/// keeps its page out of the part the title bar covers. The window's toolbar
/// carries the system sidebar toggle and a separator that tracks the divider.
/// Whether the sidebar shows is StateUI's binding. The host's one adaptation
/// is that a window wide enough for both panes opens with it shown; after
/// that, the user and the application decide.
@MainActor
final class AppKitSplitView: AppKitHitTestView {
    var onPresentationChanged: ((Bool) -> Void)?

    /// What the split does when the user moves which of three columns show.
    var onVisibilityChanged: ((NavigationSplitViewVisibility) -> Void)?

    /// The native split view controller the window's toolbar toggles.
    let splitController = NSSplitViewController()

    /// The width at which a window opens with both panes shown.
    private static let sidebarRoom: Double = 720

    private let sidebarController = NSViewController()
    private let contentController = NSViewController()
    private let detailController = NSViewController()
    private let sidebarSurface = AppKitPaneView()
    private let contentSurface = AppKitPaneView()
    private let detailSurface = AppKitPaneView()
    private lazy var sidebarItem = NSSplitViewItem(
        sidebarWithViewController: sidebarController)
    private lazy var contentItem = NSSplitViewItem(
        viewController: contentController)
    private lazy var detailItem = NSSplitViewItem(
        viewController: detailController)
    private var lastEffectivePresentation = false
    private var lastEffectiveVisibility: NavigationSplitViewVisibility?
    private var adaptation = SidebarAdaptation()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        sidebarSurface.insetsBySafeArea = true
        contentSurface.insetsBySafeArea = true
        detailSurface.insetsBySafeArea = true
        sidebarController.view = sidebarSurface
        contentController.view = contentSurface
        detailController.view = detailSurface
        sidebarItem.canCollapse = true
        sidebarItem.allowsFullHeightLayout = true
        sidebarItem.minimumThickness = 260
        sidebarItem.maximumThickness = 340
        contentItem.canCollapse = true
        contentItem.minimumThickness = 200
        splitController.addSplitViewItem(sidebarItem)
        splitController.addSplitViewItem(detailItem)
        splitController.splitView.isVertical = true
        splitController.splitView.dividerStyle = .thin
        splitController.splitView.translatesAutoresizingMaskIntoConstraints = true
        splitController.splitView.autoresizingMask = [.width, .height]
        splitController.view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(splitController.view)

        ProgramWrite.perform {
            sidebarItem.isCollapsed = true
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(splitViewResized(_:)),
            name: NSSplitView.didResizeSubviewsNotification,
            object: splitController.splitView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AppKitSplitView is created in code")
    }

    override var isFlipped: Bool { true }

    /// Shows a row across the top of the detail - the tabs of a tabbed view
    /// standing in it - as the detail item's own accessory, or takes it away.
    /// Split view item accessories are macOS 26's; before it the window's
    /// title bar holds the row instead (synchronizeTabRow decides).
    @available(macOS 26, *)
    func setDetailRow(_ row: NSView?) {
        let standing = detailItem.topAlignedAccessoryViewControllers.first?.view
        guard standing !== row else { return }

        if !detailItem.topAlignedAccessoryViewControllers.isEmpty {
            detailItem.removeTopAlignedAccessoryViewController(at: 0)
        }
        if let row {
            let accessory = NSSplitViewItemAccessoryViewController()
            accessory.view = row
            // The row stands over the page rather than on a band of its own:
            // a soft edge lets the page show beneath the tabs.
            if #available(macOS 26.1, *) { accessory.preferredScrollEdgeEffectStyle = .soft }
            detailItem.addTopAlignedAccessoryViewController(accessory)
        }

        // The row changes the detail's safe area, which lays nothing out: once
        // AppKit has placed the row, the detail lays its page out again in it.
        splitController.splitView.layoutSubtreeIfNeeded()
        detailSurface.needsLayout = true
    }

    /// Paints the part of the detail the window's bars cover in the colour
    /// written for them, or leaves it to the system's material.
    func setDetailBarColor(_ color: NSColor?) {
        detailSurface.barColor = color
    }

    var detailBarColorForTesting: NSColor? { detailSurface.barColor }
    var sidebarBarColorForTesting: NSColor? { sidebarSurface.barColor }

    @available(macOS 26, *)
    var detailRowForTesting: NSView? {
        detailItem.topAlignedAccessoryViewControllers.first?.view
    }

    @available(macOS 26, *)
    var detailRowAccessoryForTesting: NSSplitViewItemAccessoryViewController? {
        detailItem.topAlignedAccessoryViewControllers.first
    }

    func setItems(_ items: [AppKitLayoutItem]) {
        let sidebar = items.first
        let content = items.count > 2 ? items[1] : nil
        let detail = items.count > 1 ? items[items.count - 1] : nil

        // THE PANES IT HAS: a patch on its way to a page applies this view
        // again, and that asks nothing of it.
        guard !AppKitLayoutItem.sameArrangement(sidebarSurface.item, sidebar)
            || !AppKitLayoutItem.sameArrangement(contentSurface.item, content)
            || !AppKitLayoutItem.sameArrangement(detailSurface.item, detail)
        else { return }

        // A content column is a third split item the sidebar and the detail
        // make room for; a two-column split never mounts one.
        if content != nil, !splitController.splitViewItems.contains(contentItem) {
            splitController.insertSplitViewItem(contentItem, at: 1)
            lastEffectiveVisibility = nil
        } else if content == nil, splitController.splitViewItems.contains(contentItem) {
            splitController.removeSplitViewItem(contentItem)
            lastEffectiveVisibility = nil
        }

        sidebarSurface.setItem(sidebar)
        contentSurface.setItem(content)
        detailSurface.setItem(detail)
        invalidateIntrinsicContentSize()
        needsLayout = true
    }

    /// Applies Swift's value without echoing it back as a user's change.
    func apply(presented: Bool) {
        setSidebarPresented(presented, reporting: false)
    }

    /// Applies the columns the binding says show, without echoing a user's
    /// change back. `.automatic` asks nothing: the room decides, as it does
    /// for a sidebar with no binding.
    func apply(visibility: NavigationSplitViewVisibility) {
        let threeColumns = contentSurface.item != nil
        switch visibility {
        case .automatic:
            break
        case .all:
            setSidebarPresented(true, reporting: false)
            setContentPresented(true, reporting: false)
        case .doubleColumn:
            // Two columns: of three, the content and the detail; of two,
            // the sidebar and the detail.
            setSidebarPresented(!threeColumns, reporting: false)
            setContentPresented(true, reporting: false)
        case .detailOnly:
            setSidebarPresented(false, reporting: false)
            setContentPresented(false, reporting: false)
        }
    }

    /// Bounds the panes the tree asks: each column's least, ideal and most
    /// width as `preferredColumnWidth` carries them, `nil` keeping the
    /// split's own. An ideal stands the divider there the first time it is
    /// asked - the user's own dragging after stands.
    func apply(sidebarWidth: [Double]?, contentWidth: [Double]?, detailWidth: [Double]?) {
        if let widths = sidebarWidth, !widths.isEmpty {
            sidebarItem.minimumThickness = CGFloat(widths[0])
            if widths.count > 2 {
                sidebarItem.maximumThickness = max(CGFloat(widths[0]), CGFloat(widths[2]))
            }
            if widths.count > 1, sidebarItem.maximumThickness >= CGFloat(widths[1]),
               sidebarWidthAsked != widths[1] {
                sidebarWidthAsked = widths[1]
                if !sidebarItem.isCollapsed {
                    splitController.splitView.setPosition(CGFloat(widths[1]), ofDividerAt: 0)
                }
            }
        }
        if let widths = contentWidth, !widths.isEmpty {
            contentItem.minimumThickness = CGFloat(widths[0])
            if widths.count > 2 {
                contentItem.maximumThickness = max(CGFloat(widths[0]), CGFloat(widths[2]))
            }
        }
        if let widths = detailWidth, !widths.isEmpty {
            detailItem.minimumThickness = CGFloat(widths[0])
            if widths.count > 2 {
                detailItem.maximumThickness = max(CGFloat(widths[0]), CGFloat(widths[2]))
            }
        }
    }

    /// The sidebar width the tree last asked, so a repeated ask does not pull
    /// the divider back from where the user put it.
    private var sidebarWidthAsked: Double?

    override var intrinsicContentSize: NSSize {
        let sidebar = sidebarSurface.intrinsicContentSize
        let content = contentSurface.intrinsicContentSize
        let detail = detailSurface.intrinsicContentSize
        let divider = splitController.splitView.dividerThickness
        let panes = sidebar.width + divider + content.width + divider + detail.width
        return NSSize(
            width: max(detail.width, panes),
            height: max(sidebar.height, content.height, detail.height))
    }

    override func layout() {
        super.layout()
        splitController.view.frame = bounds
        adaptToFirstRoom()
        splitController.view.layoutSubtreeIfNeeded()

        // A detached NSSplitViewController has no parent view controller to
        // constrain its split view. AppKit otherwise keeps the panes at their
        // fitting height, allowing a tall document to escape above this host
        // surface. The native split view owns pane layout within these bounds.
        splitController.splitView.frame = splitController.view.bounds
        splitController.splitView.needsLayout = true
        splitController.splitView.layoutSubtreeIfNeeded()
    }

    /// The host's one adaptation: a window wide enough for both panes opens
    /// with its sidebar shown, and reports it to the binding.
    private func adaptToFirstRoom() {
        guard adaptation.room(Double(bounds.width), breakpoint: Self.sidebarRoom, shown: isEffectivelyPresented)
        else { return }

        setSidebarPresented(true, reporting: true)
    }

    private func setSidebarPresented(_ presented: Bool, reporting: Bool) {
        let previous = !sidebarItem.isCollapsed
        guard previous != presented else {
            lastEffectivePresentation = presented
            return
        }

        ProgramWrite.perform {
            sidebarItem.isCollapsed = !presented
        }
        lastEffectivePresentation = presented

        if reporting {
            if let visibility = effectiveVisibility {
                lastEffectiveVisibility = visibility
                onVisibilityChanged?(visibility)
            } else {
                onPresentationChanged?(presented)
            }
        }
    }

    /// The content column's collapse, where a third column stands.
    private func setContentPresented(_ presented: Bool, reporting: Bool) {
        guard splitController.splitViewItems.contains(contentItem) else { return }
        let previous = !contentItem.isCollapsed
        guard previous != presented else { return }

        ProgramWrite.perform {
            contentItem.isCollapsed = !presented
        }

        if reporting, let moved = effectiveVisibility {
            onVisibilityChanged?(moved)
        }
    }

    /// Which columns stand shown on screen, where three can.
    private var effectiveVisibility: NavigationSplitViewVisibility? {
        guard splitController.splitViewItems.contains(contentItem) else { return nil }
        switch (!sidebarItem.isCollapsed, !contentItem.isCollapsed) {
        case (true, true): return .all
        case (false, true): return .doubleColumn
        case (false, false): return .detailOnly
        // The detail alone never stands under the sidebar on screen.
        case (true, false): return .all
        }
    }

    @objc private func splitViewResized(_ notification: Notification) {
        guard !ProgramWrite.isWriting else { return }

        if let visibility = effectiveVisibility {
            // The first pass through lays the panes out at their written
            // state; what it reports then is no move of the user's.
            guard let last = lastEffectiveVisibility else {
                lastEffectiveVisibility = visibility
                return
            }
            guard visibility != last else { return }
            lastEffectiveVisibility = visibility
            lastEffectivePresentation = !sidebarItem.isCollapsed
            onVisibilityChanged?(visibility)
            return
        }

        let presented = !sidebarItem.isCollapsed
        guard presented != lastEffectivePresentation else { return }

        lastEffectivePresentation = presented
        onPresentationChanged?(presented)
    }

    var isEffectivelyPresented: Bool { !sidebarItem.isCollapsed }
    var isEffectivelyPresentedForTesting: Bool { isEffectivelyPresented }
    var sidebarWidthForTesting: CGFloat {
        splitController.splitView.subviews.first?.frame.width ?? 0
    }

    /// What the user's sidebar toggle leaves behind, without its animation.
    func toggleForTesting() {
        sidebarItem.isCollapsed.toggle()
    }
}

#endif
