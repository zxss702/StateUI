// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIGTK

/// A `GtkButton`: its caption and how it looks, whether it takes a press, and the click it raises.
@MainActor
final class GTKButtonView: GTKView {
    /// What the button does when the user clicks it.
    var onClicked: (() -> Void)?

    /// What a staying-pressed button reports when a press flips it - `isOn`
    /// worn on the element at all makes it one.
    var onToggled: ((Bool) -> Void)?

    /// Whether the press keeps - `isOn` worn at all. A button that keeps
    /// nothing has its active taken back on each click.
    private var toggleable = false

    /// A button, or one that stays pressed in while what it turns on is on.
    init(toggles: Bool = false) {
        super.init { _ in toggles ? gtk_toggle_button_new() : gtk_button_new() }
        connect("clicked") { _, data in
            MainActor.assumeIsolated { GTKView.find(viewNumber(data))?.clicked() }
        }
    }

    /// The shortcut's controller while the button has one.
    private var shortcutController: OpaquePointer?

    /// The keyboard shortcut, as a controller that activates the button for
    /// the key and modifiers named - Control for the platform's command key.
    func setShortcut(_ shortcut: KeyboardShortcut?) {
        if let controller = shortcutController {
            gtk_widget_remove_controller(widget, controller)
            shortcutController = nil
        }
        guard let shortcut else { return }
        let keyval = Self.keyval(shortcut.key.name)
        guard keyval != GDK_KEY_VoidSymbol else { return }
        var modifiers = GdkModifierType(rawValue: 0)
        if shortcut.modifiers.contains(.command) || shortcut.modifiers.contains(.control) {
            modifiers.insert(GDK_CONTROL_MASK)
        }
        if shortcut.modifiers.contains(.shift) { modifiers.insert(GDK_SHIFT_MASK) }
        if shortcut.modifiers.contains(.option) { modifiers.insert(GDK_ALT_MASK) }
        guard let controller = gtk_shortcut_controller_new(),
              let trigger = gtk_keyval_trigger_new(keyval, modifiers),
              let action = gtk_callback_action_new({ target, _, _ in
                  target.map { gtk_widget_activate($0) } ?? 0
              }, widget, nil),
              let made = gtk_shortcut_new(trigger, action)
        else { return }
        gtk_shortcut_controller_add_shortcut(controller, made)
        gtk_widget_add_controller(widget, controller)
        shortcutController = controller
    }

    /// The key's GDK keyval: the named keys by the names GDK gives them, a
    /// character by itself.
    private static func keyval(_ name: String) -> guint {
        let gdk: String = switch name {
        case "return": "Return"
        case "escape": "Escape"
        case "tab": "Tab"
        case "space": "space"
        case "delete": "BackSpace"
        case "deleteforward": "Delete"
        case "up": "Up"
        case "down": "Down"
        case "left": "Left"
        case "right": "Right"
        case "home": "Home"
        case "end": "End"
        case "pageup": "Page_Up"
        case "pagedown": "Page_Down"
        default: name
        }
        return gdk.withCString { gdk_keyval_from_name($0) }
    }

    /// The logical style's CSS classes on the widget now.
    private var styleClasses: [String] = []

    /// The logical style, mapped to the look GTK's own buttons take for it.
    func setStyle(_ style: ButtonStyleKind?) {
        let wanted: [String] = switch style ?? .automatic {
        case .borderedProminent: ["suggested-action"]
        case .plain, .borderless: ["flat"]
        case .link: ["flat", "link"]
        default: []
        }
        for name in styleClasses where !wanted.contains(name) { gtk_widget_remove_css_class(widget, name) }
        for name in wanted where !styleClasses.contains(name) { gtk_widget_add_css_class(widget, name) }
        styleClasses = wanted
    }

    /// How the caption's words look.
    private(set) var look = TextLook()

    /// The style sheet's class drawing the button's box.
    private var boxClass: String?

    /// The caption.
    func setText(_ text: String) {
        gtk_button_set_label(widget.of(GtkButton.self), text)
        writeLook()
    }

    /// Changes how the caption's words look.
    func setLook(_ change: (inout TextLook) -> Void) {
        change(&look)
        writeLook()
    }

    /// Writes the look on the label the button shows its caption in.
    private func writeLook() {
        guard let label = gtk_button_get_child(widget.of(GtkButton.self)),
              g_type_check_instance_is_a(label.of(GTypeInstance.self), gtk_label_get_type()) != 0
        else { return }
        let list = pango_attr_list_new()!
        look.insert(into: list)
        gtk_label_set_attributes(label.opaque, list)
        pango_attr_list_unref(list)
    }

    /// The button's box - its fill, its outline's colour and width, and its shape - as a class of the host's style
    /// sheet; what is nil stays the platform's.
    /// Design: docs/design/platforms/gtk/controls.md#a-buttons-box
    func setBox(fill: HostValue?, stroke: HostValue?, strokeWidth: Double?, shape: HostValue?) {
        let radius: Double? = switch shape.map(BoxArithmetic.outline) {
        case .roundedRectangle(let radius)?: radius
        case .ellipse?: 9999
        case .rectangle?: 0
        case nil: nil
        }
        let drawn = GTKStyleSheet.box(
            fill: fill.flatMap { GTKBrush($0).firstColor }, stroke: stroke.flatMap { GTKBrush($0).firstColor },
            strokeWidth: stroke == nil ? nil : BoxArithmetic.outlineWidth(stroke: stroke, width: strokeWidth),
            radius: radius)
        guard drawn != boxClass else { return }
        if let boxClass { gtk_widget_remove_css_class(widget, boxClass) }
        if let drawn { gtk_widget_add_css_class(widget, drawn) }
        boxClass = drawn
    }

    /// A picture in place of the caption, `size` logical pixels across; the caption stays the button's name to
    /// assistive technology and its tooltip. Whether there was such a picture.
    @discardableResult
    func setIcon(_ name: String, size: Int32, caption: String) -> Bool {
        guard let image = GTKPictures.icon(named: name, size: size) else { return false }
        gtk_button_set_child(widget.of(GtkButton.self), image)
        gtk_widget_add_css_class(widget, "image-button")
        gtk_widget_set_tooltip_text(widget, caption)

        var property = GTK_ACCESSIBLE_PROPERTY_LABEL
        var name = GValue()
        g_value_init(&name, g_type_from_name("gchararray"))
        g_value_set_string(&name, caption)
        gtk_accessible_update_property_value(widget.opaque, 1, &property, &name)
        g_value_unset(&name)
        return true
    }

    /// The caption the button shows now, read back from GTK.
    var text: String {
        gtk_button_get_label(widget.of(GtkButton.self)).map { String(cString: $0) } ?? ""
    }

    /// The staying-pressed look, or none: `nil` for a momentary button - a
    /// widget made with `toggles` is required, or the cast below fails.
    func setOn(_ on: Bool?) {
        toggleable = on != nil
        gtk_toggle_button_set_active(widget.of(GtkToggleButton.self), (on ?? false) ? 1 : 0)
    }

    override func clicked() {
        onClicked?()
        // Only a widget made with `toggles` answers the toggle calls.
        guard g_type_check_instance_is_a(widget.of(GTypeInstance.self), gtk_toggle_button_get_type()) != 0
        else { return }
        if toggleable {
            onToggled?(gtk_toggle_button_get_active(widget.of(GtkToggleButton.self)) != 0)
        } else {
            // A momentary button must not keep the toggle's pressed look.
            gtk_toggle_button_set_active(widget.of(GtkToggleButton.self), 0)
        }
    }

    override func detach() {
        super.detach()
        onClicked = nil
        onToggled = nil
    }
}
