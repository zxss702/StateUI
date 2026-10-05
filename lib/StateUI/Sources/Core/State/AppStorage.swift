// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `@AppStorage`: a `@State` the platform's store keeps under a name.
// Design: docs/design/core/state.md#kept-state

/// State kept in the application's store: the value outlives the process under
/// the key's name.
///
///     @AppStorage("showMinimap") var showMinimap = true
///
/// `Bool`, `Int`, `Double` and `String` are what a platform's store holds; an
/// enum is kept as its raw value. The value written here is what the state
/// holds when the store has nothing under the name; a write lands in the store
/// by itself, and the stored value is read before the first view is built.
@propertyWrapper
public struct AppStorage<Value: PersistentValue> {
    /// The kept state the name stands for.
    @State private var value: Value

    /// Declares a kept value under `key`.
    /// - Parameters:
    ///   - wrappedValue: what it holds when the store has nothing under the key.
    ///   - key: the name it is kept under.
    public init(wrappedValue: Value, _ key: String) {
        _value = State(wrappedValue: wrappedValue, persistentKey: PersistentKey(key, of: Value.self))
    }

    /// The kept value - read and written as any `@State`.
    public var wrappedValue: Value {
        get { value }
        nonmutating set { value = newValue }
    }

    /// What `$name` is: a binding to the kept value.
    public var projectedValue: Binding<Value> { $value }
}
