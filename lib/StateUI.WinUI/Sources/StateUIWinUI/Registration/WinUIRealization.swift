// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// What this host realizes beyond its registry, whose export says the rest - the WinUI 3 column of the control
/// dictionary; a member is recorded once a test of this package covers it.
/// Design: docs/design/contracts/dictionary.md#marks
enum WinUIRealization {
    /// The entries this host realizes none of: those it shows as unsupported, and the parts of one.
    static let unrealized: Set<String> = [
        "Content", "LeadingContent", "Map", "Pin", "PositionIndicator", "TitleBar", "TrailingContent",
        "WebView",
    ]

    /// The entries this host presents with no view of their own - a span is a run of its label's words - so no
    /// tier's record reaches them: only a member the entry's own records name is realized.
    static let viewless: Set<String> = ["Span"]

    /// The entries Windows will not have; none.
    static let notPlanned: [String: String] = [:]

    /// Every record, the tiers' first.
    static let records: [HostRecord] = [
        // MARK: Tiers - a member every wearer realizes alike
        .complete("MenuItemElement", "clicked"),
        .complete("MenuItemElement", "isEnabled"),
        .complete("MenuItemElement", "text"),
        .complete("PageElement", "title"),
        .complete("VisualElement", "style"),

        // MARK: Entries - a control's or a part's own
        .partial("DatePicker", "format", missing: "WinUI writes \"D\" and \"d\" in the user's own way, and any other pattern as \"d\"."),
        .unrealized("List", "style", why: "No style can name an List: a style names its control by an "
            + "initializer that sets nothing, which a list of some items has not."),
        .complete("Menu", "isEnabled"),
        .complete("Menu", "text"),
        .complete("NavigationStack", "popped"),
        .complete("Page", "appearing"),
        .complete("Page", "background"),
        .complete("Page", "disappearing"),
        .complete("Page", "hasNavigationBar"),
        .complete("Page", "navigatedFrom"),
        .complete("Page", "navigatedTo"),
        .complete("Page", "navigatingFrom"),
        .complete("Page", "contentPadding"),
        .complete("RadioButton", "groupName"),
        .complete("Scene", "activated"),
        .complete("Scene", "deactivated"),
        .complete("Scene", "destroying"),
        .complete("Scene", "stopped"),
        .complete("Scene", "windowClosed"),
        .complete("Scene", "windowRestored"),
        .complete("Span", "background"),
        .complete("Span", "characterSpacing"),
        .complete("Span", "fontAttributes"),
        .complete("Span", "fontFamily"),
        .complete("Span", "fontSize"),
        .complete("Span", "text"),
        .complete("Span", "textCase"),
        .complete("Span", "foregroundStyle"),
        .complete("Span", "textDecorations"),
        .complete("NavigationSplitView", "isSidebarVisible"),
        .complete("NavigationSplitView", "isSidebarVisibleChanged"),
        .complete("TabView", "currentPage"),
        .complete("TabView", "currentPageChanged"),
        .partial("TimePicker", "format", missing: "WinUI's time picker writes hours and minutes as the user's clock does, whatever the format asks: no seconds, no pattern."),
        .complete("ToolbarItem", "icon"),
        .complete("ToolbarItem", "placement"),
        .complete("ToolbarItem", "priority"),
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
        .complete("WindowScene", "resumed"),
        .complete("WindowScene", "stopped"),
        .complete("WindowScene", "title"),
        .complete("WindowScene", "width"),
        .complete("WindowScene", "windowType"),
        .complete("WindowScene", "windowValue"),
        .complete("WindowScene", "x"),
        .complete("WindowScene", "y"),
    ]

    /// What WinUI's registry says it realizes: the export's content.
    @MainActor static var declaration: HostDeclaration {
        let registry = WinUIRegistrations.registry
        return HostDeclaration(
            realization: registry.realization, shared: registry.sharedNames,
            acts: (HostActs.performed + [AppContract.persistSceneValue, ListContract.scrollTo]).map(\.name))
    }

    /// What WinUI realizes, member by member: these records before what its registry says.
    @MainActor static var register: HostRegister {
        HostRegister(records: records, unrealized: unrealized, viewless: viewless, notPlanned: notPlanned).and(declaration)
    }
}
