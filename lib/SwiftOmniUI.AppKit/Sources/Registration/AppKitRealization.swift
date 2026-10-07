// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// What this host realizes beyond its registry, whose export says the rest - the AppKit column of the control
/// dictionary; a member is recorded once a test of this package covers it.
/// Design: docs/design/contracts/dictionary.md#marks
enum AppKitRealization {
    /// The entries this host realizes none of: those it shows as unsupported, and the parts of one.
    static let unrealized: Set<String> = [
        "GridRow", "PositionIndicator",
    ]

    /// The entries this host presents with no view of their own - a title bar is the window's, a span a run of its
    /// label's words - so no tier's record reaches them: only a member the entry's own records name is realized.
    static let viewless: Set<String> = ["Span", "TitleBar"]

    /// The entries the Mac will not have; none.
    static let notPlanned: [String: String] = [:]

    /// Every record, the tiers' first.
    static let records: [HostRecord] = [
        // MARK: Tiers - a member every wearer realizes alike
        .complete("BarElement", "barBackgroundColor"),
        .complete("DecorableTextElement", "textDecorations"),
        .complete("LineHeightElement", "lineHeight"),
        .complete("MenuItemElement", "clicked"),
        .complete("MenuItemElement", "icon"),
        .complete("MenuItemElement", "isEnabled"),
        .complete("MenuItemElement", "text"),
        .complete("PageElement", "badge"),
        .complete("PageElement", "document"),
        .complete("PageElement", "icon"),
        .complete("PageElement", "interactiveDismissDisabled"),
        .complete("PageElement", "preferredColumnWidth"),
        .partial("PageElement", "presentationDetents", missing: "A macOS sheet has no detents: the first one asked for alone sizes the sheet against its parent."),
        .notPlanned("PageElement", "presentationDragIndicator", reason: "A macOS sheet has no drag indicator."),
        .complete("PageElement", "subtitle"),
        .complete("PageElement", "title"),
        .complete("PageElement", "toolbarBackground"),
        .complete("PageElement", "toolbarVisibility"),
        .complete("PageElement", "windowBackground"),
        .complete("Layout", "clipsContent"),
        .complete("VisualElement", "hint"),
        .partial("VisualElement", "accessibilityChildBehavior", missing: "AppKit leaves an element's children out alike for `.ignore` and `.combine`: `.combine` merges them into the element itself only on a platform that merges."),
        .partial("VisualElement", "accessibilityHeadingLevel", missing: "AppKit marks a heading, not its level: every level is a heading."),
        .partial("VisualElement", "accessibilityTraits", missing: "AppKit takes the traits it has a role or flag for: `playsSound`, `updatesFrequently`, `startsMediaSession`, `causesPageTurn` and `isKeyboardKey` have none."),
        .partial("VisualElement", "background", missing: "AppKit paints a colour on this view; a brush is drawn only by a layout."),
        .partial("VisualElement", "contentTransition", missing: "AppKit pushes or fades a swapped word or picture; `interpolate` draws its first kind alone."),
        .complete("VisualElement", "blendMode"),
        .complete("VisualElement", "matchedGeometry"),
        .complete("VisualElement", "matchedGeometrySource"),
        .partial("VisualElement", "symbolEffect", missing: "AppKit plays `bounce` and `pulse` over the whole view: `disappear`, `variableColor`, `drawOn` and `drawOff` have no layer to name."),
        .partial("VisualElement", "symbolEffectActive", missing: "AppKit answers it for `pulse` alone."),
        .partial("VisualElement", "symbolEffectOptions", missing: "AppKit takes `repeating` alone: a speed or a delay does nothing."),
        .partial("VisualElement", "symbolEffectValue", missing: "AppKit replays on a change for `bounce` and `pulse` alone."),
        .complete("View", "layoutPriority"),
        .complete("View", "horizontalGuide"),
        .complete("View", "verticalGuide"),
        .complete("View", "pointerStyle"),
        .partial("View", "panTouchCount", missing: "The host layer hears a one-finger pan only; any other `panTouchCount` turns the pan off."),
        .complete("VisualElement", "style"),

        // MARK: Entries - a control's or a part's own, and where it differs from its tier
        .unrealized("List", "style", why: "No style can name an List: a style names its control by an "
            + "initializer that sets nothing, which a list of some items has not."),
        .unrealized("MenuButton", "style", why: "No style can name a MenuButton: the `Menu` view makes one, "
            + "and no `Menu()` means anything; its closed style vocabulary crosses as `.menuStyle`."),
        .partial("Button", "aspect", missing: "AppKit's button has no covering scale: `.fill` fits the icon, as `.fit` does."),
        .complete("Button", "padding"),
        .partial("Button", "shape", missing: "AppKit rounds an oval button into a capsule: a layer's corners draw no oval."),
        .complete("Text", "accessibilityIdentifier"),
        .complete("Text", "characterSpacing"),
        .complete("Text", "fontAttributes"),
        .complete("Text", "fontDesign"),
        .complete("Text", "fontFamily"),
        .complete("Text", "fontSize"),
        .complete("Text", "fontTextStyle"),
        .complete("Text", "fontWeight"),
        .complete("Text", "multilineTextAlignment"),
        .complete("Text", "ignoresInput"),
        .complete("Text", "lineBreak"),
        .complete("Text", "lineLimit"),
        .complete("Text", "padding"),
        .complete("Text", "selectable"),
        .unrealized("Text", "minimumScaleFactor", why: "AppKit's label has no shrink-to-fit: the text overflows or wraps as configured."),
        .partial("Text", "textRenderer", missing: "A native control draws the words itself: a renderer watching layout degrades to the default draw pass; its own draw never runs."),
        .complete("Text", "textCase"),
        .complete("Text", "foregroundStyle"),
        .complete("Text", "verticalTextAlignment"),
        .complete("Menu", "isEnabled"),
        .complete("Menu", "text"),
        .complete("MenuButton", "isEnabled"),
        .complete("MenuButton", "menuIndicator"),
        .complete("MenuButton", "menuStyle"),
        .partial("MenuItem", "accessibilityIdentifier", missing: "Only an entry of a context menu carries it; an entry the page puts in the menu bar does not."),
        .complete("MenuItem", "isDestructive"),
        .complete("NavigationStack", "accessibilityIdentifier"),
        .partial("NavigationStack", "barForegroundColor", missing: "Only the title takes it, over a band painted in a bar colour; the toolbar's items keep the system's colour."),
        .complete("NavigationStack", "popped"),
        .complete("Popover", "arrowEdge"),
        .complete("Popover", "dismissed"),
        .complete("Popover", "isOpen"),
        .complete("Page", "appearing"),
        .complete("Page", "backButtonTitle"),
        .complete("Page", "disappearing"),
        .complete("Page", "hasBackButton"),
        .complete("Page", "hasNavigationBar"),
        // A page is no `VisualElement`: it wears `PageElement` alone, so the
        // tier's record about a background does not reach it.
        .complete("Page", "background"),
        .complete("Page", "icon"),
        .complete("Page", "navigatedFrom"),
        .complete("Page", "navigatedTo"),
        .complete("Page", "navigatingFrom"),
        .complete("Page", "title"),
        .complete("RadioButton", "groupName"),
        .complete("RadioButton", "padding"),
        .notPlanned("SearchField", "submitLabel",
                    reason: "A Mac has no keyboard on the screen whose return key says anything."),
        .notPlanned("TextField", "submitLabel",
                    reason: "A Mac has no keyboard on the screen whose return key says anything."),
        .notPlanned("TextField", "showsClearButton",
                    reason: "AppKit's text field has no button of its own that empties it."),
        .complete("Scene", "activated"),
        .complete("Scene", "deactivated"),
        .complete("Scene", "destroying"),
        .complete("Scene", "stopped"),
        .complete("Scene", "windowClosed"),
        .complete("Scene", "windowRestored"),
        .complete("ScrollView", "scrollStopped"),
        .complete("ScrollView", "scrollXChanged"),
        .complete("ScrollView", "scrollYChanged"),
        .complete("Span", "fontAttributes"),
        .complete("Span", "fontDesign"),
        .complete("Span", "fontTextStyle"),
        .complete("Span", "fontWeight"),
        .complete("Span", "text"),
        .complete("Span", "textCase"),
        .complete("NavigationSplitView", "isSidebarVisibleChanged"),
        .complete("NavigationSplitView", "columnVisibilityChanged"),
        .complete("TabView", "accessibilityIdentifier"),
        .complete("TabView", "currentPage"),
        .complete("TabView", "currentPageChanged"),
        .partial("TitleBar", "background", missing: "AppKit paints a colour on the window's bar band; a brush is drawn only by a layout."),
        .partial("TitleBar", "barForegroundColor", missing: "Only the title takes it, over a band painted in a bar colour; the toolbar's items keep the system's colour."),
        .complete("TitleBar", "icon"),
        .complete("TitleBar", "subtitle"),
        .complete("TitleBar", "title"),
        .complete("ToolbarItem", "placement"),
        .unrealized("ToolbarItem", "accessibilityIdentifier", why: "An NSToolbarItem holds no accessibility identifier."),
        .complete("ToolbarItem", "priority"),
        .complete("ToolbarSpacer", "placement"),
        .complete("ToolbarSpacer", "variant"),
        .complete("WindowScene", "activated"),
        .complete("WindowScene", "created"),
        .complete("WindowScene", "deactivated"),
        .complete("WindowScene", "destroying"),
        .complete("WindowScene", "floatsOnTop"),
        .complete("WindowScene", "height"),
        .complete("WindowScene", "hidesWhenInactive"),
        .complete("WindowScene", "isMaximizable"),
        .complete("WindowScene", "isMinimizable"),
        .complete("WindowScene", "isTranslucent"),
        .complete("WindowScene", "maximumHeight"),
        .complete("WindowScene", "maximumWidth"),
        .complete("WindowScene", "minimumHeight"),
        .complete("WindowScene", "minimumWidth"),
        .complete("WindowScene", "modalPopped"),
        .partial("WindowScene", "resizability", missing: "AppKit binds the content's least and most size to its fit: `.automatic` stands the window as it was."),
        .complete("WindowScene", "resumed"),
        .complete("WindowScene", "stopped"),
        .complete("WindowScene", "title"),
        .complete("WindowScene", "width"),
        .complete("WindowScene", "windowType"),
        .complete("WindowScene", "windowValue"),
        .complete("WindowScene", "x"),
        .complete("WindowScene", "y"),
        .complete("Grid", "background"),
        .complete("Grid", "shape"),
        .complete("Grid", "strokeWidth"),
        .complete("HStack", "background"),
        .complete("HStack", "shape"),
        .complete("HStack", "strokeWidth"),
        .complete("VStack", "background"),
        .complete("VStack", "shape"),
        .complete("VStack", "strokeWidth"),
        .complete("ZStack", "background"),
        .complete("ZStack", "shape"),
        .complete("ZStack", "strokeWidth"),
        .complete("CustomLayout", "background"),
        .complete("CustomLayout", "shape"),
        .complete("CustomLayout", "strokeWidth"),
        .complete("CustomLayout", "accessibilityIdentifier"),
        .complete("CustomLayout", "ignoresInput"),
        .complete("CustomLayout", "padding"),
        .partial("ScrollView", "stroke", missing: "AppKit outlines a scroller in a colour on a rectangle or a rounded one; an oval, or a gradient, draws none."),
        .complete("ZStack", "accessibilityIdentifier"),
        .complete("ZStack", "ignoresInput"),
        .complete("ZStack", "padding"),
        .complete("Masked", "background"),
        .complete("Masked", "shape"),
        .complete("Masked", "strokeWidth"),
        .complete("Masked", "accessibilityIdentifier"),
        .complete("Masked", "ignoresInput"),
        .complete("Masked", "padding"),
    ]

    /// What AppKit's registry says it realizes: the export's content.
    @MainActor static var declaration: HostDeclaration {
        let registry = AppKitRegistrations.registry
        return HostDeclaration(
            realization: registry.realization, shared: registry.sharedNames,
            acts: AppKitRegistrations.acts.map(\.name))
    }

    /// What AppKit realizes, member by member: these records before what its registry says.
    @MainActor static var register: HostRegister {
        HostRegister(records: records, unrealized: unrealized, viewless: viewless, notPlanned: notPlanned).and(declaration)
    }
}
