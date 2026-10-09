// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI

extension MountedElement {
    /// The preferred gaps at the edges this element exposes to its parent.
    public var layoutSpacing: LayoutSpacing {
        if type == .text { return .text(size: spacingFontSize) }
        if type == .checkBox || type == .switch || type == .radioButton { return .toggle }
        switch type {
        case .hStack, .vStack, .lazyHStack, .lazyVStack, .zStack, .grid, .gridRow, .masked:
            var result = containerSpacing
            result.pad(insets(.contentPadding))
            return result
        default: break
        }
        return LayoutSpacing()
    }

    private var spacingChildren: [MountedElement] {
        currentChildren.filter { $0.standsShown && $0.bool(.isLayoutDecoration) != true }
    }

    private var containerSpacing: LayoutSpacing {
        let preferences = spacingChildren.map(\.layoutSpacing)
        guard let first = preferences.first, let last = preferences.last else { return .zero }
        let vertical = type == .vStack || type == .lazyVStack
        let horizontal = type == .hStack || type == .lazyHStack || type == .gridRow
        var result = LayoutSpacing.zero
        let cross: Edge.Set = vertical ? .horizontal : horizontal ? .vertical : .all
        for preference in preferences { result.formUnion(preference, edges: cross) }
        if vertical || horizontal {
            result.formUnion(first, edges: vertical ? .top : .leading)
            result.formUnion(last, edges: vertical ? .bottom : .trailing)
        }
        return result
    }

    private var spacingFontSize: Double {
        if let size = textLook.size { return size }
        switch textLook.textStyle ?? .body {
        case .largeTitle: return 26
        case .title: return 22
        case .title2: return 17
        case .title3: return 15
        case .headline, .body: return 13
        case .subheadline, .callout: return 12
        case .footnote: return 11
        case .caption, .caption2: return 10
        }
    }
}
