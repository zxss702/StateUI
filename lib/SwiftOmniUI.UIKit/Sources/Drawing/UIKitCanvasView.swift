// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// A Canvas: its drawing replayed in order on Core Graphics - the instructions and the pen the host layer reads
/// (`CanvasInstruction`, `CanvasPen`), its arcs the host layer's curves - within its own bounds; a finger on it is
/// heard as it goes down, moves and lifts.
/// Design: docs/design/platforms/uikit/drawing.md#a-canvas
@MainActor
final class UIKitCanvasView: UIView {
    var onPressed: ((CGPoint) -> Void)?
    var onDragged: ((CGPoint) -> Void)?
    var onReleased: ((CGPoint) -> Void)?

    private var instructions: [CanvasInstruction] = []

    init() {
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = nil
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("UIKitCanvasView is made in code")
    }

    /// The drawing, as its contract declares it; none draws nothing.
    func apply(_ drawing: [DrawCommand]?) {
        instructions = CanvasInstruction.instructions(drawing)
        setNeedsDisplay()
    }

    /// A canvas asks for no room of its own.
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        .zero
    }

    /// The room `text` takes drawn in the font `look` names, measured by UIKit's own typesetter: wrapped at
    /// `maximumWidth` where one is given, each paragraph one line else - the `measureText` act's answer.
    func measureText(_ text: String, font look: TextLook, maximumWidth: Double?) -> Size {
        let bound = CGSize(
            width: maximumWidth ?? .greatestFiniteMagnitude,
            height: .greatestFiniteMagnitude)
        let measured = (text as NSString).boundingRect(
            with: bound, options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Self.font(for: look)], context: nil)
        return Size(width: measured.width, height: measured.height)
    }

    /// The font `look` names, resolved the way UIKit's own text draws it: a text style's preferred font where the
    /// look takes one - `size` over it where it also says one - else the family it names or the system font at its
    /// size, its weight where one is set, its letter shape and its bold and italic over all.
    private static func font(for look: TextLook) -> UIFont {
        var font: UIFont
        if let style = look.textStyle {
            font = UIFont.preferredFont(forTextStyle: uiTextStyle(style))
            if let size = look.size { font = font.withSize(size) }
        } else {
            let size = look.size ?? Double(UIFont.systemFontSize)
            if let weight = look.weight, look.family == nil {
                font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight(rawValue: weight / 100))
            } else {
                font = look.family.flatMap { UIFont(name: $0, size: size) }
                    ?? UIFont.systemFont(ofSize: size)
            }
        }
        if let design = look.design,
           let shaped = font.fontDescriptor.withDesign(uiFontDesign(design)) {
            font = UIFont(descriptor: shaped, size: font.pointSize)
        }
        var traits = font.fontDescriptor.symbolicTraits
        if look.attributes.contains(.bold) { traits.insert(.traitBold) }
        if look.attributes.contains(.italic) { traits.insert(.traitItalic) }
        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            font = UIFont(descriptor: descriptor, size: font.pointSize)
        }
        return font
    }

    /// A SwiftOmniUI text style as UIKit's own.
    private static func uiTextStyle(_ style: FontTextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        }
    }

    /// A SwiftOmniUI font design as UIKit's own.
    private static func uiFontDesign(_ design: FontDesign) -> UIFontDescriptor.SystemDesign {
        switch design {
        case .default: .default
        case .serif: .serif
        case .rounded: .rounded
        case .monospaced: .monospaced
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clip(to: bounds)
        var pen = CanvasPen()
        var saved = 0
        for instruction in instructions {
            if pen.take(instruction) {
                if instruction == .saveState {
                    context.saveGState()
                    saved += 1
                } else if instruction == .restoreState, saved > 0 {
                    context.restoreGState()
                    saved -= 1
                }
                continue
            }
            draw(instruction, pen: pen, in: context)
        }
        while saved > 0 {
            context.restoreGState()
            saved -= 1
        }
    }

    private func draw(_ instruction: CanvasInstruction, pen: CanvasPen, in context: CGContext) {
        switch instruction {
        case .drawLine(let from, let to):
            let path = CGMutablePath()
            path.move(to: CGPoint(x: from.x, y: from.y))
            path.addLine(to: CGPoint(x: to.x, y: to.y))
            stroke(path, pen, context)
        case .drawRectangle(let room): stroke(CGPath(rect: Self.rect(room), transform: nil), pen, context)
        case .drawRoundedRectangle(let room, let radius): stroke(Self.rounded(room, radius), pen, context)
        case .drawEllipse(let room): stroke(CGPath(ellipseIn: Self.rect(room), transform: nil), pen, context)
        case .drawArc(let room, let start, let end, let clockwise, let closed):
            stroke(UIKitShapeView.path(CanvasArithmetic.arc(
                in: room, start: start, end: end, clockwise: clockwise, closed: closed, wedge: false)), pen, context)
        case .drawPath(let curves): stroke(UIKitShapeView.path(curves), pen, context)
        case .fillRectangle(let room): fill(CGPath(rect: Self.rect(room), transform: nil), pen, context)
        case .fillRoundedRectangle(let room, let radius): fill(Self.rounded(room, radius), pen, context)
        case .fillEllipse(let room): fill(CGPath(ellipseIn: Self.rect(room), transform: nil), pen, context)
        case .fillArc(let room, let start, let end, let clockwise):
            fill(UIKitShapeView.path(CanvasArithmetic.arc(
                in: room, start: start, end: end, clockwise: clockwise, closed: true, wedge: true)), pen, context)
        case .fillPath(let curves): fill(UIKitShapeView.path(curves), pen, context)
        case .drawText(let text, let room, let across, let down): write(text, in: room, across, down, pen, context)
        case .translate(let x, let y): context.translateBy(x: x, y: y)
        case .rotate(let degrees): context.rotate(by: degrees * .pi / 180)
        case .scale(let x, let y): context.scaleBy(x: x, y: y)
        default: break
        }
    }

    private func stroke(_ path: CGPath, _ pen: CanvasPen, _ context: CGContext) {
        guard pen.strokeWidth > 0, let color = Self.color(pen.stroke, pen) else { return }
        context.addPath(path)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(pen.strokeWidth)
        let cap: CGLineCap = switch pen.strokeCap {
        case .round: .round
        case .square: .square
        default: .butt
        }
        let join: CGLineJoin = switch pen.strokeJoin {
        case .round: .round
        case .bevel: .bevel
        default: .miter
        }
        context.setLineCap(cap)
        context.setLineJoin(join)
        context.strokePath()
    }

    private func fill(_ path: CGPath, _ pen: CanvasPen, _ context: CGContext) {
        guard let color = Self.color(pen.fill, pen) else { return }
        context.addPath(path)
        context.setFillColor(color.cgColor)
        if pen.fillEvenOdd { context.fillPath(using: .evenOdd) } else { context.fillPath() }
    }

    /// Text in its box: placed by the box's two alignments - its top the box's - and cut to it.
    private func write(
        _ text: String, in room: Rect, _ across: TextAlignment, _ down: TextAlignment, _ pen: CanvasPen,
        _ context: CGContext
    ) {
        let box = Self.rect(room)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = switch across {
        case .start: .left
        case .center: .center
        case .end: .right
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: pen.fontSize ?? UIFont.systemFontSize),
            .foregroundColor: Self.color(pen.text, pen) ?? .black,
            .paragraphStyle: paragraph,
        ]
        let measured = (text as NSString).boundingRect(
            with: box.size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        let top: CGFloat = switch down {
        case .start: box.minY
        case .center: box.midY - measured.height / 2
        case .end: box.maxY - measured.height
        }
        context.saveGState()
        context.clip(to: box)
        (text as NSString).draw(
            in: CGRect(x: box.minX, y: top, width: box.width, height: measured.height), withAttributes: attributes)
        context.restoreGState()
    }

    private static func color(_ value: HostValue, _ pen: CanvasPen) -> UIColor? {
        guard let color = UIColor(stateUI: value) else { return nil }
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return color.withAlphaComponent(alpha * pen.alpha)
    }

    private static func rect(_ room: Rect) -> CGRect {
        CGRect(x: room.x, y: room.y, width: room.width, height: room.height)
    }

    private static func rounded(_ room: Rect, _ radius: Double) -> CGPath {
        let box = rect(room)
        let kept = min(max(0, radius), min(abs(box.width), abs(box.height)) / 2)
        return CGPath(roundedRect: box, cornerWidth: kept, cornerHeight: kept, transform: nil)
    }

    // MARK: - A finger on it

    func pressed(at point: CGPoint) { onPressed?(point) }
    func dragged(to point: CGPoint) { onDragged?(point) }
    func released(at point: CGPoint) { onReleased?(point) }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.first.map { pressed(at: $0.location(in: self)) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.first.map { dragged(to: $0.location(in: self)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.first.map { released(at: $0.location(in: self)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.first.map { released(at: $0.location(in: self)) }
    }
}
#endif
