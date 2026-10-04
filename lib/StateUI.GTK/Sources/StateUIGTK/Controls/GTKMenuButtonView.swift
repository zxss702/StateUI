// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIGTK

/// A `GtkMenuButton`: its face a label child's widget or a chevron alone, its
/// menu a `GMenu` model whose items activate `GSimpleAction`s wired back to the
/// elements that own them.
@MainActor
final class GTKMenuButtonView: GTKView {
    /// The action objects the menu's items activate, kept while the model lasts.
    private var actions: [UnsafeMutableRawPointer] = []

    /// The group the actions live under on the button's widget (`"menu"` prefix).
    private var actionGroup: UnsafeMutablePointer<GSimpleActionGroup>?

    /// What an action's activate runs, by the action object's address.
    private var clicks: [UInt: () -> Void] = [:]

    /// The next item's action name suffix; no two live actions share one.
    private var sequence = 0

    /// A menu button, face a chevron until a label child's widget lands.
    init() {
        super.init { _ in gtk_menu_button_new() }
    }

    /// The widget the button's face draws; GTK keeps its own arrow beside it.
    func setFace(_ face: GTKWidget?) {
        gtk_menu_button_set_child(widget.opaque, face)
    }

    /// Whether the button opens its menu - `.isEnabled`'s.
    var opensMenu = true {
        didSet { if opensMenu != oldValue { gtk_widget_set_sensitive(widget, opensMenu ? 1 : 0) } }
    }

    /// How the trigger draws: a `borderlessButton` keeps the label with no
    /// button frame around it.
    private var flatClass: String?
    var borderless = false {
        didSet { swapClass(&flatClass, to: borderless ? "flat" : nil) }
    }

    /// Whether the trigger shows the arrow that says it opens a menu.
    var showsArrow = true {
        didSet {
            if showsArrow != oldValue {
                gtk_menu_button_set_always_show_arrow(widget.opaque, showsArrow ? 1 : 0)
            }
        }
    }

    /// Rebuilds the menu model and its actions from `entries`; `clicked` is
    /// handed the element the chosen entry belongs to.
    func setEntries(_ entries: [MenuEntry], clicked: @escaping (MountedElement) -> Void) {
        gtk_menu_button_set_menu_model(widget.opaque, nil)
        if actionGroup != nil {
            gtk_widget_insert_action_group(widget, "menu", nil)
            actionGroup = nil
        }
        actions = []
        clicks = [:]
        guard !entries.isEmpty, let group = g_simple_action_group_new() else { return }

        let menu = g_menu_new()!
        fill(menu, with: entries, group: group, clicked: clicked)

        gtk_widget_insert_action_group(widget, "menu", OpaquePointer(group))
        gtk_menu_button_set_menu_model(widget.opaque, model(menu))
        actionGroup = group
    }

    /// Appends `entries` to `menu`, sections drawing the rules between groups
    /// and each item's action `menu.e<N>` under the button's group.
    private func fill(_ menu: OpaquePointer, with entries: [MenuEntry],
                      group: UnsafeMutablePointer<GSimpleActionGroup>,
                      clicked: @escaping (MountedElement) -> Void) {
        var section = g_menu_new()!
        var wroteItem = false
        for entry in entries {
            switch entry.kind {
            case .separator:
                g_menu_append_section(menu, nil, model(section))
                section = g_menu_new()!
            case .item:
                guard let owner = entry.element else { break }
                let name = "e\(sequence)"; sequence += 1
                guard let action = g_simple_action_new(name, nil) else { continue }
                g_simple_action_set_enabled(action, entry.isEnabled ? 1 : 0)
                clicks[UInt(bitPattern: action)] = { clicked(owner) }
                connectSignal(UnsafeMutableRawPointer(action), "activate", number: number) {
                    (instance: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, data: gpointer?) in
                    MainActor.assumeIsolated {
                        guard let view = GTKView.find(viewNumber(data)) as? GTKMenuButtonView,
                              let instance
                        else { return }
                        view.clicks[UInt(bitPattern: instance)]?()
                    }
                }
                actions.append(UnsafeMutableRawPointer(action))
                g_action_map_add_action(OpaquePointer(group), OpaquePointer(UnsafeMutableRawPointer(action)))
                let item = g_menu_item_new(entry.title, "menu.\(name)")!
                g_menu_append_item(section, item)
                wroteItem = true
            case .submenu:
                if wroteItem {
                    g_menu_append_section(menu, nil, model(section))
                    section = g_menu_new()!
                }
                let sub = g_menu_new()!
                fill(sub, with: entry.entries, group: group, clicked: clicked)
                g_menu_append_submenu(menu, entry.title, model(sub))
            }
        }
        g_menu_append_section(menu, nil, model(section))
    }

    /// The same opaque object as the `GMenuModel` GTK's import names.
    private func model(_ menu: OpaquePointer) -> UnsafeMutablePointer<GMenuModel> {
        UnsafeMutableRawPointer(menu).assumingMemoryBound(to: GMenuModel.self)
    }
}
