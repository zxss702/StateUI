// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

extension AppKitRegistrations {
    /// The control a user presses: a caption, an icon beside it, and the
    /// three moments of a press.
    ///
    /// The icon is a file NAME, resolved through the picture the host gave the
    /// view, exactly as an `Image`'s is. What is NOT here is the room the
    /// caption is given: a button's padding becomes a size constraint over the
    /// native cell's own measurement, which is the host's arithmetic and not a
    /// value written onto a control.
    static func buttons(_ registry: Registry<NSView>) {
        registry.add(ButtonContract.self, create: { reports in
            let button = AppKitButtonView()
            button.onClicked = { reports.raise(ButtonContract.clicked) }
            button.onPressed = { reports.raise(ButtonContract.pressed) }
            button.onReleased = { reports.raise(ButtonContract.released) }
            button.onToggled = { on in
                reports.report(ButtonContract.isOn, on, as: ButtonContract.toggled)
            }
            return button
        }, members: { button in
            button.applies([
                TextElementContract.text, TextElementContract.textCase, ButtonContract.icon,
                ButtonContract.iconPosition,
                ImageElementContract.aspect, ButtonContract.lineBreak,
                TextStyleElementContract.foregroundStyle, VisualElementContract.background,
                BorderElementContract.shape, BorderElementContract.stroke,
                BorderElementContract.strokeWidth, VisualElementContract.isEnabled,
                FontElementContract.fontFamily, FontElementContract.fontSize,
                FontElementContract.fontAttributes, FontElementContract.fontTextStyle, FontElementContract.fontWeight,
                FontElementContract.fontDesign,
                ButtonContract.buttonStyle, ButtonContract.isOn,
            ]) { view, values in
                // Each value is read into a name of its own: twelve arguments
                // of `flatMap` and `??` in one call is more than the type
                // checker will take.
                let caption = (values[TextElementContract.textCase] ?? .none)
                    .applied(to: values[TextElementContract.text] ?? "")
                let icon: NSImage? = values[ButtonContract.icon]
                    .flatMap { $0.isEmpty ? nil : view.picture?($0.file) }
                let position: NSControl.ImagePosition = caption.isEmpty
                    ? .imageOnly
                    : Self.imagePosition(values[ButtonContract.iconPosition] ?? .leading)
                let scaling: NSImageScaling = Self.imageScaling(
                    values[ImageElementContract.aspect] ?? .fit)
                let foregroundStyle: NSColor = values[TextStyleElementContract.foregroundStyle]
                    .flatMap { nsColor($0.propValue) } ?? .controlTextColor
                let background: NSColor? = values[VisualElementContract.background]
                    .flatMap { nsColor($0.propValue) }
                let stroke = values[BorderElementContract.stroke]?.propValue
                let strokeWidth = BoxArithmetic.outlineWidth(
                    stroke: stroke, width: values[BorderElementContract.strokeWidth])
                let strokeColor = strokeWidth > 0 ? AppKitBrush(stroke).lineColor : nil
                let breaking = NSLineBreakMode(values[ButtonContract.lineBreak] ?? .wordWrap)
                let style: ButtonStyleKind = values[ButtonContract.buttonStyle] ?? .automatic

                view.apply(
                    text: caption,
                    image: icon,
                    imagePosition: position,
                    imageScaling: scaling,
                    font: Self.font(values),
                    foregroundStyle: foregroundStyle,
                    backgroundColor: background,
                    strokeColor: strokeColor,
                    strokeWidth: strokeWidth,
                    shape: BoxArithmetic.outline(values[BorderElementContract.shape]?.propValue),
                    lineBreakMode: breaking,
                    style: style,
                    enabled: values[VisualElementContract.isEnabled] ?? true)
                // A button wearing `isOn` at all is a staying-pressed one.
                let isOn: Bool? = values[ButtonContract.isOn]
                view.apply(toggleable: isOn != nil, on: isOn ?? false)
            }
            button.property(ButtonContract.shortcut) { view, shortcut in
                view.keyEquivalent = shortcut.map(Self.keyEquivalent) ?? ""
                view.keyEquivalentModifierMask = shortcut.map(Self.modifierFlags) ?? []
            }
            button.raises(ButtonContract.clicked)
            button.raises(ButtonContract.pressed)
            button.raises(ButtonContract.released)
            button.raises(ButtonContract.toggled)
        })
    }

    /// The key equivalent a named key stands for: its character, or the
    /// unicode the key is known by where a character cannot write it.
    private static func keyEquivalent(_ shortcut: KeyboardShortcut) -> String {
        switch shortcut.key.name {
        case "return": return "\r"
        case "escape": return "\u{1b}"
        case "tab": return "\t"
        case "space": return " "
        case "delete": return "\u{8}"
        case "deleteforward": return "\u{7f}"
        case "up": return "\u{f700}"
        case "down": return "\u{f701}"
        case "left": return "\u{f702}"
        case "right": return "\u{f703}"
        case "home": return "\u{f729}"
        case "end": return "\u{f72b}"
        case "pageup": return "\u{f72c}"
        case "pagedown": return "\u{f72d}"
        case let name where name.hasPrefix("f"):
            return Int(name.dropFirst()).flatMap { UnicodeScalar(0xf704 + $0 - 1) }.map(String.init)
                ?? shortcut.key.name
        default: return shortcut.key.name
        }
    }

    /// The modifier mask the shortcut's bits stand for.
    private static func modifierFlags(_ shortcut: KeyboardShortcut) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if shortcut.modifiers.contains(.command) { flags.insert(.command) }
        if shortcut.modifiers.contains(.shift) { flags.insert(.shift) }
        if shortcut.modifiers.contains(.option) { flags.insert(.option) }
        if shortcut.modifiers.contains(.control) { flags.insert(.control) }
        return flags
    }

    /// Where an icon sits beside its caption.
    private static func imagePosition(_ position: IconPosition) -> NSControl.ImagePosition {
        switch position {
        case .top: .imageAbove
        case .trailing: .imageTrailing
        case .bottom: .imageBelow
        case .leading: .imageLeading
        }
    }

    /// How an icon fills the room it is given.
    ///
    /// `.fit` and `.fill` come out the same: a native button has no covering
    /// scale, which is what this host's declaration says about `aspect` on a
    /// button.
    private static func imageScaling(_ aspect: ContentMode) -> NSImageScaling {
        switch aspect {
        case .stretch: .scaleAxesIndependently
        case .center: .scaleNone
        case .fit, .fill: .scaleProportionallyUpOrDown
        }
    }
}

#endif
