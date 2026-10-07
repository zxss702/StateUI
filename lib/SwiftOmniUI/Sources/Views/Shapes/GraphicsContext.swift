// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The drawing surface `Canvas`'s closure form is handed, as SwiftUI writes it:
// the calls gather into the canvas's `drawable` drawing, which a host replays
// on its own canvas - the same records `Draw` writes.

/// What a `Canvas`'s drawing closure draws on.
///
///     Canvas { context, size in
///         context.fill(
///             Path(roundedRect: Rect(0, 0, size.width, 40), cornerRadius: 8),
///             with: .color(.cornflowerBlue))
///         context.stroke(
///             Path { path in
///                 path.move(to: Point(x: 0, y: 0))
///                 path.addLine(to: Point(x: size.width, y: size.height))
///             },
///             with: .color(.steelBlue),
///             style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
///     }
///
/// The calls gather into a drawing - the same records `Draw` writes - and the
/// closure runs again as the canvas's size settles, so what depends on `size`
/// is drawn at the size it lands.
public struct GraphicsContext: Sendable {
    /// The instructions gathered so far, in drawing order.
    var commands: [DrawCommand] = []

    /// What a fill or a stroke is drawn with.
    public enum Shading: Sendable {
        /// One colour.
        case color(Color)

        /// The colour, where the shading is one.
        var color: Color? {
            if case .color(let color) = self { return color }
            return nil
        }
    }
}

extension GraphicsContext {
    /// Fills `path` in the shading's colour, `style`'s rule deciding which
    /// points are inside.
    public mutating func fill(_ path: Path, with shading: Shading, style: FillStyle) {
        guard let color = shading.color else { return }
        commands += [
            Draw.fillColor(color),
            Draw.fillStyle(eoFill: style.isEOFilled),
            Draw.fillPath(path.svg),
        ]
    }

    /// Fills `path` in the shading's colour, by the winding rule.
    public mutating func fill(_ path: Path, with shading: Shading) {
        fill(path, with: shading, style: FillStyle())
    }

    /// Outlines `path` in the shading's colour, as `style` finishes it.
    public mutating func stroke(_ path: Path, with shading: Shading, style: StrokeStyle) {
        guard let color = shading.color else { return }
        commands += [
            Draw.strokeColor(color),
            Draw.strokeStyle(width: style.lineWidth, cap: style.lineCap, join: style.lineJoin),
            Draw.drawPath(path.svg),
        ]
    }

    /// Outlines `path` in the shading's colour, `lineWidth` wide.
    public mutating func stroke(_ path: Path, with shading: Shading, lineWidth: Double) {
        stroke(path, with: shading, style: StrokeStyle(lineWidth: lineWidth))
    }
}
