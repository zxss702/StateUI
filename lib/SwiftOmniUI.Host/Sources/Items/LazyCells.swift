// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI

/// What a host's lazy container holds of one lazy layout, and what it tells
/// the tree - alike on every host: the children's identities in order, the
/// ones standing in view, the mounted subtree each builds, and the run's
/// arithmetic.
///
/// Where a collection (`ItemsCells`) is asked for entries by the cells its
/// toolkit reuses, a lazy container asks itself: it measures the room on
/// screen, names the children in it by `tell`, and the tree mounts those -
/// and only those - under it.
/// Design: docs/design/host/items.md#the-view-moving
@_spi(Host) @MainActor public final class LazyCells {
    /// The lazy element, while it stands in the tree.
    public private(set) weak var element: MountedElement?

    private weak var runtime: HostRuntime?

    /// Every child's identity in the order it shows, as last taken.
    public private(set) var identities: [String] = []

    private var contentRevision = -1
    private var positions: [String: Int] = [:]

    /// Content changes waiting for arrangement. Measurement and viewport realization must
    /// not consume this; the host clears it after beginning the changed arrangement.
    public var animatesChanges = false
    /// New source identities awaiting their first placement; recycled neighbours never enter here.
    public var inserting: Set<String> = []
    /// The source positions mounted, including the fixed neighbour window.
    public private(set) var built: Range<Int> = 0..<0

    /// The last viewport and geometry asked for. Identical layout notices do
    /// not perform another range lookup or send another render.
    public var window: (span: Range<Double>, revision: Int, perRun: Int)?

    /// Diagnostic counts for the work a lazy window actually performs.
    public private(set) var requests = 0
    /// Viewport range lookups performed.
    public var searches = 0
    /// Native child measurements performed.
    public var measurements = 0

    /// Document-coordinate correction not yet applied to the mounted presentation frames.
    public var anchorShift = 0.0

    private var anchor: (identity: String, place: Int, inset: Double, origin: Double, viewport: Double, trailing: Bool)?

    /// The run's arithmetic: measured extents by identity, the rest by the
    /// mean of the measured.
    public var extents = LazyExtents()

    /// A grid's arithmetic: one extent a row, measured of the tallest cell
    /// it holds; forgotten where the column count changes the runs.
    public var runs = LazyRunExtents()

    /// The cells of `element`, telling `runtime`.
    public init(_ element: MountedElement, in runtime: HostRuntime) {
        self.element = element
        self.runtime = runtime
    }

    /// Takes a fresh content source. Insertions, removals and moves preserve the
    /// measured sizes of surviving identities; changed content invalidates them.
    @discardableResult
    public func takeItems() -> Bool {
        let now = element?.value(.items)?.strings ?? []
        let revision = element?.lazyContentRevision ?? 0
        guard now != identities || revision != contentRevision else { return false }
        if contentRevision >= 0 {
            animatesChanges = true
            inserting.formUnion(Set(now).subtracting(identities))
        }
        contentRevision = revision
        inserting.formIntersection(now)
        if now != identities { extents.keep(identities: Set(now)) }
        else { extents.reset() }
        identities = now
        if now.isEmpty {
            anchor = nil
            anchorShift = 0
        }
        positions = Dictionary(identities.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        built = 0..<0
        window = nil
        runs.reset()
        return true
    }

    /// The place `identity` shows at; nil where it is none of them.
    public func position(of identity: String) -> Int? {
        positions[identity]
    }

    /// The mounted subtree of `identity`, where there is one.
    public func item(_ identity: String) -> MountedElement? {
        element?.children.first {
            if let source = $0.lazyIdentity { return source == identity }
            return $0.id == .manual(identity)
        }
    }

    /// The mounted children, each with the place its identity stands at, in
    /// the order they show.
    public var mounted: [(place: Int, item: MountedElement)] {
        guard let element else { return [] }
        return element.children.compactMap { child in
            guard case .manual(let identity) = child.id,
                  let place = positions[child.lazyIdentity ?? identity] else { return nil }
            return (place, child)
        }
        .sorted { $0.0 < $1.0 }
    }

    /// Where `place`'s child begins on the run, counting the padding head.
    public func offset(of place: Int) -> Double {
        extents.offset(of: place, in: identities)
    }

    /// The places standing in `span` - `from` to `to` on the run - widened by
    /// `overscan` at both ends.
    public func places(in span: Range<Double>, overscan: Double) -> Range<Int> {
        extents.places(in: span, overscan: overscan, in: identities)
    }

    /// The whole run's length, both paddings in.
    public var total: Double {
        extents.total(in: identities)
    }

    /// Reads a viewport only when it or the content geometry changed. Shared
    /// by every host's stack and grid, including empty and clipped windows.
    public func show(_ span: Range<Double>, perRun: Int = 1, grid: Bool = false) {
        let revision = grid ? runs.revision : extents.revision
        guard window?.span != span || window?.revision != revision || window?.perRun != perRun else { return }
        let moved = window?.revision == revision && window?.span != span
        window = (span, revision, perRun)
        searches += 1
        let wanted = grid
            ? runs.places(in: span, overscan: 0, count: (identities.count + perRun - 1) / perRun)
            : extents.places(in: span, overscan: 0, in: identities)
        if !wanted.isEmpty, anchor == nil || moved {
            let place = wanted.lowerBound * perRun
            let origin = grid
                ? runs.offset(of: wanted.lowerBound, count: (identities.count + perRun - 1) / perRun)
                : extents.offset(of: place, in: identities)
            let total = grid
                ? runs.total(count: (identities.count + perRun - 1) / perRun)
                : extents.total(in: identities)
            anchor = (identities[place], place, span.lowerBound - origin, span.lowerBound,
                      span.upperBound - span.lowerBound, span.lowerBound > 0 && abs(span.upperBound - total) < 1)
        }
        guard let element, let runtime else { return }
        let lower = min(identities.count, max(0, wanted.lowerBound - 1) * perRun)
        let upper = min(identities.count, (wanted.upperBound + 1) * perRun)
        let within = !wanted.isEmpty && lower < upper ? lower..<upper : 0..<0
        inserting.formIntersection(identities[within])
        guard within != built else { return }
        if !inserting.isDisjoint(with: identities[within]) { animatesChanges = true }
        built = within
        requests += 1
        element.send(.realizedChanged, [.strings(Array(identities[within]))], in: runtime)
    }

    /// The corrected viewport origin after measurements or data move its anchor.
    /// A viewport at the end stays at the end. Hosts apply this absolute origin
    /// because their native scroller may already have clamped a shrinking document.
    public func correctedOrigin(perRun: Int = 1, grid: Bool = false) -> Double? {
        guard let held = anchor, !identities.isEmpty else { return nil }
        let place = positions[held.identity] ?? min(held.place, identities.count - 1)
        let start = grid
            ? runs.offset(of: place / perRun, count: (identities.count + perRun - 1) / perRun)
            : extents.offset(of: place, in: identities)
        let total = grid
            ? runs.total(count: (identities.count + perRun - 1) / perRun)
            : extents.total(in: identities)
        let origin = max(0, held.trailing ? total - held.viewport : start + held.inset)
        anchorShift += origin - held.origin
        anchor = (identities[place], place, held.inset, origin, held.viewport, held.trailing)
        return abs(origin - held.origin) > 0.0001 ? origin : nil
    }

    /// Without a scroller there is no viewport to narrow by.
    public func tellAll() {
        guard let element, let runtime, built != 0..<identities.count else { return }
        if !inserting.isEmpty { animatesChanges = true }
        built = 0..<identities.count
        requests += 1
        element.send(.realizedChanged, [.strings(identities)], in: runtime)
    }

}

/// Measured child extents and a cached prefix of their estimated places.
/// The host invalidates measurements when the source or its cross-axis size changes.
@_spi(Host) public struct LazyExtents: Sendable {
    /// The spacing between adjacent children or runs.
    public var spacing: Double = 0 {
        didSet { if spacing != oldValue { revision += 1; prefix = [] } }
    }
    /// Space before the first and after the last child or run.
    public var padding: (head: Double, tail: Double) = (0, 0) {
        didSet { if padding != oldValue { revision += 1; prefix = [] } }
    }
    /// The mean measured extent used for unseen children or runs.
    public private(set) var estimate: Double = 44
    /// Geometry version used to reuse viewport searches.
    public private(set) var revision = 0
    private var measured: [String: Double] = [:]
    private var sum = 0.0
    private var prefix: [Double] = []

    /// Starts with a provisional extent until the first window is measured.
    public init() {}

    /// A complete child measurement. Zero is a valid size.
    public mutating func measure(_ identity: String, extent: Double) {
        guard extent.isFinite, extent >= 0, measured[identity] != extent else { return }
        let previous = measured[identity] ?? estimate
        sum += extent - (measured[identity] ?? 0)
        measured[identity] = extent
        let next = sum / Double(measured.count)
        if extent != previous || next != estimate {
            revision += 1
            prefix = []
        }
        estimate = next
    }

    /// Reordering invalidates positions even when every identity survives.
    public mutating func keep(identities: Set<String>) {
        measured = measured.filter { identities.contains($0.key) }
        sum = measured.values.reduce(0, +)
        estimate = measured.isEmpty ? 44 : sum / Double(measured.count)
        revision += 1
        prefix = []
    }

    /// Forget sizes that were measured under a different layout proposal.
    public mutating func reset() {
        measured = [:]
        sum = 0
        revision += 1
        prefix = []
        // Keep the last useful estimate until the new visible measurements arrive.
    }

    /// The measured child extent, or the current estimate.
    public func extent(of identity: String) -> Double {
        measured[identity] ?? estimate
    }

    /// The prefix is rebuilt once per geometry change, never once per child.
    public mutating func offset(of place: Int, in identities: [String]) -> Double {
        if prefix.count != identities.count + 1 {
            prefix = [padding.head]
            prefix.reserveCapacity(identities.count + 1)
            for index in 0..<identities.count {
                prefix.append(prefix[index] + extent(of: identities[index]) + spacing)
            }
        }
        return prefix[max(0, min(place, identities.count))]
    }

    /// Estimated length of the entire data source, including both paddings.
    public mutating func total(in identities: [String]) -> Double {
        guard identities.count > 0 else { return padding.head + padding.tail }
        return offset(of: identities.count, in: identities) + padding.tail - spacing
    }

    /// Only actual intersections count as visible; spacing is not a child.
    public mutating func places(in span: Range<Double>, overscan: Double, in identities: [String]) -> Range<Int> {
        guard identities.count > 0, !span.isEmpty else { return 0..<0 }
        _ = offset(of: 0, in: identities)
        let lo = span.lowerBound - overscan, hi = span.upperBound + overscan
        var lower = 0, upper = identities.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if prefix[middle + 1] - spacing <= lo { lower = middle + 1 }
            else { upper = middle }
        }
        let first = lower
        upper = identities.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if prefix[middle] < hi { lower = middle + 1 }
            else { upper = middle }
        }
        return first < lower ? first..<lower : 0..<0
    }
}

/// Measured row or column extents and a cached prefix of their estimated places.
/// The host invalidates measurements when the source or its cross-axis size changes.
@_spi(Host) public struct LazyRunExtents: Sendable {
    /// The spacing between adjacent children or runs.
    public var spacing: Double = 0 {
        didSet { if spacing != oldValue { revision += 1; prefix = [] } }
    }
    /// Space before the first and after the last child or run.
    public var padding: (head: Double, tail: Double) = (0, 0) {
        didSet { if padding != oldValue { revision += 1; prefix = [] } }
    }
    /// The mean measured extent used for unseen children or runs.
    public private(set) var estimate: Double = 44
    /// Geometry version used to reuse viewport searches.
    public private(set) var revision = 0
    private var measured: [Int: Double] = [:]
    private var sum = 0.0
    private var prefix: [Double] = []

    /// Starts with a provisional extent until the first window is measured.
    public init() {}

    /// A complete run, measured as the largest of its current cells. Zero is a valid size.
    public mutating func measure(_ run: Int, extent: Double) {
        guard extent.isFinite, extent >= 0, measured[run] != extent else { return }
        let previous = measured[run] ?? estimate
        sum += extent - (measured[run] ?? 0)
        measured[run] = extent
        let next = sum / Double(measured.count)
        if extent != previous || next != estimate {
            revision += 1
            prefix = []
        }
        estimate = next
    }

    /// Forget sizes that were measured under a different layout proposal.
    public mutating func reset() {
        measured = [:]
        sum = 0
        revision += 1
        prefix = []
        // Keep the last useful estimate until the new visible measurements arrive.
    }

    /// The measured run extent, or the current estimate.
    public func extent(of run: Int) -> Double {
        measured[run] ?? estimate
    }

    /// The prefix is rebuilt once per geometry change, never once per child.
    public mutating func offset(of place: Int, count: Int) -> Double {
        if prefix.count != count + 1 {
            prefix = [padding.head]
            prefix.reserveCapacity(count + 1)
            for index in 0..<count {
                prefix.append(prefix[index] + extent(of: index) + spacing)
            }
        }
        return prefix[max(0, min(place, count))]
    }

    /// Estimated length of the entire data source, including both paddings.
    public mutating func total(count: Int) -> Double {
        guard count > 0 else { return padding.head + padding.tail }
        return offset(of: count, count: count) + padding.tail - spacing
    }

    /// Only actual intersections count as visible; spacing is not a child.
    public mutating func places(in span: Range<Double>, overscan: Double, count: Int) -> Range<Int> {
        guard count > 0, !span.isEmpty else { return 0..<0 }
        _ = offset(of: 0, count: count)
        let lo = span.lowerBound - overscan, hi = span.upperBound + overscan
        var lower = 0, upper = count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if prefix[middle + 1] - spacing <= lo { lower = middle + 1 }
            else { upper = middle }
        }
        let first = lower
        upper = count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if prefix[middle] < hi { lower = middle + 1 }
            else { upper = middle }
        }
        return first < lower ? first..<lower : 0..<0
    }
}

/// A lazy grid's tracks across its run: the columns a `LazyVGrid` fills, or
/// the rows a `LazyHGrid` fills, resolved for the room the host gives.
@_spi(Host) public enum LazyGridTracks {
    /// The sizes `items` stand for at `width`: stated tracks as they stand,
    /// an `.adaptive` one as many `.flexible` copies as the room fits.
    public static func resolve(_ items: [GridItem], width: Double?, spacing: Double) -> [GridItem.Size] {
        GridArithmetic.resolvedFlow(items, width: width, spacing: spacing)
    }

    /// How wide each resolved track stands: fixed as stated, the rest
    /// sharing what is left within their bounds.
    public static func extents(_ tracks: [GridItem.Size], width: Double, spacing: Double) -> [Double] {
        var taken = spacing * Double(max(tracks.count - 1, 0))
        var shares = 0
        for track in tracks {
            switch track {
            case .fixed(let width): taken += width
            case .flexible, .adaptive: shares += 1
            }
        }
        let share = max(0, width - taken) / Double(max(shares, 1))
        return tracks.map { track in
            switch track {
            case .fixed(let width): return width
            case .flexible(let minimum, let maximum), .adaptive(let minimum, let maximum):
                return min(max(share, minimum), max(minimum, maximum))
            }
        }
    }
}
