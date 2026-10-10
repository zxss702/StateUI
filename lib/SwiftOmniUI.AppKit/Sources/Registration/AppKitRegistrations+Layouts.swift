// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

extension AppKitRegistrations {
    /// The stacks and the grid: the room a layout leaves around and between
    /// its children. What ARRANGES the children is not here - a layout walks
    /// its own rows, which is the host's work, and a registration describes
    /// one view.
    static func layouts(_ registry: Registry<NSView>) {
        registry.add(VStackContract.self, create: { _ in AppKitStackView(axis: .vertical) }) { stack in
            stack.applies(Self.stackMembers) { view, values in
                view.spacing = values[StackBaseContract.spacing]
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
        }

        registry.add(HStackContract.self, create: { _ in AppKitStackView(axis: .horizontal) }) { stack in
            stack.applies(Self.stackMembers) { view, values in
                view.spacing = values[StackBaseContract.spacing]
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
        }

        registry.add(LazyVStackContract.self, madeByHost: AppKitLazyStackView.self) { lazy in
            lazy.applies(Self.stackMembers + [LazyVStackContract.items]) { view, values in
                view.spacing = values[StackBaseContract.spacing]
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
            lazy.raises(LazyVStackContract.realizedChanged)
        }

        registry.add(LazyHStackContract.self, madeByHost: AppKitLazyStackView.self) { lazy in
            lazy.applies(Self.stackMembers + [LazyHStackContract.items]) { view, values in
                view.spacing = values[StackBaseContract.spacing]
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
            lazy.raises(LazyHStackContract.realizedChanged)
        }

        registry.add(LazyVGridContract.self, madeByHost: AppKitLazyGridView.self) { grid in
            grid.property(ViewContract.horizontalContentAlignment) { view, alignment in
                view.trackAlignment = alignment ?? .center
            }
            grid.applies([
                LazyVGridContract.items, LazyVGridContract.flowColumns, LazyVGridContract.rowSpacing,
                LazyVGridContract.columnSpacing, PaddingElementContract.contentPadding,
            ]) { view, values in
                view.tracks = values[LazyVGridContract.flowColumns] ?? []
                view.runSpacing = CGFloat(values[LazyVGridContract.rowSpacing] ?? 0)
                view.trackSpacing = CGFloat(values[LazyVGridContract.columnSpacing] ?? 0)
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
            grid.raises(LazyVGridContract.realizedChanged)
        }

        registry.add(LazyHGridContract.self, madeByHost: AppKitLazyGridView.self) { grid in
            grid.property(ViewContract.verticalContentAlignment) { view, alignment in
                view.trackAlignment = alignment ?? .center
            }
            grid.applies([
                LazyHGridContract.items, LazyHGridContract.flowRows, LazyHGridContract.rowSpacing,
                LazyHGridContract.columnSpacing, PaddingElementContract.contentPadding,
            ]) { view, values in
                view.tracks = values[LazyHGridContract.flowRows] ?? []
                view.runSpacing = CGFloat(values[LazyHGridContract.columnSpacing] ?? 0)
                view.trackSpacing = CGFloat(values[LazyHGridContract.rowSpacing] ?? 0)
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
            grid.raises(LazyHGridContract.realizedChanged)
        }

        // The host makes the scroll view; its registration takes the members alone.
        // Design: docs/design/platforms/appkit/registrations.md#the-scroll-view
        registry.add(ScrollViewContract.self, madeByHost: AppKitScrollView.self) { scroll in
            scroll.applies([
                ScrollViewContract.orientation,
                ScrollViewContract.verticalScrollIndicators,
                ScrollViewContract.horizontalScrollIndicators,
                ScrollViewContract.isScrollDisabled,
                ScrollViewContract.scrollBounceBehavior,
                ScrollViewContract.scrollOffset,
                ScrollViewContract.defaultScrollAnchor,
                ScrollContentElementContract.scrollContentBackground,
                LayoutContract.clipsContent,
                PaddingElementContract.contentPadding,
            ]) { view, values in
                // The offset is written only where the tree moved it.
                // Design: docs/design/platforms/appkit/input.md#scrolling
                let offset = values.changed(ScrollViewContract.scrollOffset)
                    ? values[ScrollViewContract.scrollOffset].map { NSPoint(x: $0.x, y: $0.y) }
                    : nil

                view.apply(
                    orientation: (values[ScrollViewContract.orientation] ?? .vertical).rawValue,
                    padding: Self.edgeInsets(values[PaddingElementContract.contentPadding]),
                    verticalBarVisibility:
                        (values[ScrollViewContract.verticalScrollIndicators] ?? .automatic).rawValue,
                    horizontalBarVisibility:
                        (values[ScrollViewContract.horizontalScrollIndicators] ?? .automatic).rawValue,
                    isScrollDisabled: values[ScrollViewContract.isScrollDisabled] ?? false,
                    scrollBounceBehavior:
                        (values[ScrollViewContract.scrollBounceBehavior] ?? .automatic).rawValue,
                    scrollContentBackground: values[ScrollContentElementContract.scrollContentBackground]
                        .map { $0 != .hidden },
                    clipsContent: values[LayoutContract.clipsContent],
                    defaultAnchor: values[ScrollViewContract.defaultScrollAnchor]
                        .map { [NSNumber(value: $0.x), NSNumber(value: $0.y)] },
                    offset: offset)
            }
            scroll.applies([
                BorderElementContract.shape, BorderElementContract.stroke, BorderElementContract.strokeWidth,
            ]) { view, values in
                view.setBox(
                    stroke: values[BorderElementContract.stroke]?.propValue,
                    strokeWidth: values[BorderElementContract.strokeWidth],
                    shape: values[BorderElementContract.shape]?.propValue)
            }
        }

        registry.add(GridContract.self, create: { _ in AppKitGridView() }) { grid in
            grid.applies([
                GridContract.rows, GridContract.columns,
                GridContract.rowSpacing, GridContract.columnSpacing,
                GridContract.flowColumns,
                PaddingElementContract.contentPadding,
            ]) { view, values in
                view.rows = Self.gridLengths(values[GridContract.rows])
                view.columns = Self.gridLengths(values[GridContract.columns])
                view.flowColumns = values[GridContract.flowColumns] ?? []
                view.rowSpacing = CGFloat(values[GridContract.rowSpacing] ?? 0)
                view.columnSpacing = CGFloat(values[GridContract.columnSpacing] ?? 0)
                view.padding = Self.edgeInsets(values[PaddingElementContract.contentPadding])
            }
        }
    }

    /// What both stacks take: the space between their children, and the space
    /// kept inside their own edge.
    private static let stackMembers: [any ContractMember] = [
        StackBaseContract.spacing, PaddingElementContract.contentPadding,
    ]

    /// A row or a column is a kind and an amount, and travels as the two of
    /// them - a LIST OF VALUES, as a render transform does.
    private static func gridLengths(_ value: [GridLength]?) -> [GridLength] {
        value ?? []
    }
}

#endif
