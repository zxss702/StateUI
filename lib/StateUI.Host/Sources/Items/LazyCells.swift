// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI

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

    private var positions: [String: Int] = [:]

    /// The identities the tree was last told to build.
    private var built: Set<String> = []

    /// The window the host last asked for and when - the run's pace is read
    /// from how it moves, and the reach held around it grows and shrinks
    /// with it.
    private var lastAsk: (first: Int, last: Int, at: ContinuousClock.Instant)?

    /// How fast the window moves, in places a second - smoothed, and let go
    /// once the window rests.
    private var pace: Double = 0

    /// A pending collapse of the reach after the window settles.
    private var settling: Task<Void, Never>?

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

    /// Takes the identities the element carries now; whether they changed.
    /// Measures of identities no longer shown are let go; a moved identity
    /// keeps its measure at its new place.
    @discardableResult
    public func takeItems() -> Bool {
        let now = element?.value(.items)?.strings ?? []
        guard now != identities else { return false }
        identities = now
        positions = Dictionary(identities.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        built = []
        lastAsk = nil
        pace = 0
        settling?.cancel()
        settling = nil
        extents.keep(identities: Set(now))
        return true
    }

    /// The place `identity` shows at; nil where it is none of them.
    public func position(of identity: String) -> Int? {
        positions[identity]
    }

    /// The mounted subtree of `identity`, where there is one.
    public func item(_ identity: String) -> MountedElement? {
        element?.children.first { $0.id == .manual(identity) }
    }

    /// The mounted children, each with the place its identity stands at, in
    /// the order they show.
    public var mounted: [(place: Int, item: MountedElement)] {
        guard let element else { return [] }
        return element.children.compactMap { child in
            guard case .manual(let identity) = child.id, let place = positions[identity] else { return nil }
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

    /// The children of places `first..<last` are the ones the host can show;
    /// those plus a reach around them are what the tree is told to build -
    /// told only where the answer changed.
    ///
    /// The reach is not a constant: a window in motion leads its way by a
    /// stretch that grows with its pace (momentum keeps the places ahead
    /// built before they arrive), and a window at rest holds little beyond
    /// what it shows - the places left behind are let go.
    /// Design: docs/design/host/items.md#within-reach
    public func tell(first: Int, last: Int) {
        guard let element, let runtime, !identities.isEmpty else { return }
        let first = max(0, first), last = min(last, identities.count - 1)
        guard first <= last else { return }

        let now = ContinuousClock.now
        if let prev = lastAsk {
            let (seconds, attoseconds) = (now - prev.at).components
            let dt = Double(seconds) + Double(attoseconds) / 1e18
            // A gap this long is a fresh settling, not movement in progress.
            if dt > 0.4 { pace = 0 }
            else if dt > 0 {
                pace += (Double(first - prev.first) / dt - pace) * min(1, dt * 8)
            }
        }
        lastAsk = (first, last, now)

        // A settled window keeps what it shows and a breath more; a moving
        // one leads the way it goes by up to two more of itself.
        let window = last - first + 1
        let lead = min(2 * window + 4, Int(abs(pace) * 0.15))
        let before = pace < -0.5 ? max(2, lead) : 2
        let after = pace > 0.5 ? max(2, lead) : 2
        let within = Array(identities[max(0, first - before)...min(identities.count - 1, last + after)])
        if Set(within) != built {
            built = Set(within)
            element.send(.realizedChanged, [.strings(within)], in: runtime)
        }
        settle()
    }

    /// After the window rests, the reach is drawn in to the window alone -
    /// run once the motion has had its moment to be over.
    private func settle() {
        settling?.cancel()
        guard lastAsk != nil else { return }
        settling = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self, let ask = self.lastAsk, !Task.isCancelled else { return }
            let (seconds, attoseconds) = (ContinuousClock.now - ask.at).components
            guard Double(seconds) + Double(attoseconds) / 1e18 > 0.35 else { return }
            self.pace = 0
            let within = Set(self.identities[ask.first...ask.last])
            guard within != self.built, let element = self.element, let runtime = self.runtime
            else { return }
            self.built = within
            element.send(.realizedChanged, [.strings(self.identities[ask.first...ask.last].map { $0 })], in: runtime)
        }
    }

    /// A grid asks by RUN - a row at a time: `first..<last` rows of `perRun`
    /// cells are the ones in view, and the cells those rows hold are told.
    public func tellRuns(first: Int, last: Int, perRun: Int) {
        let perRun = max(1, perRun)
        tell(first: first * perRun, last: (last + 1) * perRun - 1)
    }

    /// The tree builds every child - a lazy container standing outside any
    /// scroller has no viewport to narrow by.
    public func tellAll() {
        guard let element, let runtime, Set(identities) != built else { return }
        built = Set(identities)
        element.send(.realizedChanged, [.strings(identities)], in: runtime)
    }
}

/// Where a lazy container's children stand along its run, before and after
/// they exist: the ones mounted are measured, and the rest stand for by the
/// mean of the measured - so the scroll room is known at once, and a child
/// taking its own size shifts only the places after it.
@_spi(Host) public struct LazyExtents: Sendable {
    /// The gap between one child and the next.
    public var spacing: Double = 0

    /// The room kept before the first child and after the last.
    public var padding: (head: Double, tail: Double) = (0, 0)

    /// The extent a child no measure has answered for yet - the mean of the
    /// ones measured, the first guess before any is.
    public private(set) var estimate: Double = 44

    /// The measured extents, by identity.
    private var measured: [String: Double] = [:]

    /// An empty book - the estimate stands for every child until one is
    /// measured.
    public init() {}

    /// `identity`'s child is `extent` long on the run.
    public mutating func measure(_ identity: String, extent: Double) {
        guard extent > 0 else { return }
        measured[identity] = extent
        estimate = measured.values.reduce(0, +) / Double(measured.count)
    }

    /// Measures of identities no longer shown are let go.
    public mutating func keep(identities: Set<String>) {
        measured = measured.filter { identities.contains($0.key) }
    }

    /// Where `place`'s child begins on the run, counting the padding head.
    public func offset(of place: Int, in identities: [String]) -> Double {
        var offset = padding.head + spacing * Double(min(place, identities.count))
        for index in 0..<min(place, identities.count) { offset += extent(of: identities[index]) }
        return offset
    }

    /// The length `identity`'s child takes on the run, measured or estimated.
    public func extent(of identity: String) -> Double {
        measured[identity] ?? estimate
    }

    /// The whole run's length, both paddings in.
    public func total(in identities: [String]) -> Double {
        guard !identities.isEmpty else { return padding.head + padding.tail }
        return offset(of: identities.count, in: identities) + padding.tail - spacing
    }

    /// The places standing in `span` - `from` to `to` on the run - widened by
    /// `overscan` at both ends.
    public func places(in span: Range<Double>, overscan: Double, in identities: [String]) -> Range<Int> {
        guard !identities.isEmpty else { return 0..<0 }
        let lo = span.lowerBound - overscan, hi = span.upperBound + overscan
        var first = identities.count, last = -1
        var y = padding.head
        for (index, identity) in identities.enumerated() {
            let next = y + extent(of: identity) + (index + 1 < identities.count ? spacing : 0)
            if next > lo && y < hi {
                first = min(first, index)
                last = index
            }
            y = next
        }
        guard last >= 0 else { return 0..<0 }
        return first..<(last + 1)
    }
}

/// A grid's run arithmetic: one extent a row (or a column, across), measured
/// of the longest cell it holds. Runs are named by their place, not a child's
/// identity - a changed column count makes new runs, and the measures go with
/// the old ones.
@_spi(Host) public struct LazyRunExtents: Sendable {
    /// The gap between one run and the next.
    public var spacing: Double = 0

    /// The room kept before the first run and after the last.
    public var padding: (head: Double, tail: Double) = (0, 0)

    /// The extent a run no measure has answered for yet - the mean of the
    /// ones measured, the first guess before any is.
    public private(set) var estimate: Double = 44

    /// The measured extents, by place.
    private var measured: [Int: Double] = [:]

    /// An empty book - the estimate stands for every run until one is
    /// measured.
    public init() {}

    /// `run`'s longest cell is `extent` on the run.
    public mutating func measure(_ run: Int, extent: Double) {
        guard extent > 0 else { return }
        measured[run] = max(extent, measured[run] ?? 0)
        estimate = measured.values.reduce(0, +) / Double(measured.count)
    }

    /// Every measure is let go - the runs count anew.
    public mutating func reset() {
        measured = [:]
        estimate = 44
    }

    /// The length `run` takes, measured or estimated.
    public func extent(of run: Int) -> Double {
        measured[run] ?? estimate
    }

    /// Where `run` begins on the run, counting the padding head.
    public func offset(of run: Int, count: Int) -> Double {
        var offset = padding.head + spacing * Double(min(run, count))
        for index in 0..<min(run, count) { offset += extent(of: index) }
        return offset
    }

    /// The whole run's length over `count` runs, both paddings in.
    public func total(count: Int) -> Double {
        guard count > 0 else { return padding.head + padding.tail }
        return offset(of: count, count: count) + padding.tail - spacing
    }

    /// The runs standing in `span`, widened by `overscan` at both ends.
    public func places(in span: Range<Double>, overscan: Double, count: Int) -> Range<Int> {
        guard count > 0 else { return 0..<0 }
        let lo = span.lowerBound - overscan, hi = span.upperBound + overscan
        var first = count, last = -1
        var y = padding.head
        for index in 0..<count {
            let next = y + extent(of: index) + (index + 1 < count ? spacing : 0)
            if next > lo && y < hi {
                first = min(first, index)
                last = index
            }
            y = next
        }
        guard last >= 0 else { return 0..<0 }
        return first..<(last + 1)
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
