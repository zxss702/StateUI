// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// What a lazy container's view does alike: it keeps the children in view
/// mounted - and only those - telling the tree which identities the window
/// wants built, and standing each at the offset its measure says.
///
/// The run's length is the estimates' before the children exist, so the
/// scroll room answers at once; a child's own measure lands as it mounts and
/// shifts the places after it, the way a scroller of estimated rows does.
/// Design: docs/design/host/items.md#the-view-moving
@MainActor
class UIKitLazyView: UIKitLayoutView {
    /// The direction the children stack in.
    let axis: StackArithmetic.Axis

    /// The cells' bookkeeping: identities, mounted children, the runs' measures.
    let cells: LazyCells

    /// The children mounted now, by identity.
    private(set) var held: [String: UIKitLayoutItem] = [:]

    /// The scroller whose offset moving re-asks the window; the nearest one's.
    private weak var watching: UIScrollView?

    /// The offset observation, kept for as long as it watches.
    private var observing: NSKeyValueObservation?

    /// Natural sizes survive scrolling; content invalidation or a changed
    /// cross-axis proposal clears only the measurements that can be stale.
    var measured: [String: (proposal: Double?, size: LayoutSize)] = [:]
    var measuredRevision = -1
    var measuredAcross: Double?
    var naturalAcross = 44.0
    var anchorTarget: Double?

    /// A window change under way asks the run again once, not per notice.
    private var retellQueued = false
    private var fillingWindow = false

    init(axis: StackArithmetic.Axis, cells: LazyCells) {
        self.axis = axis
        self.cells = cells
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("UIKitLazyView is made in code")
    }

    /// The mounted children, held by identity.
    func setItems(_ items: [(identity: String, item: UIKitLayoutItem)]) {
        let now = Dictionary(items.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        guard now.keys != held.keys || now.contains(where: {
            held[$0.key]?.view !== $0.value.view || held[$0.key]?.values != $0.value.values
        }) else { return }
        for (identity, previous) in held {
            if now[identity]?.view !== previous.view || now[identity]?.values != previous.values {
                measured.removeValue(forKey: identity)
            }
        }
        for gone in held where now[gone.key] == nil {
            gone.value.view.removeFromSuperview()
        }
        for item in items where item.item.view.superview !== self {
            addSubview(item.item.view)
        }
        held = now
        forgetMeasurements()
        measuredRevision = measurements.revision
        setNeedsLayout()
    }

    /// The nearest scroller clipping this run on its own axis, or none: a
    /// `UIKitScrollView` clips where its orientation goes this way; any other
    /// scroller clips both ways.
    private var clip: UIScrollView? {
        var view = superview
        while let current = view {
            if let scroller = current as? UIScrollView {
                guard let own = scroller.superview as? UIKitScrollView,
                      !own.orientation.takes(axis)
                else { return scroller }
            }
            view = current.superview
        }
        return nil
    }

    /// Forgets this run's measure and every ancestor's that follows it - the
    /// scroll document's among them - so the room is sized anew. The item
    /// list changing length is exactly such a change.
    func invalidateMeasurements() {
        var view: UIView? = self
        while let current = view {
            (current as? UIKitLayoutView)?.forgetMeasurements()
            current.setNeedsLayout()
            view = current.superview
        }
    }

    /// The window the run shows - the scroller's bounds brought into this
    /// view, along the run.
    var span: Range<Double>? {
        guard !cells.identities.isEmpty, let scroller = clip else { return nil }
        let visible = scroller.convert(scroller.bounds, to: self)
        guard !visible.isEmpty else { return nil }
        return axis == .vertical
            ? Double(visible.minY)..<Double(visible.maxY)
            : Double(visible.minX)..<Double(visible.maxX)
    }

    /// Asks the tree for the children the window wants; each kind answers
    /// which places a span holds. No scroller to narrow by means all of them.
    private func retell() {
        guard !retellQueued else { return }
        retellQueued = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.retellQueued = false
            self.watchClip()
            // No clip to narrow by means all of it stands in view - a lazy
            // container outside any scroller builds every child.
            guard self.watching != nil else {
                if self.window != nil { self.cells.tellAll() }
                return
            }
            if let origin = self.anchorTarget, let scroll = self.watching {
                var target = scroll.contentOffset
                scroll.superview?.layoutIfNeeded()
                let corner = self.convert(self.bounds.origin, to: scroll)
                if self.axis == .vertical { target.y = corner.y + origin }
                else { target.x = corner.x + origin }
                self.anchorTarget = nil
                scroll.setContentOffset(target, animated: false)
            }
            self.tellWindow(self.span ?? 0..<0)
        }
    }

    /// The places standing in `span`, as the kind's runs count them.
    func tellWindow(_ span: Range<Double>) {}

    /// Recomputes the places when the scroller's window moved.
    private func watchClip() {
        let scroller = clip
        guard scroller !== watching else { return }
        observing?.invalidate()
        observing = nil
        watching = scroller
        if let scroller {
            observing = scroller.observe(\.contentOffset) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.windowMoved() }
            }
        }
    }

    private func windowMoved() {
        guard !fillingWindow else { return }
        guard anchorTarget == nil else {
            retell()
            return
        }
        fillingWindow = true
        defer { fillingWindow = false }
        var passes = 0
        repeat {
            tellWindow(span ?? 0..<0)
            watching?.superview?.layoutIfNeeded()
            layoutIfNeeded()
            if let origin = anchorTarget, let scroll = watching {
                scroll.superview?.layoutIfNeeded()
                let corner = convert(bounds.origin, to: scroll)
                var target = scroll.contentOffset
                if axis == .vertical { target.y = corner.y + origin }
                else { target.x = corner.x + origin }
                anchorTarget = nil
                scroll.setContentOffset(target, animated: false)
            }
            passes += 1
            let revision = self is UIKitLazyGridView ? cells.runs.revision : cells.extents.revision
            if cells.window?.span == (span ?? 0..<0), cells.window?.revision == revision { break }
        } while passes < 8
        retell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        retell()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        watchClip()
        retell()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        watchClip()
        retell()
    }
}

/// A lazy stack: one child a place.
final class UIKitLazyStackView: UIKitLazyView {
    var spacing = 0.0 {
        didSet { if spacing != oldValue { cells.extents.spacing = spacing; forgetMeasurements() } }
    }

    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.extents.padding = (head: axis == .vertical ? padding.top : padding.left,
                                       tail: axis == .vertical ? padding.bottom : padding.right)
                forgetMeasurements()
            }
        }
    }

    /// The room a child gets across - inside the padding.
    private var acrossRoom: Double {
        axis == .vertical
            ? Double(bounds.width) - padding.left - padding.right
            : Double(bounds.height) - padding.top - padding.bottom
    }

    /// As wide as offered and as long as the run measures.
    override func contentSize(width: Double?) -> LayoutSize {
        let total = cells.total
        return axis == .vertical
            ? LayoutSize(width: width ?? 0, height: total)
            : LayoutSize(width: total, height: naturalAcross + padding.top + padding.bottom)
    }

    /// Every mounted child measures, is stood at its offset, and the window
    /// re-asks what the tree builds.
    override func arrange(in bounds: Rect) {
        places.begin(width: bounds.width, animating: cells.animatesChanges)
        let across = max(0, acrossRoom)
        let revision = cells.extents.revision
        if measuredAcross != across {
            cells.extents.reset()
            measured = [:]
            measuredAcross = across
        }
        if measuredRevision != measurements.revision {
            measured = [:]
            cells.extents.reset()
        }
        for (identity, item) in held {
            guard !item.departing, cells.position(of: identity) != nil else { continue }
            let margin = item.values.margin
            let proposal: Double? = axis == .vertical
                ? max(0, across - margin.left - margin.right) : nil
            let size: LayoutSize
            if let cached = measured[identity], cached.proposal == proposal {
                size = cached.size
            } else {
                size = item.size(offered: proposal)
                measured[identity] = (proposal, size)
                cells.measurements += 1
            }
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            cells.extents.measure(identity, extent: extent)
        }
        let cross = held.compactMap { identity, item -> Double? in
            guard !item.departing, let size = measured[identity]?.size else { return nil }
            return size.height + item.values.margin.top + item.values.margin.bottom
        }.max() ?? (cells.identities.isEmpty ? 0 : 44)
        if axis == .horizontal, naturalAcross != cross {
            naturalAcross = cross
            invalidateMeasurements()
        }
        if let origin = cells.correctedOrigin() { anchorTarget = origin }
        if cells.extents.revision != revision { invalidateMeasurements() }
        measuredRevision = measurements.revision
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let margin = item.values.margin
            let run = cells.offset(of: place)
            let extent = cells.extents.extent(of: identity)
            let frame: Rect
            if axis == .vertical {
                let open = across - margin.left - margin.right
                let expands = item.values.expandingAxes == .horizontal || item.values.expandingAxes == .both
                let width = Extent.of(
                    option: expands ? 3 : item.values.horizontal, stated: item.values.width,
                    natural: measured[identity]!.size.width,
                    available: open, minimum: item.values.minimumWidth,
                    maximum: item.values.maximumWidth)
                let x = padding.left + margin.left + Extent.start(
                    option: item.values.horizontal, extent: width, start: 0,
                    available: open,
                    guide: item.values.horizontalGuide?.slot == item.values.horizontal
                        ? item.values.horizontalGuide?.offset : nil)
                frame = Rect(x: x, y: run + margin.top, width: width,
                             height: extent - margin.top - margin.bottom)
            } else {
                let open = across - margin.top - margin.bottom
                let expands = item.values.expandingAxes == .vertical || item.values.expandingAxes == .both
                let height = Extent.of(
                    option: expands ? 3 : item.values.vertical, stated: item.values.height,
                    natural: measured[identity]!.size.height,
                    available: open, minimum: item.values.minimumHeight,
                    maximum: item.values.maximumHeight)
                let y = padding.top + margin.top + Extent.start(
                    option: item.values.vertical, extent: height, start: 0,
                    available: open,
                    guide: item.values.verticalGuide?.slot == item.values.vertical
                        ? item.values.verticalGuide?.offset : nil)
                frame = Rect(x: run + margin.left, y: y,
                             width: extent - margin.left - margin.right, height: height)
            }
            self.place(item, at: direction.places(
                frame,
                in: Rect(x: 0, y: 0, width: Double(bounds.width), height: Double(bounds.height))))
        }
    }

    override func tellWindow(_ span: Range<Double>) {
        cells.show(span)
    }
}

/// A lazy grid: the cells fill the tracks across its run, a run at a time -
/// a `LazyVGrid`'s run is a row of its columns, a `LazyHGrid`'s a column of
/// its rows.
final class UIKitLazyGridView: UIKitLazyView {
    /// The tracks across - `flowColumns` down a grid, `flowRows` across one.
    var tracks: [GridItem] = [] { didSet { if tracks != oldValue { columns = [] } } }

    /// The room between one run and the next.
    var runSpacing = 0.0 {
        didSet { if runSpacing != oldValue { cells.runs.spacing = runSpacing; forgetMeasurements() } }
    }

    /// The room between the tracks.
    var trackSpacing = 0.0 { didSet { if trackSpacing != oldValue { columns = [] } } }

    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.runs.padding = (head: axis == .vertical ? padding.top : padding.left,
                                       tail: axis == .vertical ? padding.bottom : padding.right)
                forgetMeasurements()
            }
        }
    }

    /// The track extents at the room now, kept until the room or they change;
    /// a changed count makes new runs, and their measures go.
    private var columns: [Double] = [] {
        didSet {
            if columns != oldValue {
                measured = [:]
                cells.runs.reset()
                forgetMeasurements()
            }
        }
    }

    /// The room across - inside the padding, the tracks take it all.
    private var acrossRoom: Double {
        axis == .vertical
            ? Double(bounds.width) - padding.left - padding.right
            : Double(bounds.height) - padding.top - padding.bottom
    }

    /// The cells a run holds.
    private var perRun: Int { max(1, columns.count) }

    /// The runs the cells make.
    private var runCount: Int { (cells.identities.count + perRun - 1) / perRun }

    /// As wide as offered and as long as the runs measure.
    override func contentSize(width: Double?) -> LayoutSize {
        let room = max(0, axis == .vertical
            ? (width.map { $0 - padding.left - padding.right } ?? acrossRoom)
            : acrossRoom)
        let proposed = LazyGridTracks.resolve(tracks, width: room, spacing: trackSpacing)
        let count = (cells.identities.count + max(1, proposed.count) - 1) / max(1, proposed.count)
        let total = cells.runs.total(count: count)
        return axis == .vertical
            ? LayoutSize(width: width ?? 0, height: total)
            : LayoutSize(width: total, height:
                LazyGridTracks.extents(proposed, width: room, spacing: trackSpacing).reduce(0, +)
                + Double(max(0, proposed.count - 1)) * trackSpacing + padding.top + padding.bottom)
    }

    override func arrange(in bounds: Rect) {
        places.begin(width: bounds.width, animating: cells.animatesChanges)
        let room = max(0, acrossRoom)
        let next = LazyGridTracks.extents(
            LazyGridTracks.resolve(tracks, width: room, spacing: trackSpacing),
            width: room, spacing: trackSpacing)
        if next != columns { columns = next }
        let widths = columns
        guard !widths.isEmpty else { return }
        let revision = cells.runs.revision
        if measuredRevision != measurements.revision {
            measured = [:]
            cells.runs.reset()
        }
        var runExtents: [Int: Double] = [:]
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let run = place / widths.count, track = place % widths.count
            let margin = item.values.margin
            let proposal: Double? = axis == .vertical
                ? max(0, widths[track] - margin.left - margin.right) : nil
            let size: LayoutSize
            if let cached = measured[identity], cached.proposal == proposal {
                size = cached.size
            } else {
                size = item.size(offered: proposal)
                measured[identity] = (proposal, size)
                cells.measurements += 1
            }
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            runExtents[run] = max(runExtents[run] ?? 0, extent)
        }
        for (run, extent) in runExtents { cells.runs.measure(run, extent: extent) }
        if let origin = cells.correctedOrigin(perRun: perRun, grid: true) { anchorTarget = origin }
        if cells.runs.revision != revision { invalidateMeasurements() }
        measuredRevision = measurements.revision
        var trackOrigins: [Double] = []
        var start = axis == .vertical ? padding.left : padding.top
        for width in widths {
            trackOrigins.append(start)
            start += width + trackSpacing
        }
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let run = place / widths.count, track = place % widths.count
            let margin = item.values.margin
            let origin = cells.runs.offset(of: run, count: runCount)
            let extent = cells.runs.extent(of: run)
            let frame: Rect
            if axis == .vertical {
                let open = widths[track] - margin.left - margin.right
                let expands = item.values.expandingAxes == .horizontal || item.values.expandingAxes == .both
                let width = Extent.of(
                    option: expands ? 3 : item.values.horizontal, stated: item.values.width,
                    natural: measured[identity]!.size.width,
                    available: max(0, open), minimum: item.values.minimumWidth,
                    maximum: item.values.maximumWidth)
                let x = trackOrigins[track] + margin.left + Extent.start(
                    option: item.values.horizontal, extent: width, start: 0,
                    available: max(0, open),
                    guide: item.values.horizontalGuide?.slot == item.values.horizontal
                        ? item.values.horizontalGuide?.offset : nil)
                frame = Rect(x: x, y: origin + margin.top, width: width,
                             height: extent - margin.top - margin.bottom)
            } else {
                let open = widths[track] - margin.top - margin.bottom
                let expands = item.values.expandingAxes == .vertical || item.values.expandingAxes == .both
                let height = Extent.of(
                    option: expands ? 3 : item.values.vertical, stated: item.values.height,
                    natural: measured[identity]!.size.height,
                    available: max(0, open), minimum: item.values.minimumHeight,
                    maximum: item.values.maximumHeight)
                let y = trackOrigins[track] + margin.top + Extent.start(
                    option: item.values.vertical, extent: height, start: 0,
                    available: max(0, open),
                    guide: item.values.verticalGuide?.slot == item.values.vertical
                        ? item.values.verticalGuide?.offset : nil)
                frame = Rect(x: origin + margin.left, y: y,
                             width: extent - margin.left - margin.right, height: height)
            }
            self.place(item, at: direction.places(
                frame,
                in: Rect(x: 0, y: 0, width: Double(bounds.width), height: Double(bounds.height))))
        }
    }

    override func tellWindow(_ span: Range<Double>) {
        cells.show(span, perRun: perRun, grid: true)
    }
}

private extension UIScrollView {
    /// The next scroller up the chain, or none.
    var nextScroller: UIScrollView? {
        var view = superview
        while let current = view {
            if let scroller = current as? UIScrollView { return scroller }
            view = current.superview
        }
        return nil
    }
}

private extension Axis {
    /// Whether a scroller of this axis can clip a lazy run of `axis`.
    func takes(_ axis: StackArithmetic.Axis) -> Bool {
        switch (self, axis) {
        case (.both, _), (.vertical, .vertical), (.horizontal, .horizontal): true
        default: false
        }
    }
}
#endif
