// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// What assistive technology meets.
extension AppKitElement {
    /// Applies SwiftOmniUI's semantic surface without replacing the native
    /// control's ordinary role or participation when the author says nothing.
    func applyAccessibility(to view: NSView) {
        let target = accessibilityTarget(of: view)
        if accessibilityDefaults == nil {
            accessibilityDefaults = (
                isElement: target.isAccessibilityElement(),
                role: target.accessibilityRole())
        }
        guard let defaults = accessibilityDefaults else { return }

        target.setAccessibilityIdentifier(string(.accessibilityIdentifier))
        target.setAccessibilityLabel(string(.accessibilityLabel))
        target.setAccessibilityHelp(string(.accessibilityHint))

        let excludesChildren = value(.automationExcludedWithChildren)?.bool == true
        let childBehavior = enumeration(.accessibilityChildBehavior)
        let suppressChildren = excludesChildren
            || childBehavior == AccessibilityChildBehavior.ignore.rawValue
            || childBehavior == AccessibilityChildBehavior.combine.rawValue
        if suppressChildren {
            view.setAccessibilityChildren([])
            accessibilityChildrenSuppressed = true
        } else if accessibilityChildrenSuppressed {
            view.setAccessibilityChildren(nil)
            accessibilityChildrenSuppressed = false
        }

        let traits = AccessibilityTraits(rawValue: enumeration(.accessibilityTraits) ?? 0)
        target.setAccessibilitySelected(traits.contains(.isSelected))

        let headingLevel = max(0, enumeration(.accessibilityHeadingLevel) ?? 0)
        let carriesSemantics = string(.accessibilityLabel) != nil
            || string(.accessibilityHint) != nil
            || headingLevel > 0
            || !traits.isEmpty
        // An element that answers a tap is a button to assistive technology,
        // pressed by the handler a click runs. See `AppKitHitTestView`.
        let pressable = events[.tapGesture] != nil && view is AppKitHitTestView
        // The author says whether the view is hidden; an element is the opposite.
        let authoredElement = value(.isAccessibilityHidden)?.bool.map { !$0 }
        target.setAccessibilityElement(
            excludesChildren
                ? false
                : (authoredElement ?? (carriesSemantics || pressable ? true : defaults.isElement)))

        if headingLevel > 0 || traits.contains(.isHeader) {
            target.setAccessibilityRole(NSAccessibility.Role(rawValue: "AXHeading"))
        } else if traits.contains(.isLink) {
            target.setAccessibilityRole(.link)
        } else if traits.contains(.isButton) || pressable {
            target.setAccessibilityRole(.button)
        } else if traits.contains(.isToggle) {
            target.setAccessibilityRole(.checkBox)
        } else if traits.contains(.isSearchField) {
            target.setAccessibilityRole(NSAccessibility.Role(rawValue: "AXSearchField"))
        } else if traits.contains(.isImage) {
            target.setAccessibilityRole(.image)
        } else if traits.contains(.isStaticText) {
            target.setAccessibilityRole(.staticText)
        } else {
            target.setAccessibilityRole(defaults.role)
        }
    }

    /// The object assistive technology meets for `view`: the native control a
    /// wrapping view presents in its place (`AppKitAccessibilityPresenting`),
    /// or the view itself - and for a control AppKit presents through its
    /// cell, a button, a slider or a stepper, that cell. The cell is the
    /// element there and the view is not, so words written on the view would
    /// reach nobody, and making the view the element would hide the control's
    /// own role. Whether it is the cell is decided once, before any authored
    /// word moves it; the control is looked up each time, because a wrapper
    /// may replace it - a text field becoming a password field.
    func accessibilityTarget(of view: NSView) -> NSAccessibilityProtocol {
        let control = (view as? AppKitAccessibilityPresenting)?.presentedControl ?? view
        let cell = (control as? NSControl)?.cell
        if accessibilityThroughCell == nil {
            accessibilityThroughCell = cell?.isAccessibilityElement() == true
        }
        if accessibilityThroughCell == true, let cell {
            return cell
        }
        return control
    }
}
#endif
