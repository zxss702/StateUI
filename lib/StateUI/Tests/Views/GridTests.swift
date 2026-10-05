// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import StateUI

/// A `LazyVGrid`'s columns, and a `Grid`'s `GridRow`s, as the nodes the differ sees.
final class GridTests: XCTestCase {
    /// A lazy grid is a `Grid` node carrying its column items, its spacing the
    /// row gap and the first column's own gap.
    func testALazyGridCarriesItsColumnsAndSpacing() throws {
        let columns = [
            GridItem(.flexible(minimum: 128, maximum: 764), spacing: 12, alignment: .leading),
            GridItem(.adaptive(minimum: 128, maximum: 764)),
        ]
        let grid = LazyVGrid(columns: columns, spacing: 12) {
            Text("a"); Text("b"); Text("c")
        }

        XCTAssertEqual(grid.node.type, GridContract.nodeType)
        XCTAssertEqual(grid.node.props["flowColumns"], columns.propValue)
        XCTAssertEqual(grid.node.props["rowSpacing"], .number(12))
        XCTAssertEqual(grid.node.props["columnSpacing"], .number(12))
    }

    /// Each cell in a lazy grid stands in the column its place names, aligned
    /// as that column says - horizontally only, where the row's height is the
    /// column's business.
    func testALazyGridsCellsWearTheirColumnsAlignment() throws {
        let grid = LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.fixed(80), alignment: .topTrailing),
            ]
        ) {
            Text("a"); Text("b"); Text("c")
        }
        let cells = grid.node.built.children

        XCTAssertEqual(cells.count, 3)
        XCTAssertEqual(cells[0].props["horizontalAlignment"], AxisAlignment.start.propValue)
        XCTAssertEqual(cells[0].props["verticalAlignment"], AxisAlignment.center.propValue)
        XCTAssertEqual(cells[1].props["horizontalAlignment"], AxisAlignment.end.propValue)
        XCTAssertEqual(cells[1].props["verticalAlignment"], AxisAlignment.start.propValue)
        XCTAssertEqual(cells[2].props["horizontalAlignment"], AxisAlignment.start.propValue,
                       "the third cell wraps to the first column's alignment")
    }

    /// A `Grid` of `GridRow`s lays each row's children one to a column, a bare
    /// child a row of its own spanning the columns the rows make.
    func testAGridOfRowsStampsEachCellItsPlace() throws {
        let grid = Grid(horizontalSpacing: 4, verticalSpacing: 8) {
            GridRow { Text("a"); Text("b") }
            Text("wide")
        }
        let cells = grid.node.built.children

        XCTAssertEqual(grid.node.props["columnSpacing"], .number(4))
        XCTAssertEqual(grid.node.props["rowSpacing"], .number(8))
        XCTAssertEqual(cells.count, 3)
        XCTAssertEqual(cells.map { $0.props["gridRow"] }, [.number(0), .number(0), .number(1)])
        XCTAssertEqual(cells.map { $0.props["gridColumn"] }, [.number(0), .number(1), .number(0)])
        XCTAssertNil(cells[0].props["gridColumnSpan"])
        XCTAssertEqual(cells[2].props["gridColumnSpan"], .number(2),
                       "a bare child spans the columns the rows make")
    }

    /// A row's and the grid's alignments settle where a cell sits: the row's
    /// down axis, the grid's across.
    func testAGridAlignsEachCellAsItsRowAndGridSay() throws {
        let grid = Grid(alignment: .topLeading) {
            GridRow(alignment: .bottom) { Text("a") }
            GridRow { Text("b") }
        }
        let cells = grid.node.built.children

        XCTAssertEqual(cells[0].props["horizontalAlignment"], AxisAlignment.start.propValue)
        XCTAssertEqual(cells[0].props["verticalAlignment"], AxisAlignment.end.propValue,
                       "the row's own alignment wins over the grid's")
        XCTAssertEqual(cells[1].props["verticalAlignment"], AxisAlignment.start.propValue,
                       "the grid's alignment where the row does not say")
    }
}
