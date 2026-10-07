// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A key identifying a focused value - what a view declares so the value the
/// focused branch publishes is read under its own name:
///
///     struct RunActionKey: FocusedValueKey {
///         typealias Value = () -> Void
///     }
///
///     extension FocusedValues {
///         var runAction: (() -> Void)? {
///             get { self[RunActionKey.self] }
///             set { self[RunActionKey.self] = newValue }
///         }
///     }
public protocol FocusedValueKey {
    /// What the key reads and writes.
    associatedtype Value
}

/// The values the focused view and the scene around it publish, read by the
/// `FocusedValueKey` each names - the bag `@FocusedValue` reads and
/// `.focusedValue` writes under the SwiftUI spellings.
public struct FocusedValues {
    /// The published values, each by its key.
    private var values: [ObjectIdentifier: Any] = [:]

    /// An empty bag - nothing published.
    public init() {}

    /// What `key` publishes; nil where nothing wrote under it.
    public subscript<Key: FocusedValueKey>(key: Key.Type) -> Key.Value? {
        get { values[ObjectIdentifier(key)] as? Key.Value }
        set { values[ObjectIdentifier(key)] = newValue }
    }
}
