// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// Whatever an outline can be, written in SVG path syntax.
///
///     Path("M 0,40 L 20,0 L 40,40 Z")
///         .fill(.gold)
///         .aspect(.fit)
///
/// `M` moves, `L` draws a line, `C` a curve, `A` an arc and `Z` closes the
/// figure. The numbers are device units in the path's OWN space, and `.aspect`
/// says what happens to that space in the room the layout gives it - a path
/// drawn 40 wide fills a 200-wide cell under `.fit` and stays 40 under
/// `.center`.
///
/// Every platform accepts the same grammar: the host parses the path itself
/// before drawing it.
public struct Path: Shape, PathProperties {
    /// The node this control describes.
    public var node: Node

    /// A path with no outline yet - what a `Style<Path>` is written against.
    public init() {
        node = Node(contract: PathContract.self)
    }

    /// The outline, in SVG path syntax.
    public init(_ data: String) {
        node = Node(contract: PathContract.self)
        node.write(PathContract.data, data)
    }

    /// An outline written by the closure, the way SwiftUI builds one:
    ///
    ///     Path { path in
    ///         path.move(to: Point(x: 0, y: 0))
    ///         path.addCurve(to: Point(x: 40, y: 20),
    ///                       control1: Point(x: 0, y: 10), control2: Point(x: 40, y: 10))
    ///     }
    ///
    /// - Parameter callback: writes the outline on the empty path it is
    ///   handed, through `move`, `addLine`, `addCurve` and `closeSubpath`.
    public init(_ callback: (inout Path) -> Void) {
        self.init()
        callback(&self)
    }

    /// The ellipse `rect` holds, as `GraphicsContext` calls draw it.
    public init(ellipseIn rect: Rect) {
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2
        let centerX = rect.x + radiusX
        let centerY = rect.y + radiusY
        self.init(
            "M \(centerX),\(centerY - radiusY)"
                + " A \(radiusX),\(radiusY) 0 1 1 \(centerX),\(centerY + radiusY)"
                + " A \(radiusX),\(radiusY) 0 1 1 \(centerX),\(centerY - radiusY) Z")
    }

    /// `rect` with every corner rounded by `cornerRadius`.
    public init(roundedRect rect: Rect, cornerRadius: Double) {
        let radius = min(max(0, cornerRadius), min(rect.width, rect.height) / 2)
        let left = rect.x
        let top = rect.y
        let right = rect.x + rect.width
        let bottom = rect.y + rect.height
        self.init(
            "M \(left + radius),\(top)"
                + " L \(right - radius),\(top) A \(radius),\(radius) 0 0 1 \(right),\(top + radius)"
                + " L \(right),\(bottom - radius) A \(radius),\(radius) 0 0 1 \(right - radius),\(bottom)"
                + " L \(left + radius),\(bottom) A \(radius),\(radius) 0 0 1 \(left),\(bottom - radius)"
                + " L \(left),\(top + radius) A \(radius),\(radius) 0 0 1 \(left + radius),\(top) Z")
    }

    /// The outline as it stands, in the syntax the initializer takes - what a
    /// `GraphicsContext` call draws.
    var svg: String {
        node.props[PathContract.data.token]?.string ?? ""
    }

    /// Begins a new subpath at `point`, drawing nothing to it.
    public mutating func move(
        to point: Point
    ) {
        append("M \(point.x),\(point.y)")
    }

    /// Adds a straight segment from where the path stands to `point`.
    public mutating func addLine(to point: Point) {
        append("L \(point.x),\(point.y)")
    }

    /// Adds a cubic Bézier segment to `point`, bent by the two control points.
    public mutating func addCurve(to point: Point, control1: Point, control2: Point) {
        append("C \(control1.x),\(control1.y) \(control2.x),\(control2.y) \(point.x),\(point.y)")
    }

    /// Closes the current subpath with a straight segment back to where it
    /// began.
    public mutating func closeSubpath() {
        append("Z")
    }

    /// One more statement of the outline, past what it already says.
    private mutating func append(_ piece: String) {
        node.props[PathContract.data.token] = .string(svg.isEmpty ? piece : svg + " " + piece)
    }
}

/// `Path`'s own properties, shared by the control and its `Style<Path>`.
public protocol PathProperties: PropertyContainer {}

extension PathProperties {
    /// The outline, in SVG path syntax - `"M 0,40 L 20,0 L 40,40 Z"`.
    ///
    /// The same value the initializer takes; write it here to give a
    /// `Style<Path>` an outline, or to swap one on a path that already has
    /// modifiers on it.
    public func data(_ value: String) -> Modified { setValue(PathContract.data, value) }
}
