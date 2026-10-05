// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI

/// One entry a window's chrome holds for the arrangement it shows - an action, a spacer, or the view a
/// `ToolbarItem` carries.
@MainActor
struct WinUIToolbarAction {
    let title: String
    let isEnabled: Bool
    var identifier: String?
    /// The files its picture may stand in, in order (`PictureArithmetic.files`); none for words alone.
    var icon: [String] = []
    let perform: () -> Void
    var view: WinUIView?
    var spacer: ToolbarSpacerVariant?

    /// Whether two actions draw the same button. What an action performs is taken again on every composition.
    func draws(like other: WinUIToolbarAction) -> Bool {
        title == other.title && isEnabled == other.isEnabled && identifier == other.identifier && icon == other.icon
            && view === other.view && spacer == other.spacer
    }
}
