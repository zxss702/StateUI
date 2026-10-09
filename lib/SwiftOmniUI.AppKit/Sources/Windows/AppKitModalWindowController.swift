// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import Foundation
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// One native sheet in the modal arrangement owned by a SwiftOmniUI window.
@MainActor
final class AppKitModalWindowController: NSWindowController, NSWindowDelegate {
    /// The sheet's page, held by its mounted element, which owns its AppKit half.
    private var element: MountedElement
    var node: AppKitElement { element.appKit }
    private weak var stateUIOwner: AppKitWindowController?

    /// The sheet's first responder, watched for its owner.
    private var focusWatch: NSKeyValueObservation?

    init(node: AppKitElement, owner: AppKitWindowController) {
        element = node.element
        stateUIOwner = owner

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        // Tab and Shift-Tab go through the views as they stand on screen: AppKit works the loop out.
        window.autorecalculatesKeyViewLoop = true
        super.init(window: window)
        window.delegate = self
        focusWatch = window.observe(\.firstResponder) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.stateUIOwner?.focusMoved() }
        }
        synchronize(node)
    }

    required init?(coder: NSCoder) {
        nil
    }

    /// Whether the user may take the sheet away; `false` where the page says
    /// `interactiveDismissDisabled`.
    private var allowsUserDismissal = true

    func synchronize(_ node: AppKitElement) {
        element = node.element
        guard let window else { return }

        if let content = node.presentablePageView, window.contentView !== content {
            content.frame = NSRect(origin: .zero, size: window.contentLayoutRect.size)
            content.autoresizingMask = [.width, .height]
            window.contentView = content
        }
        let page = node.element.visiblePage
        window.title = page?.pageValue(.title)?.string ?? "SwiftOmniUI"
        allowsUserDismissal = !(page?.pageValue(.interactiveDismissDisabled)?.bool ?? false)
        window.standardWindowButton(.closeButton)?.isEnabled = allowsUserDismissal
        sizeForDetents(of: page, window)
    }

    /// A macOS sheet has no detents: the first one asked for becomes the
    /// sheet's height, measured against the parent.
    private func sizeForDetents(of page: MountedElement?, _ window: NSWindow) {
        guard let detents = page?.pageValue(.presentationDetents).flatMap({ [PresentationDetent](propValue: $0) }),
              let first = detents.first,
              let parent = window.sheetParent ?? window.parent ?? stateUIOwner?.window
        else { return }

        let room = parent.frame.height
        let height: CGFloat? = switch first {
        case .medium: room * 0.5
        case .large: nil
        case .fraction(let part): room * CGFloat(part)
        case .height(let points): CGFloat(points)
        }
        guard let height else { return }

        window.setContentSize(NSSize(width: window.contentLayoutRect.width, height: height))
    }

    func present(over parent: NSWindow, actuallyPresent: Bool) {
        guard actuallyPresent, let window, window.sheetParent == nil else { return }
        parent.beginSheet(window)
    }

    func dismiss(from parent: NSWindow) {
        guard let window else { return }
        window.delegate = nil
        if window.sheetParent != nil { parent.endSheet(window) }
        window.orderOut(nil)
        window.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard allowsUserDismissal else { return false }
        stateUIOwner?.userDismissed(self)
        return false
    }
}

#endif
