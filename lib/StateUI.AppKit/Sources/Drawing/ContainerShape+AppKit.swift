// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import QuartzCore
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

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
        layer.cornerRadius = switch self {
        case .rectangle: 0
        case .roundedRectangle(let radius): min(radius, min(bounds.width, bounds.height) / 2)
        case .ellipse, .capsule, .circle: min(bounds.width, bounds.height) / 2
        }
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
