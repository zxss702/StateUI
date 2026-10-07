// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// The AppKit host's answer to a `LocalizedStringKey`: the main bundle's
/// tables, the same file SwiftUI reads.
enum AppKitStrings {
    static func resolve(_ key: LocalizedStringKey) -> String? {
        let pattern = Bundle.main.localizedString(forKey: key.pattern, value: nil, table: nil)
        guard pattern != key.pattern else { return nil }
        return HostLocalizedStrings.format(pattern, arguments: key.arguments)
    }
}
#endif
