// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

extension UIKitRegistrations {
    /// The stacks, the grid and the ZStack: the room a layout leaves around and between its children, the box it
    /// paints, and whether a touch beside its children goes on to what is under it.
    static func layouts(_ registry: Registry<UIView>) {
        registry.add(VStackContract.self, create: { _ in UIKitStackView(axis: .vertical) }) { stack in
            stack.applies(stackMembers) { view, values in applyStack(view, values) }
            stack.applies(boxMembers) { view, values in applyBox(view, values) }
            stack.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            stack.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            stack.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
        }

        registry.add(HStackContract.self, create: { _ in UIKitStackView(axis: .horizontal) }) { stack in
            stack.applies(stackMembers) { view, values in applyStack(view, values) }
            stack.applies(boxMembers) { view, values in applyBox(view, values) }
            stack.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            stack.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            stack.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
        }

        registry.add(GridContract.self, create: { _ in UIKitGridView() }) { grid in
            grid.applies([
                GridContract.rows, GridContract.columns,
                GridContract.rowSpacing, GridContract.columnSpacing,
                GridContract.flowColumns,
                PaddingElementContract.contentPadding,
            ]) { view, values in
                view.rows = values[GridContract.rows] ?? []
                view.columns = values[GridContract.columns] ?? []
                view.flowColumns = values[GridContract.flowColumns] ?? []
                view.rowSpacing = values[GridContract.rowSpacing] ?? 0
                view.columnSpacing = values[GridContract.columnSpacing] ?? 0
                view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
            }
            grid.applies(boxMembers) { view, values in applyBox(view, values) }
            grid.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            grid.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            grid.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
        }

        registry.add(LazyVStackContract.self, madeByHost: UIKitLazyStackView.self) { lazy in
            lazy.applies(stackMembers + [LazyVStackContract.items]) { view, values in
                view.spacing = values[StackBaseContract.spacing] ?? 0
                view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
                if view.cells.takeItems() { view.invalidateMeasurements() }
            }
            lazy.applies(boxMembers) { view, values in applyBox(view, values) }
            lazy.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            lazy.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            lazy.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
            lazy.raises(LazyVStackContract.realizedChanged)
        }

        registry.add(LazyHStackContract.self, madeByHost: UIKitLazyStackView.self) { lazy in
            lazy.applies(stackMembers + [LazyHStackContract.items]) { view, values in
                view.spacing = values[StackBaseContract.spacing] ?? 0
                view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
                if view.cells.takeItems() { view.invalidateMeasurements() }
            }
            lazy.applies(boxMembers) { view, values in applyBox(view, values) }
            lazy.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            lazy.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            lazy.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
            lazy.raises(LazyHStackContract.realizedChanged)
        }

        registry.add(LazyVGridContract.self, madeByHost: UIKitLazyGridView.self) { grid in
            grid.applies([
                LazyVGridContract.items, LazyVGridContract.flowColumns, LazyVGridContract.rowSpacing,
                LazyVGridContract.columnSpacing, PaddingElementContract.contentPadding,
            ]) { view, values in
                view.tracks = values[LazyVGridContract.flowColumns] ?? []
                view.runSpacing = values[LazyVGridContract.rowSpacing] ?? 0
                view.trackSpacing = values[LazyVGridContract.columnSpacing] ?? 0
                view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
                if view.cells.takeItems() { view.invalidateMeasurements() }
            }
            grid.applies(boxMembers) { view, values in applyBox(view, values) }
            grid.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            grid.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            grid.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
            grid.raises(LazyVGridContract.realizedChanged)
        }

        registry.add(LazyHGridContract.self, madeByHost: UIKitLazyGridView.self) { grid in
            grid.applies([
                LazyHGridContract.items, LazyHGridContract.flowRows, LazyHGridContract.rowSpacing,
                LazyHGridContract.columnSpacing, PaddingElementContract.contentPadding,
            ]) { view, values in
                view.tracks = values[LazyHGridContract.flowRows] ?? []
                view.runSpacing = values[LazyHGridContract.columnSpacing] ?? 0
                view.trackSpacing = values[LazyHGridContract.rowSpacing] ?? 0
                view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
                if view.cells.takeItems() { view.invalidateMeasurements() }
            }
            grid.applies(boxMembers) { view, values in applyBox(view, values) }
            grid.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            grid.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            grid.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
            grid.raises(LazyHGridContract.realizedChanged)
        }

        registry.add(ZStackContract.self, create: { _ in UIKitZStackView() }) { layout in
            layout.property(PaddingElementContract.contentPadding) { view, padding in view.padding = padding ?? EdgeInsets(0) }
            layout.applies(boxMembers) { view, values in applyBox(view, values) }
            layout.property(VisualElementContract.ignoresInput) { view, ignores in view.isUserInteractionEnabled = ignores != true }
            layout.property(LayoutContract.letsInputThrough) { view, lets in view.passesBeside = lets ?? false }
            layout.property(LayoutContract.hitShape) { view, shape in view.hitShape = shape }
        }
    }

    /// A ScrollView: its orientation, bars and room, and the offset the tree moves it to. Where the user moves it is
    /// reported by the element, on the display's frames.
    /// Design: docs/design/platforms/uikit/layout.md#scrolling
    static func scrolling(_ registry: Registry<UIView>) {
        registry.add(ScrollViewContract.self, create: { _ in UIKitScrollView() }) { scroll in
            scroll.applies([
                ScrollViewContract.orientation, ScrollViewContract.verticalScrollIndicators,
                ScrollViewContract.horizontalScrollIndicators, ScrollViewContract.scrollOffset,
                PaddingElementContract.contentPadding,
            ]) { view, values in
                view.apply(
                    orientation: values[ScrollViewContract.orientation] ?? .vertical,
                    padding: values[PaddingElementContract.contentPadding] ?? EdgeInsets(0),
                    verticalBar: values[ScrollViewContract.verticalScrollIndicators] ?? .automatic,
                    horizontalBar: values[ScrollViewContract.horizontalScrollIndicators] ?? .automatic,
                    offset: values.changed(ScrollViewContract.scrollOffset) ? values[ScrollViewContract.scrollOffset] : nil)
            }
            scroll.applies([
                VisualElementContract.background,
                BorderElementContract.shape, BorderElementContract.stroke, BorderElementContract.strokeWidth,
            ]) { view, values in
                // A scroller cuts what it shows to its bounds; a shape cuts it to the shape.
                view.setBox(
                    fill: values[VisualElementContract.background]?.propValue,
                    stroke: values[BorderElementContract.stroke]?.propValue,
                    width: values[BorderElementContract.strokeWidth],
                    shape: values[BorderElementContract.shape]?.propValue,
                    clips: true)
            }
            scroll.raises(ScrollViewContract.scrollXChanged)
            scroll.raises(ScrollViewContract.scrollYChanged)
            scroll.raises(ScrollViewContract.scrollStopped)
        }
    }

    /// What every layout takes of its own box: what fills it, its outline, its shape and its cut.
    private static let boxMembers: [any ContractMember] = [
        VisualElementContract.background,
        BorderElementContract.stroke, BorderElementContract.strokeWidth, BorderElementContract.shape,
        LayoutContract.clipsContent,
    ]

    private static func applyBox<Realized: ElementContract>(_ view: UIKitLayoutView, _ values: ElementValues<Realized>) {
        view.setBox(
            fill: values[VisualElementContract.background]?.propValue,
            stroke: values[BorderElementContract.stroke]?.propValue,
            width: values[BorderElementContract.strokeWidth],
            shape: values[BorderElementContract.shape]?.propValue,
            clips: values[LayoutContract.clipsContent] ?? false)
    }

    /// What both stacks take: the space between their children, and the space inside their own edge.
    private static let stackMembers: [any ContractMember] = [
        StackBaseContract.spacing, PaddingElementContract.contentPadding,
    ]

    private static func applyStack<Realized: ElementContract>(_ view: UIKitStackView, _ values: ElementValues<Realized>) {
        view.spacing = values[StackBaseContract.spacing] ?? 0
        view.padding = values[PaddingElementContract.contentPadding] ?? EdgeInsets(0)
    }
}
#endif
