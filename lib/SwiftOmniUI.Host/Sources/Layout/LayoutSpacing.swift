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

    static func text(size: Double) -> Self {
        var result = Self()
        let pointSize = size.isFinite ? max(0, size) : 13
        let edge = Preference(kind: .text, scale: pointSize / 13,
                              textGap: max(0, pointSize - 13) * 1.5 / 13)
        result.top = [edge]; result.bottom = [edge]
        return result
    }

    static func uniform(_ kind: Kind) -> Self {
        var result = Self()
        result.top = [Preference(kind: kind)]; result.bottom = result.top
        result.leading = result.top; result.trailing = result.top
        return result
    }
}
