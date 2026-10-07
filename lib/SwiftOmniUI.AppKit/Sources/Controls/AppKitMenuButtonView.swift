// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// A menu that lives in the view: its label child shown as the trigger, a
/// click on it popping the menu its ContextMenu slot describes. A bordered
/// style draws a bezel and a chevron; `borderlessButton` shows the label
/// alone.
@MainActor
final class AppKitMenuButtonView: AppKitSingleChildView, NSMenuDelegate {
    /// Whether the button draws a bezel and chevron around its label.
    var showsChrome = true {
        didSet { if showsChrome != oldValue { needsDisplay = true; needsLayout = true } }
    }

    /// Whether the chevron at the label's side is drawn.
    var showsIndicator = true {
        didSet { if showsIndicator != oldValue { needsDisplay = true; needsLayout = true } }
    }

    /// Whether a click opens the menu.
    var opensMenu = true

    /// The entries the click pops, rebuilt as the slot's children walk by.
    var menuEntries: [NSMenuItem] = []

    private var pressed = false {
        didSet { if pressed != oldValue { needsDisplay = true } }
    }

    override var isFlipped: Bool { true }

    /// The chrome's part of the intrinsic size: the bezel's padding and the
    /// chevron's room.
    private var chromeWidth: Double { showsChrome ? (showsIndicator ? 26 : 14) : 0 }

    override func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        var size = super.fittingContentSize(
            width: availableWidth.map { max(0, $0 - chromeWidth) })
        if showsChrome {
            size.width += chromeWidth
            size.height = max(size.height + 8, 22)
        }
        return size
    }

    override func layout() {
        super.layout()
        if let item {
            var frame = item.view.frame
            if showsChrome {
                frame.origin.x += 7
                frame.size.width = max(0, frame.width - chromeWidth)
                item.view.frame = frame
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard opensMenu, !menuEntries.isEmpty else { return }
        pressed = true
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        for item in menuEntries { menu.addItem(item) }
        let origin = NSPoint(x: 0, y: bounds.height + 4)
        menu.popUp(positioning: nil, at: origin, in: self)
        pressed = false
    }

    override func draw(_ dirtyRect: NSRect) {
        guard showsChrome else { return }
        let bezel = bounds.insetBy(dx: 0.5, dy: 0.5)
        NSColor.controlBackgroundColor.withAlphaComponent(pressed ? 0.6 : 0.35).setFill()
        NSBezierPath(roundedRect: bezel, xRadius: 6, yRadius: 6).fill()
        NSColor.separatorColor.setStroke()
        NSBezierPath(roundedRect: bezel, xRadius: 6, yRadius: 6).stroke()

        guard showsIndicator else { return }
        let centre = NSPoint(x: bounds.maxX - 13, y: bounds.midY)
        let chevron = NSBezierPath()
        chevron.move(to: NSPoint(x: centre.x - 4, y: centre.y + 1.5))
        chevron.line(to: NSPoint(x: centre.x, y: centre.y - 2.5))
        chevron.line(to: NSPoint(x: centre.x + 4, y: centre.y + 1.5))
        chevron.lineWidth = 1.4
        NSColor.secondaryLabelColor.setStroke()
        chevron.stroke()
    }

    /// The menu closing lifts the pressed look whether the click opened it or
    /// the user looked and left.
    func menuDidClose(_ menu: NSMenu) {
        pressed = false
    }
}

#endif
