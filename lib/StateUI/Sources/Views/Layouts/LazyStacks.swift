// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A `VStack` under the SwiftUI name for one inside a scroller.
///
///     ScrollView {
///         LazyVStack(spacing: 12) { … }
///     }
///
/// SwiftUI's is lazy: it makes a row when the row scrolls into view. This
/// library's stacks lay their children out as they are described, so a lazy
/// column is the column itself - the name is kept so SwiftUI-shaped code
/// reads as it means, and rows that truly want recycling belong in a `List`.
public struct LazyVStack: View {
    /// The column it describes.
    private let held: () -> any View

    /// The same inits `VStack` answers.
    public init(@ViewBuilder content: @escaping () -> any View) {
        held = { VStack(content: content) }
    }

    /// A lazy column whose children stand at `alignment` across its width.
    public init(alignment: HorizontalAlignment, @ViewBuilder content: @escaping () -> any View) {
        held = { VStack(alignment: alignment, content: content) }
    }

    /// The same, with the stack's own spacing.
    public init(alignment: HorizontalAlignment, spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        held = { VStack(alignment: alignment, spacing: spacing, content: content) }
    }

    /// The same, with spacing and no alignment - centered, as SwiftUI's is.
    public init(spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        held = { VStack(alignment: .center, spacing: spacing, content: content) }
    }

    /// The column.
    public var body: some View { AnyView(held()) }
}

/// An `HStack` under the SwiftUI name for one inside a scroller.
///
///     ScrollView(.horizontal) {
///         LazyHStack(spacing: 12) { … }
///     }
public struct LazyHStack: View {
    /// The row it describes.
    private let held: () -> any View

    /// The same inits `HStack` answers.
    public init(@ViewBuilder content: @escaping () -> any View) {
        held = { HStack(content: content) }
    }

    /// A lazy row whose children stand at `alignment` down its height.
    public init(alignment: VerticalAlignment, @ViewBuilder content: @escaping () -> any View) {
        held = { HStack(alignment: alignment, content: content) }
    }

    /// The same, with the stack's own spacing.
    public init(alignment: VerticalAlignment, spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        held = { HStack(alignment: alignment, spacing: spacing, content: content) }
    }

    /// The same, with spacing and no alignment - centered, as SwiftUI's is.
    public init(spacing: Double?, @ViewBuilder content: @escaping () -> any View) {
        held = { HStack(alignment: .center, spacing: spacing, content: content) }
    }

    /// The row.
    public var body: some View { AnyView(held()) }
}
