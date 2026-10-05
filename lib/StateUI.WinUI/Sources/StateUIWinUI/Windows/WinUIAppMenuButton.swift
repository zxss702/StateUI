// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIWinUI

/// The scene's commands behind the button at the title bar's leading edge: a WinUI `Button` whose face is the
/// platform's navigation glyph, a press opening its `Flyout` - the placement groups' entries in it.
/// Design: docs/design/platforms/winui/pages.md#menus
@MainActor
final class WinUIAppMenuButton: WinUIView {
    /// The entries as they were last written.
    private(set) var shown = WinUIMenu()

    init() {
        super.init { number in stateui_winui_app_menu_make(number) }
    }

    /// The entries the press opens, the flyout written again only where what it draws changed.
    func show(_ menu: WinUIMenu) {
        menuActions = menu.actions
        guard !menu.draws(like: shown) else { return }

        shown = menu
        WinUIStrings.withCStrings(menu.titles) { titles in
            WinUIStrings.withCStrings(menu.identifiers) { identifiers in
                menu.kinds.withUnsafeBufferPointer { kinds in
                    menu.enabled.withUnsafeBufferPointer { enabled in
                        stateui_winui_menu_button_set_menu(
                            handle, number, kinds.baseAddress, titles, enabled.baseAddress, identifiers,
                            Int32(kinds.count))
                    }
                }
            }
        }
    }

    override func detach() {
        super.detach()
        shown = WinUIMenu()
    }
}
