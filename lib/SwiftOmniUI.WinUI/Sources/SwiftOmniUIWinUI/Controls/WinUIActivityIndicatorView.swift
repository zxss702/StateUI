// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import CSwiftOmniUIWinUI

/// An ActivityIndicator: WinUI's `ProgressRing`, turning while its work runs.
@MainActor
final class WinUIActivityIndicatorView: WinUIView {
    init() {
        super.init { _ in swiftomniui_winui_progress_ring_make() }
    }

    /// Whether it turns.
    func setRunning(_ running: Bool) {
        swiftomniui_winui_progress_ring_set_running(handle, running)
    }

    /// Whether WinUI turns it.
    var isRunning: Bool { swiftomniui_winui_progress_ring_running(handle) }
}
