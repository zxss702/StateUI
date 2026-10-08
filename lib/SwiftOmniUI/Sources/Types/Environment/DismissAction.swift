// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// What dismisses the presentation a view stands in: a sheet's or popover's
/// own closer, a pushed navigation page's way back down the stack.
///
///     @Environment(\.dismiss) private var dismiss
///
///     Button("Done") { dismiss() }
///
/// Where nothing presented holds the view the call does nothing but say so -
/// a dismissed root has nowhere to go.
public struct DismissAction: Sendable {
    /// The closer the nearest presentation wired for itself.
    private let act: @Sendable @MainActor () -> Void

    /// An action that does its work when called.
    init(_ act: @escaping @Sendable @MainActor () -> Void) {
        self.act = act
    }

    /// Runs the dismissal.
    @MainActor public func callAsFunction() {
        act()
    }
}

/// `\.dismiss` reads a `DismissAction`.
struct DismissActionKey: EnvironmentKey {
    static let defaultValue = DismissAction {
        complain("@Environment(\\.dismiss) ran where nothing presented holds the view.")
    }
}

extension EnvironmentValues {
    /// The dismissal of the nearest presentation the view stands in.
    public var dismiss: DismissAction {
        get { self[DismissActionKey.self] }
        set { self[DismissActionKey.self] = newValue }
    }
}
