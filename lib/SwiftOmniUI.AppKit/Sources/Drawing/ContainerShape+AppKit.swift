// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import QuartzCore
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// A box's outline in AppKit's terms - the host layer's (`BoxArithmetic`): its path, and the cut of a layer to it.
/// Design: docs/design/host/layout.md#a-box
extension ContainerShape {
    /// The outline within `rect`, a corner no more than half the side it rounds.
    func path(in rect: NSRect) -> NSBezierPath {
        switch self {
        case .rectangle:
            return NSBezierPath(rect: rect)
        case .roundedRectangle(let radius):
            let fitted = BoxArithmetic.fitted(radius, width: rect.width, height: rect.height)
            return NSBezierPath(roundedRect: rect, xRadius: fitted.width, yRadius: fitted.height)
        case .unevenRoundedRectangle(let cornerRadius):
            return ContainerShape.unevenPath(in: rect, cornerRadius: cornerRadius)
        case .capsule:
            let half = min(rect.width, rect.height) / 2
            return NSBezierPath(roundedRect: rect, xRadius: half, yRadius: half)
        case .ellipse:
            return NSBezierPath(ovalIn: rect)
        case .circle:
            return NSBezierPath(ovalIn: ContainerShape.square(in: rect))
        }
    }

    /// Cuts `layer` to the outline: its corners where they round, a mask where it is an oval.
    func cut(_ layer: CALayer) {
        let bounds = layer.bounds
        switch self {
        case .rectangle:
            layer.cornerRadius = 0
            layer.mask = nil
        case .roundedRectangle(let radius):
            layer.cornerRadius = min(radius, min(bounds.width, bounds.height) / 2)
            layer.mask = nil
        case .unevenRoundedRectangle(let cornerRadius):
            layer.cornerRadius = 0
            let mask = layer.mask as? CAShapeLayer ?? CAShapeLayer()
            mask.frame = bounds
            mask.path = ContainerShape.unevenCGPath(in: bounds, cornerRadius: cornerRadius)
            layer.mask = mask
        case .capsule:
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
            layer.mask = nil
        case .ellipse, .circle:
            layer.cornerRadius = 0
            let mask = layer.mask as? CAShapeLayer ?? CAShapeLayer()
            mask.frame = bounds
            let oval = self == .ellipse ? bounds : ContainerShape.square(in: bounds)
            mask.path = CGPath(ellipseIn: oval, transform: nil)
            layer.mask = mask
        }
    }

    /// Rounds `layer`'s corners along the outline - an oval as a capsule, which is what a layer's corners draw.
    func round(_ layer: CALayer) {
        let bounds = layer.bounds
        switch self {
        case .unevenRoundedRectangle(let cornerRadius):
            layer.cornerRadius = 0
            let mask = layer.mask as? CAShapeLayer ?? CAShapeLayer()
            mask.frame = bounds
            mask.path = ContainerShape.unevenCGPath(in: bounds, cornerRadius: cornerRadius)
            layer.mask = mask
        default:
            layer.cornerRadius = switch self {
            case .rectangle: 0
            case .roundedRectangle(let radius): min(radius, min(bounds.width, bounds.height) / 2)
            case .ellipse, .capsule, .circle: min(bounds.width, bounds.height) / 2
            case .unevenRoundedRectangle: 0
            }
        }
    }

    /// A rectangle's outline whose corners round each by their own radius -
    /// top left, top right, bottom right, bottom left, no corner more than
    /// half the side it rounds.
    private static func unevenPath(in rect: NSRect, cornerRadius: CornerRadius) -> NSBezierPath {
        let radii: (Double, Double, Double, Double)
        switch cornerRadius {
        case .uniform(let radius): radii = (radius, radius, radius, radius)
        case .corners(let tl, let tr, let bl, let br): radii = (tl, tr, bl, br)
        }
        let bound = min(rect.width, rect.height) / 2
        let (tl, tr, bl, br) = (
            min(radii.0, bound), min(radii.1, bound), min(radii.2, bound), min(radii.3, bound))

        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + tl, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX - tr, y: rect.maxY))
        if tr > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.maxX - tr, y: rect.maxY - tr),
                radius: tr, startAngle: 90, endAngle: 0, clockwise: true)
        }
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY + br))
        if br > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.maxX - br, y: rect.minY + br),
                radius: br, startAngle: 0, endAngle: 270, clockwise: true)
        }
        path.line(to: NSPoint(x: rect.minX + bl, y: rect.minY))
        if bl > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.minX + bl, y: rect.minY + bl),
                radius: bl, startAngle: 270, endAngle: 180, clockwise: true)
        }
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - tl))
        if tl > 0 {
            path.appendArc(
                withCenter: NSPoint(x: rect.minX + tl, y: rect.maxY - tl),
                radius: tl, startAngle: 180, endAngle: 90, clockwise: true)
        }
        path.close()
        return path
    }

    /// `unevenPath` as a `CGPath`, for a shape-layer mask.
    private static func unevenCGPath(in rect: NSRect, cornerRadius: CornerRadius) -> CGPath {
        unevenPath(in: rect, cornerRadius: cornerRadius).cgPath
    }

    /// The square in the middle of `rect`, as wide as its shorter side.
    private static func square(in rect: NSRect) -> NSRect {
        let side = min(rect.width, rect.height)
        return NSRect(
            x: rect.minX + (rect.width - side) / 2,
            y: rect.minY + (rect.height - side) / 2,
            width: side,
            height: side)
    }
}

#endif
