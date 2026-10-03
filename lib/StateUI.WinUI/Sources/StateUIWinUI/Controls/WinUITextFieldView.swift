// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
import CStateUIWinUI

/// A TextField: a WinUI `TextBox` on one line, whose Enter submits.
@MainActor
final class WinUITextFieldView: WinUIInputView {
    init() {
        super.init { number in stateui_winui_field_make(number) }
    }

    /// The logical style, mapped to the box's own chrome.
    func setStyle(_ style: TextFieldStyleKind?) {
        stateui_winui_field_set_style(handle, (style ?? .automatic).rawValue)
    }
}
