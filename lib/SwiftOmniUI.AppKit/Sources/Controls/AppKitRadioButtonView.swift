// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// A native AppKit radio control. SwiftOmniUI's mounted tree owns group scope.
@MainActor
final class AppKitRadioButtonView: NSButton {
    var onSelected: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setButtonType(.radio)
        target = self
        action = #selector(selected(_:))
    }

    convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AppKitRadioButtonView is created in code")
    }

    func apply(
        checked: Bool,
        text: String,
        font: NSFont,
        foregroundStyle: NSColor,
        enabled: Bool
    ) {
        ProgramWrite.perform {
            state = checked ? .on : .off
            title = text
            self.font = font
            attributedTitle = NSAttributedString(
                string: text,
                attributes: [.font: font, .foregroundColor: foregroundStyle])
            isEnabled = enabled
        }
    }

    /// Only SwiftOmniUI turns a radio button: AppKit turns off every radio button of one superview and action as one of
    /// them is clicked, whatever set SwiftOmniUI puts each in, and that turn is refused. The click's own turn is its
    /// cell's, and stands.
    /// Design: docs/design/platforms/appkit/views.md#a-radio-buttons-set
    override var state: NSControl.StateValue {
        get { super.state }
        set {
            guard ProgramWrite.isWriting else { return }
            super.state = newValue
        }
    }

    func setCheckedFromGroup(_ checked: Bool) {
        ProgramWrite.perform {
            state = checked ? .on : .off
        }
    }

    @objc private func selected(_ sender: NSButton) {
        guard !ProgramWrite.isWriting, state == .on else { return }
        onSelected?()
    }

    func selectForTesting() {
        ProgramWrite.perform { state = .on }
        selected(self)
    }
}

#endif
