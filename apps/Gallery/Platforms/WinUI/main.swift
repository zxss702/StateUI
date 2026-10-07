// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import GalleryUI
import SwiftOmniUIWebViewWinUI
import SwiftOmniUIWinUI

// Register the application module, then say what this host answers for it before it runs: the controls it realizes,
// the acts it performs, and the pushes it reports - each in Host/ beside this file, the elements made by the gallery's
// relay in Relay/. Then hand WinUI this thread until the last window closes.
swiftomniui_app_register()
GalleryControls.register()
GalleryActs.register()
GalleryEventSources.start()
// The backends the Gallery shows a library element through: the web view, over WebView2.
SwiftOmniUIWebViewWinUI.register()
SwiftOmniUIWinUI.run()
