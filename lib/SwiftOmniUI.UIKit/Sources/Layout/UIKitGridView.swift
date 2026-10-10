// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// A Grid: its children in rows and columns (`GridArithmetic`).
@MainActor
final class UIKitGridView: UIKitLayoutView {
    var rows: [GridLength] = [] {
        didSet { if rows != oldValue { invalidate() } }
    }

    var columns: [GridLength] = [] {
        didSet { if columns != oldValue { invalidate() } }
    }

    /// The room between two rows, and between two columns.
    var rowSpacing = 0.0 {
        didSet { if rowSpacing != oldValue { invalidate() } }
    }

    var columnSpacing = 0.0 {
        didSet { if columnSpacing != oldValue { invalidate() } }
    }

    /// A `LazyVGrid`'s columns: a flow fills them row first, an adaptive one
    /// as many times as the room fits.
    var flowColumns: [GridItem] = [] {
        didSet { if flowColumns != oldValue { invalidate() } }
    }

    /// The room inside the grid's own edge.
    var padding = EdgeInsets(0) {
        didSet { if padding != oldValue { invalidate() } }
    }

    /// Draws the shade a placed layout lays over its card - the grid's second child - `opacity` opaque.
    /// Design: docs/design/platforms/uikit/drawing.md#a-placed-child
    func setShadeOpacity(_ opacity: Double) {
        guard items.count > 1 else { return }
        items[1].drawing?.placedOpacity = min(max(opacity, 0), 1)
    }

    private func invalidate() {
        forgetMeasurements()
        setNeedsLayout()
    }

    override func contentSize(width: Double?) -> LayoutSize {
        GridArithmetic.size(
            of: items, rows: rows, columns: columns,
            rowSpacing: rowSpacing, columnSpacing: columnSpacing, padding: padding, width: width,
            flow: flowColumns)
    }

    override func arrange(in bounds: Rect) {
        let places = GridArithmetic.places(
            of: items, rows: rows, columns: columns,
            rowSpacing: rowSpacing, columnSpacing: columnSpacing, padding: padding, in: bounds,
            direction: direction, flow: flowColumns)
        for (item, place) in zip(items, places) {
            if let place { self.place(item, at: place) }
        }
    }
}
#endif
