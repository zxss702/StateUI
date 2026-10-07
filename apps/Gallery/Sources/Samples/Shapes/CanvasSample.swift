@_spi(Host) import SwiftOmniUI

/// A canvas drawn from state, and one drawn from a finger.
struct CanvasSample: SampleContent {
    static let id = "canvas"
    static let title = "Canvas"
    static let summary = "A canvas: the drawing instructions travel, and the host draws them."

    // A drag is a gesture, and a scroller would claim it before the canvas
    // heard about it - see SampleContent.scrolls.
    static let scrolls = false

    var examples: [Example] {
        [Example(FollowsState()), Example(FollowsAFinger()), Example(Measured())]
    }
}

/// A drawing described from state, redrawn because the state changed and for
/// no other reason.
private struct FollowsState: ExampleContent {
    @State private var bars = [0.4, 0.75, 0.3, 0.95, 0.6]

    static let code = """
        struct FollowsState: View {
            @State private var bars = [0.4, 0.75, 0.3, 0.95, 0.6]

            var body: some View {
                VStack {
                    // The bars are read by the drawing below, so changing
                    // one builds this closure - which is what redraws it.
                    DebugInfoLabel()

                    Canvas {
                        for (index, value) in bars.enumerated() {
                            let height = value * 90
                            let x = Double(index) * 44

                            Draw.fillColor(Palette.accent)
                            Draw.fillRoundedRectangle(
                                x: x, y: 100 - height, width: 32, height: height,
                                cornerRadius: 4)

                            Draw.foregroundStyle(Palette.text)
                            Draw.fontSize(11)
                            Draw.drawText(
                                "\\(Int(value * 100))", x: x, y: 104, width: 32, height: 14,
                                horizontalAlignment: .center)
                        }
                    }
                    .frame(height: 120)

                    Button("Different numbers", action: { bars = bars.map { _ in Double.random(in: 0.15...1) } })
                        
                }
            }
        }
        """

    var body: some View {
        VStack {
            DebugInfoLabel()

            Canvas {
                for (index, value) in bars.enumerated() {
                    let height = value * 90
                    let x = Double(index) * 44

                    Draw.fillColor(Palette.accent)
                    Draw.fillRoundedRectangle(
                        x: x, y: 100 - height, width: 32, height: height, cornerRadius: 4)

                    Draw.foregroundStyle(Palette.text)
                    Draw.fontSize(11)
                    Draw.drawText(
                        "\(Int(value * 100))", x: x, y: 104, width: 32, height: 14,
                        horizontalAlignment: .center)
                }
            }
            .frame(height: 120)

            Button("Different numbers", action: { bars = bars.map { _ in Double.random(in: 0.15...1) } })
                .font(.system(size: 13))
                .contentPadding(EdgeInsets(16, 6))
                .horizontalAlignment(.center)
                
        }
        .spacing(12)
    }

    var notes: (any View)? {
        Text("The drawing is a list of instructions described in Swift. They travel to "
            + "the host, which draws them on the platform's canvas. The bars are read "
            + "inside the drawing, so new numbers draw it again.")
            .font(.system(size: 12))
            .foregroundStyle(Palette.subtle)
    }
}

/// The same canvas, drawn from what a finger is doing to it.
private struct FollowsAFinger: ExampleContent {
    @State private var trail: [Point] = []

    static let code = """
        struct FollowsAFinger: View {
            @State private var trail: [Point] = []

            // Where a finger went, drawn where it went: the canvas reports in
            // its own coordinates, which is what the instructions use.
            var body: some View {
                VStack {
                    // The trail is read by the drawing, so every report the
                    // finger makes builds this closure and draws again.
                    DebugInfoLabel()

                    Canvas {
                        Draw.strokeColor(Palette.outline)
                        Draw.strokeWidth(1)
                        Draw.drawRoundedRectangle(
                            x: 1, y: 1, width: 300, height: 118, cornerRadius: 8)

                        Draw.fillColor(Palette.accent)
                        for point in trail {
                            Draw.fillEllipse(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                        }
                    }
                    .frame(height: 120)
                    .onPressed { trail = [$0] }
                    .onDragged { trail = Array((trail + [$0]).suffix(120)) }
                    .onReleased { _ in }

                    Button("Clear", action: { trail = [] })
                        .disabled(trail.isEmpty)
                        
                }
            }
        }
        """

    var body: some View {
        VStack {
            DebugInfoLabel()

            Canvas {
                Draw.strokeColor(Palette.outline)
                Draw.strokeWidth(1)
                Draw.drawRoundedRectangle(x: 1, y: 1, width: 300, height: 118, cornerRadius: 8)

                Draw.fillColor(Palette.accent)
                for point in trail {
                    Draw.fillEllipse(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                }
            }
            .frame(height: 120)
            .onPressed { trail = [$0] }
            .onDragged { trail = Array((trail + [$0]).suffix(120)) }
            .onReleased { _ in }

            Button("Clear", action: { trail = [] })
                .font(.system(size: 13))
                .contentPadding(EdgeInsets(16, 6))
                .horizontalAlignment(.center)
                .disabled(trail.isEmpty)
                
        }
        .spacing(12)
    }

    var notes: (any View)? {
        Text("Every point the finger reports is a write: the trail changes, the "
            + "drawing is described again, and the new instructions travel.")
            .font(.system(size: 12))
            .foregroundStyle(Palette.subtle)
    }
}

/// The SwiftUI-shaped canvas: `Canvas(renderer:)` hands a `GraphicsContext`
/// and the settled size, `context.draw(Text)` writes words, and an aim's
/// `measureText` asks the host's text engine the room words will take.
private struct Measured: ExampleContent {
    @Aim(Canvas.self) private var ruler
    @State private var fitted: Size?

    static let code = """
        @Aim(Canvas.self) private var ruler
        @State private var fitted: Size?

        var body: some View {
            VStack {
                Canvas { context, size in
                    let words = "Snug"
                    let middle = Point(x: size.width / 2, y: 52)

                    // A Text goes in whole - its words, colour and size are
                    // the drawing's for that call.
                    context.draw(Text(words), at: middle)

                    if let fitted {
                        context.stroke(
                            Path(roundedRect: Rect(
                                x: middle.x - fitted.width / 2 - 8,
                                y: middle.y - fitted.height / 2 - 6,
                                width: fitted.width + 16,
                                height: fitted.height + 12),
                                cornerRadius: 6),
                            with: .color(Palette.accent), lineWidth: 1)
                    }
                }
                .frame(height: 104)
                .aim(ruler)
                .task {
                    // measureText is an act aimed at the canvas: async, and
                    // answered by the host's own text engine.
                    fitted = try? await ruler.measureText("Snug")
                }

                Text(fitted.map {
                    "measured \\(Int($0.width)) x \\(Int($0.height))" }
                    ?? "measuring...")
            }
        }
        """

    var body: some View {
        VStack {
            DebugInfoLabel()

            Canvas { context, size in
                let words = "Snug"
                let middle = Point(x: size.width / 2, y: 52)

                context.draw(Text(words), at: middle)

                if let fitted {
                    context.stroke(
                        Path(roundedRect: Rect(
                            x: middle.x - fitted.width / 2 - 8,
                            y: middle.y - fitted.height / 2 - 6,
                            width: fitted.width + 16,
                            height: fitted.height + 12),
                            cornerRadius: 6),
                        with: .color(Palette.accent), lineWidth: 1)
                }
            }
            .frame(height: 104)
            .aim(ruler)
            .task {
                fitted = try? await ruler.measureText("Snug")
            }

            Text(fitted.map { "measured \(Int($0.width)) x \(Int($0.height))" }
                ?? "measuring...")
                .font(.system(size: 13))
                .foregroundStyle(Palette.subtle)
                .horizontalAlignment(.center)
        }
        .spacing(12)
    }

    var notes: (any View)? {
        Text("`Canvas(renderer:)` is the SwiftUI shape of the same canvas: a "
            + "`GraphicsContext` gathering `fill`, `stroke` and `draw` calls, "
            + "and the settled `size` beside it. `measureText` is asked of the "
            + "canvas's aim - the answer is what the host's text engine gives "
            + "the words, which is why the box fits.")
            .font(.system(size: 12))
            .foregroundStyle(Palette.subtle)
    }
}
