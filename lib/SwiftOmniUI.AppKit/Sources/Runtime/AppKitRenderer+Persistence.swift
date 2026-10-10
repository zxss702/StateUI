// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// Kept values in the preferences: read before the first render, each written as it changes, as the words every
/// host keeps a value by.
/// Design: docs/design/host/runtime.md#kept-values
extension AppKitRenderer {
    func hydratePersistentState() {
        // One pass reads what the application lists and the manifest; the
        // manifest names the keys a claimed state kept, read in the next.
        var read: Set<String> = []

        while true {
            let keys = runtime.core.persistentKeys.filter { read.insert($0.name).inserted }
            guard !keys.isEmpty else { return }

            let words = Dictionary(uniqueKeysWithValues: keys.compactMap { key in
                preferences.string(forKey: key.name).map { (key.name, $0) }
            })
            runtime.core.restorePersistent(KeptWord.restored(words, for: keys))
        }
    }

    func savePersistent(_ call: HostActCall) {
        guard let kept = KeptWord.kept(call.arguments, keys: runtime.core.persistentKeys) else { return }
        preferences.set(kept.word, forKey: kept.name)
    }
}
#endif
