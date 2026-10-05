// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIWinUI

/// A menu living in the view: a WinUI `Button` whose `Flyout` a press opens,
/// the label child its face, a chevron beside it the indicator shows or hides.
/// Design: docs/design/platforms/winui/pages.md#menus
@MainActor
final class WinUIMenuButtonView: WinUIView {
    /// The entries as they were last written.
    private(set) var shown = WinUIMenu()

    init() {
        super.init { number in stateui_winui_menu_button_make(number) }
    }

    /// The face the press opens the menu from: the label child's view; nil for the chevron alone.
    func setFace(_ face: WinUIView?) {
        stateui_winui_menu_button_set_face(handle, face?.handle)
    }

    /// Whether the face draws the chevron that says it opens a menu.
    func setIndicator(_ shown: Bool) {
        stateui_winui_menu_button_set_indicator(handle, shown ? 1 : 0)
    }

    /// Whether the trigger draws the platform's frameless look - `.borderlessButton`'s.
    func setBorderless(_ borderless: Bool) {
        stateui_winui_menu_button_set_borderless(handle, borderless ? 1 : 0)
    }

    /// Whether the press opens the menu.
    func setEnabled(_ enabled: Bool) {
        stateui_winui_set_enabled(handle, enabled)
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
