// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A grid that fills its columns with its children row first - SwiftUI's
/// `LazyVGrid`:
///
///     LazyVGrid(
///         columns: [
///             GridItem(.flexible(minimum: 128, maximum: 764), spacing: 12, alignment: .leading),
///             GridItem(.flexible(minimum: 128, maximum: 764), spacing: 12, alignment: .leading),
///         ],
///         spacing: 12
///     ) {
///         ForEach(entries) { entry in EntryCell(entry: entry) }
///     }
///
/// A `.fixed` column is that many points, a `.flexible` one a share of what
/// is left, and an `.adaptive` one stands for as many columns of at least
/// its minimum as the room fits - `Grid`'s cells, counted for it (Grid.swift).
public struct LazyVGrid<Content: View>: LayoutView, GridProperties {
    /// The node this grid describes.
    public var node: Node

    /// A grid filling `columns` with what the closure describes, row first,
    /// its cells centered across where a column does not say and as far from
    /// the next row as the next is used to.
    ///
    /// - Parameters:
    ///   - columns: the columns to fill; an `.adaptive` item stands for as
    ///     many as fit in the room the grid is given.
    ///   - content: the cells, in order.
    public init(columns: [GridItem], @ViewBuilder content: @escaping () -> Content) {
        self.init(columns: columns, alignment: .center, spacing: nil, content: content)
    }

    /// A grid filling `columns` with what the closure describes, row first.
    ///
    /// - Parameters:
    ///   - columns: the columns to fill; an `.adaptive` item stands for as
    ///     many as fit in the room the grid is given.
    ///   - alignment: where a cell's content sits across its column, where
    ///     the column's own alignment does not say.
    ///   - content: the cells, in order.
    public init(
        columns: [GridItem], alignment: HorizontalAlignment, @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(columns: columns, alignment: alignment, spacing: nil, content: content)
    }

    /// A grid filling `columns` with what the closure describes, row first,
    /// `spacing` from one row to the next.
    ///
    /// - Parameters:
    ///   - columns: the columns to fill; an `.adaptive` item stands for as
    ///     many as fit in the room the grid is given.
    ///   - spacing: the gap between two rows; a column's own `spacing` is the
    ///     gap after it.
    ///   - content: the cells, in order.
    public init(
        columns: [GridItem], spacing: Double?, @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(columns: columns, alignment: .center, spacing: spacing, content: content)
    }

    /// A grid filling `columns` with what the closure describes, row first.
    ///
    /// - Parameters:
    ///   - columns: the columns to fill; an `.adaptive` item stands for as
    ///     many as fit in the room the grid is given.
    ///   - alignment: where a cell's content sits across its column, where
    ///     the column's own alignment does not say.
    ///   - spacing: the gap between two rows; a column's own `spacing` is the
    ///     gap after it.
    ///   - content: the cells, in order.
    public init(
        columns: [GridItem],
        alignment: HorizontalAlignment,
        spacing: Double?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        node = Node(contract: GridContract.self)
        node.write(GridContract.flowColumns, columns)
        if let spacing { node.write(GridContract.rowSpacing, spacing) }
        if let columnSpacing = columns.lazy.compactMap(\.spacing).first {
            node.write(GridContract.columnSpacing, columnSpacing)
        }
        node.producer = {
            let count = max(columns.count, 1)
            return content().node.asChildren.enumerated().map { index, cell in
                var cell = cell
                let item = columns[index % count]
                let across = item.alignment?.horizontal.axis ?? alignment.axis
                if across != .fill { cell.write(ViewContract.horizontalAlignment, across) }
                if let down = item.alignment?.vertical.axis, down != .fill {
                    cell.write(ViewContract.verticalAlignment, down)
                }
                return cell
            }
        }
    }
}
