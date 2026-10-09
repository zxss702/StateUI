// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI

/// Edge preferences for automatic stack gaps. Desktop values approximate SwiftUI.
@_spi(Host) public struct LayoutSpacing: Equatable, Sendable {
    private enum Kind: Equatable, Sendable { case other, text, toggle, empty }
    private struct Preference: Equatable, Sendable {
        var kind: Kind = .other
        var scale = 1.0
        var textGap = 0.0
    }
    private var top = [Preference()], bottom = [Preference()]
    private var leading = [Preference()], trailing = [Preference()]
    public init() {}

    mutating func formUnion(_ other: Self, edges: Edge.Set = .all) {
        if edges.contains(.top) { top = Self.merged(top, other.top) }
        if edges.contains(.bottom) { bottom = Self.merged(bottom, other.bottom) }
        if edges.contains(.leading) { leading = Self.merged(leading, other.leading) }
        if edges.contains(.trailing) { trailing = Self.merged(trailing, other.trailing) }
    }

    private static func merged(_ first: [Preference], _ second: [Preference]) -> [Preference] {
        first + second.filter { !first.contains($0) }
    }

    mutating func pad(_ insets: EdgeInsets) {
        if insets.top != 0 { top = [Preference()] }
        if insets.bottom != 0 { bottom = [Preference()] }
        if insets.left != 0 { leading = [Preference()] }
        if insets.right != 0 { trailing = [Preference()] }
    }

    static func text(size: Double) -> Self {
        var result = Self()
        let pointSize = size.isFinite ? max(0, size) : 13
        let edge = Preference(kind: .text, scale: pointSize / 13,
                              textGap: max(0, pointSize - 13) * 1.5 / 13)
        result.top = [edge]; result.bottom = [edge]
        return result
    }

    private static func uniform(_ kind: Kind) -> Self {
        var result = Self()
        result.top = [Preference(kind: kind)]; result.bottom = result.top
        result.leading = result.top; result.trailing = result.top
        return result
    }
    static let toggle = uniform(.toggle)
    static let zero = uniform(.empty)

    public func distance(to next: Self, along axis: StackArithmetic.Axis) -> Double {
        let before = axis == .vertical ? bottom : trailing
        let after = axis == .vertical ? next.top : next.leading
        return before.flatMap { first in after.map { second in
            if first.kind == .empty || second.kind == .empty { return 0.0 }
            guard axis == .vertical else { return 8.0 }
            if first.kind == .text && second.kind == .text { return max(first.textGap, second.textGap) }
            if first.kind == .text { return 8.2 * first.scale }
            if second.kind == .text { return 4.7 * second.scale }
            return first.kind == .toggle && second.kind == .toggle ? 6.0 : 8.0
        } }.max() ?? 0
    }
}
