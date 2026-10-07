// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import GalleryUI
import SwiftOmniUIWeb

/// The gallery's own pushes, as this host raises them: the battery, as the browser tells the page's scripts.
enum GalleryEventSources {
    /// Declares what the host raises and wires its source. Said once, before the application runs.
    @MainActor
    static func start() {
        SwiftOmniUIEvents.raises(GalleryContract.batteryChanged)
        SwiftOmniUIScripts.hear("battery") { words in
            let (level, charging) = GalleryActs.battery(words)
            guard level > 0 else { return }
            SwiftOmniUIEvents.raise(GalleryContract.batteryChanged, level, charging)
        }
    }
}
