// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
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
class AppKitLazyView: AppKitTravellingLayout, AppKitMeasurementCaching {
    let measurements = MeasurementCache()
    /// The direction the children stack in.
    let axis: StackArithmetic.Axis

    /// The cells' bookkeeping: identities, mounted children, the runs' measures.
    let cells: LazyCells

    /// The children mounted now, by identity.
    private(set) var held: [String: AppKitLayoutItem] = [:]

    /// The clip whose bounds moving re-asks the window; the nearest scroller's.
    private weak var watching: NSView?

    /// Natural sizes survive scrolling; content invalidation or a changed
    /// cross-axis proposal clears only the measurements that can be stale.
    var measured: [String: (proposal: Double?, size: LayoutSize)] = [:]
    var measuredRevision = -1
    var measuredAcross: Double?
    var naturalAcross = 44.0
    var anchorTarget: Double?
    var geometryChanged = false

    /// A window change under way asks the run again once, not per notice.
    private var retellQueued = false
    private var fillingWindow = false

    init(axis: StackArithmetic.Axis, cells: LazyCells) {
        self.axis = axis
        self.cells = cells
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AppKitLazyView is created in code")
    }

    override var isFlipped: Bool { true }

    /// The mounted children, held by identity.
    func setItems(_ items: [(identity: String, item: AppKitLayoutItem)]) {
        let now = Dictionary(items.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        guard now.keys != held.keys || now.contains(where: {
            held[$0.key]?.view !== $0.value.view || held[$0.key]?.values != $0.value.values
        }) else { return }
        if now.contains(where: { identity, item in
            held[identity].map { $0.values != item.values } ?? false
        }) {
            // A retained child's layout changed (including a size animation). Old offscreen sizes
            // belong to the previous content, unlike a window merely gaining or losing neighbours.
            cells.extents.reset()
            cells.runs.reset()
        }
        for (identity, previous) in held {
            if now[identity]?.view !== previous.view || now[identity]?.values != previous.values {
                measured.removeValue(forKey: identity)
            }
        }
        for previous in held.values where !items.contains(where: { $0.item.view === previous.view }) {
            previous.view.removeFromSuperview()
        }
        for item in items where item.item.view.superview !== self {
            item.item.view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(item.item.view)
        }
        held = now
        needsLayout = true
    }

    /// The window the run shows - the view's own visible stretch along the
    /// run, or all of it where no clip narrows it.
    var span: Range<Double>? {
        guard !cells.identities.isEmpty else { return nil }
        let visible = visibleRect
        guard !visible.isEmpty else { return nil }
        return axis == .vertical
            ? Double(visible.minY)..<Double(visible.maxY)
            : Double(visible.minX)..<Double(visible.maxX)
    }

    /// Asks the tree for the children the window wants; each kind answers
    /// which places a span holds. No clip to narrow by means all of them.
    private func retell() {
        guard !retellQueued else { return }
        retellQueued = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.retellQueued = false
            self.watchClip()
            if self.geometryChanged {
                self.geometryChanged = false
                // A parent may already be in layout when its lazy child refines the estimate. Repeat
                // the invalidation after that pass, so AppKit cannot consume the parent's layout flag
                // while leaving its document at the old extent.
                self.invalidateMeasurements()
                self.measuredRevision = self.measurements.revision
            }
            // No clip to narrow by means all of it stands in view - a lazy
            // container outside any scroller builds every child.
            guard self.watching != nil else {
                if self.window != nil { self.cells.tellAll() }
                return
            }
            if self.anchorTarget != nil, let clip = self.watching as? NSClipView,
               let scroll = clip.superview as? NSScrollView {
                scroll.layoutSubtreeIfNeeded()
                if let origin = self.anchorTarget {
                    var target = clip.bounds.origin
                    let corner = self.convert(self.bounds.origin, to: clip)
                    if self.axis == .vertical { target.y = corner.y + origin }
                    else { target.x = corner.x + origin }
                    self.places.layoutMotion?.shift(mounts: self.held.values.map(\.mount),
                        by: Point(self.axis == .horizontal ? self.cells.anchorShift : 0,
                                  self.axis == .vertical ? self.cells.anchorShift : 0))
                    self.cells.anchorShift = 0
                    self.anchorTarget = nil
                    clip.scroll(to: target)
                    scroll.reflectScrolledClipView(clip)
                }
            }
            self.tellWindow(self.span ?? 0..<0)
        }
    }

    /// The places standing in `span`, as the kind's runs count them.
    func tellWindow(_ span: Range<Double>) {}

    /// Recomputes the places when the scroller's window moved.
    private func watchClip() {
        var scroll = enclosingScrollView
        var clip = scroll?.contentView
        while let current = scroll as? AppKitScrollView, !current.orientation.takes(axis) {
            scroll = current.enclosingScrollView
            clip = scroll?.contentView
        }
        guard clip !== watching else { return }
        if let watching {
            NotificationCenter.default.removeObserver(
                self, name: NSView.boundsDidChangeNotification, object: watching)
        }
        watching = clip
        clip?.postsBoundsChangedNotifications = true
        if let clip {
            NotificationCenter.default.addObserver(
                self, selector: #selector(windowMoved), name: NSView.boundsDidChangeNotification,
                object: clip)
        }
    }

    @objc private func windowMoved() {
        guard !fillingWindow else { return }
        guard (watching?.superview as? AppKitScrollView)?.isArrangingDocument != true,
              anchorTarget == nil else {
            retell()
            return
        }
        // Settle the newly measured window before AppKit draws the changed clip.
        // A shorter arriving row can expose another row in the same frame.
        fillingWindow = true
        defer { fillingWindow = false }
        var passes = 0
        repeat {
            tellWindow(span ?? 0..<0)
            enclosingScrollView?.layoutSubtreeIfNeeded()
            layoutSubtreeIfNeeded()
            if anchorTarget != nil, let clip = watching as? NSClipView,
               let scroll = clip.superview as? NSScrollView {
                scroll.layoutSubtreeIfNeeded()
                if let origin = anchorTarget {
                    let corner = convert(bounds.origin, to: clip)
                    var target = clip.bounds.origin
                    if axis == .vertical { target.y = corner.y + origin }
                    else { target.x = corner.x + origin }
                    places.layoutMotion?.shift(mounts: held.values.map(\.mount),
                        by: Point(axis == .horizontal ? cells.anchorShift : 0,
                                  axis == .vertical ? cells.anchorShift : 0))
                    cells.anchorShift = 0
                    anchorTarget = nil
                    clip.scroll(to: target)
                    scroll.reflectScrolledClipView(clip)
                }
            }
            passes += 1
            let revision = self is AppKitLazyGridView ? cells.runs.revision : cells.extents.revision
            if cells.window?.span == (span ?? 0..<0), cells.window?.revision == revision { break }
        } while passes < 8
        retell()
    }

    override func layout() {
        super.layout()
        retell()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        watchClip()
        retell()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        watchClip()
        retell()
    }
}

/// A lazy stack: one child a place.
final class AppKitLazyStackView: AppKitLazyView, AppKitWidthConstrainedMeasuring {
    var spacing: CGFloat = 0 {
        didSet { if spacing != oldValue { cells.extents.spacing = Double(spacing); invalidateMeasurements() } }
    }
    var padding = NSEdgeInsets() {
        didSet {
            if !NSEdgeInsetsEqual(padding, oldValue) {
                cells.extents.padding = (head: Double(axis == .vertical ? padding.top : padding.left), tail: Double(axis == .vertical ? padding.bottom : padding.right))
                invalidateMeasurements()
            }
        }
    }

    /// The room a child gets across - inside the padding.
    private var acrossRoom: CGFloat {
        axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom
    }

    /// As wide as offered and as long as the run measures.
    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        measurements.size(offering: availableWidth) {
            let total = CGFloat(self.cells.total)
            return self.axis == .vertical
                ? NSSize(width: availableWidth ?? 0, height: total)
                : NSSize(width: total, height: self.naturalAcross + Double(self.padding.top + self.padding.bottom))
        }
    }

    /// Every mounted child measures, is stood at its offset, and the window
    /// re-asks what the tree builds.
    override func layout() {
        super.layout()
        places.begin(width: Double(axis == .vertical ? bounds.width : bounds.height), animating: cells.animatesChanges)
        cells.animatesChanges = false
        let across = Double(max(0, acrossRoom))
        let revision = cells.extents.revision
        if measuredAcross != across {
            cells.extents.reset()
            measured = [:]
            measuredAcross = across
        }
        if measuredRevision != measurements.revision {
            measured = [:]
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
        // AppKit can lay the children out before the queued clip correction. Keep their
        // presentation in the current clip's coordinates until that correction is committed.
        let pendingShift = anchorTarget.map { $0 - (span?.lowerBound ?? $0) } ?? 0
        let committedShift = cells.anchorShift - pendingShift
        if committedShift != 0 {
            places.layoutMotion?.shift(mounts: held.values.map(\.mount),
                                       by: Point(axis == .horizontal ? committedShift : 0,
                                                 axis == .vertical ? committedShift : 0))
        }
        cells.anchorShift = pendingShift
        if cells.extents.revision != revision {
            geometryChanged = true
            invalidateMeasurements()
        }
        measuredRevision = measurements.revision
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let margin = item.values.margin
            let run = cells.offset(of: place)
            let extent = cells.extents.extent(of: identity)
            let frame: NSRect
            if axis == .vertical {
                let open = across - margin.left - margin.right
                let width = Extent.of(
                    option: item.values.horizontal, stated: item.values.width,
                    natural: measured[identity]!.size.width,
                    available: open, minimum: item.values.minimumWidth,
                    maximum: item.values.maximumWidth)
                let x = Double(padding.left) + margin.left + Extent.start(
                    option: item.values.horizontal, extent: width, start: 0,
                    available: open,
                    guide: item.values.horizontalGuide?.slot == item.values.horizontal
                        ? item.values.horizontalGuide?.offset : nil)
                frame = NSRect(x: x, y: run + margin.top, width: width,
                               height: extent - margin.top - margin.bottom)
            } else {
                let open = across - margin.top - margin.bottom
                let height = Extent.of(
                    option: item.values.vertical, stated: item.values.height,
                    natural: measured[identity]!.size.height,
                    available: open, minimum: item.values.minimumHeight,
                    maximum: item.values.maximumHeight)
                let y = Double(padding.top) + margin.top + Extent.start(
                    option: item.values.vertical, extent: height, start: 0,
                    available: open,
                    guide: item.values.verticalGuide?.slot == item.values.vertical
                        ? item.values.verticalGuide?.offset : nil)
                frame = NSRect(x: run + margin.left, y: y,
                               width: extent - margin.left - margin.right, height: height)
            }
            var placed = item
            if cells.inserting.remove(identity) == nil { placed.fadeIn = nil }
            var presentation = direction.places(frame.placed, in: bounds.placed)
            if axis == .vertical { presentation.y -= cells.anchorShift }
            else { presentation.x -= cells.anchorShift }
            self.place(placed, at: NSRect(placed: presentation))
        }
    }

    override func tellWindow(_ span: Range<Double>) {
        cells.show(span)
    }
}

/// A lazy grid: the cells fill the tracks across its run, a run at a time -
/// a `LazyVGrid`'s run is a row of its columns, a `LazyHGrid`'s a column of
/// its rows.
final class AppKitLazyGridView: AppKitLazyView, AppKitWidthConstrainedMeasuring {

    /// The tracks across - `flowColumns` down a grid, `flowRows` across one.
    var tracks: [GridItem] = [] { didSet { if tracks != oldValue { columns = [] } } }

    /// The room between one run and the next.
    var runSpacing: CGFloat = 0 {
        didSet { if runSpacing != oldValue { cells.runs.spacing = Double(runSpacing); invalidateMeasurements() } }
    }

    /// The room between the tracks.
    var trackSpacing: CGFloat = 0 { didSet { if trackSpacing != oldValue { columns = [] } } }

    var padding = NSEdgeInsets() {
        didSet {
            if !NSEdgeInsetsEqual(padding, oldValue) {
                cells.runs.padding = (head: Double(axis == .vertical ? padding.top : padding.left), tail: Double(axis == .vertical ? padding.bottom : padding.right))
                invalidateMeasurements()
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
                invalidateMeasurements()
            }
        }
    }

    /// The room across - inside the padding, the tracks take it all.
    private var acrossRoom: CGFloat {
        axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom
    }

    /// The cells a run holds.
    private var perRun: Int { max(1, columns.count) }

    /// The runs the cells make.
    private var runCount: Int { (cells.identities.count + perRun - 1) / perRun }

    /// As wide as offered and as long as the runs measure.
    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        return measurements.size(offering: availableWidth) {
            let room = max(0, self.axis == .vertical
                ? (availableWidth.map { Double($0 - self.padding.left - self.padding.right) } ?? Double(self.acrossRoom))
                : Double(self.acrossRoom))
            let tracks = LazyGridTracks.resolve(self.tracks, width: room, spacing: Double(self.trackSpacing))
            let count = (self.cells.identities.count + max(1, tracks.count) - 1) / max(1, tracks.count)
            let total = CGFloat(self.cells.runs.total(count: count))
            return self.axis == .vertical
                ? NSSize(width: availableWidth ?? 0, height: total)
                : NSSize(width: total, height:
                    LazyGridTracks.extents(tracks, width: room, spacing: Double(self.trackSpacing)).reduce(0, +)
                    + Double(max(0, tracks.count - 1)) * Double(self.trackSpacing)
                    + Double(self.padding.top + self.padding.bottom))
        }
    }

    override func layout() {
        super.layout()
        places.begin(width: Double(axis == .vertical ? bounds.width : bounds.height), animating: cells.animatesChanges)
        cells.animatesChanges = false
        let room = max(0, Double(acrossRoom))
        let next = LazyGridTracks.extents(
            LazyGridTracks.resolve(tracks, width: room, spacing: Double(trackSpacing)),
            width: room, spacing: Double(trackSpacing))
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
        // AppKit can lay the children out before the queued clip correction. Keep their
        // presentation in the current clip's coordinates until that correction is committed.
        let pendingShift = anchorTarget.map { $0 - (span?.lowerBound ?? $0) } ?? 0
        let committedShift = cells.anchorShift - pendingShift
        if committedShift != 0 {
            places.layoutMotion?.shift(mounts: held.values.map(\.mount),
                                       by: Point(axis == .horizontal ? committedShift : 0,
                                                 axis == .vertical ? committedShift : 0))
        }
        cells.anchorShift = pendingShift
        if cells.runs.revision != revision {
            geometryChanged = true
            invalidateMeasurements()
        }
        measuredRevision = measurements.revision
        var trackOrigins: [Double] = []
        var start = axis == .vertical ? Double(padding.left) : Double(padding.top)
        for width in widths {
            trackOrigins.append(start)
            start += width + Double(trackSpacing)
        }
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let run = place / widths.count, track = place % widths.count
            let margin = item.values.margin
            let origin = cells.runs.offset(of: run, count: runCount)
            let extent = cells.runs.extent(of: run)
            let frame: NSRect
            if axis == .vertical {
                let open = widths[track] - margin.left - margin.right
                let width = Extent.of(
                    option: item.values.horizontal, stated: item.values.width,
                    natural: measured[identity]!.size.width,
                    available: max(0, open), minimum: item.values.minimumWidth,
                    maximum: item.values.maximumWidth)
                let x = trackOrigins[track] + margin.left + Extent.start(
                    option: item.values.horizontal, extent: width, start: 0,
                    available: max(0, open),
                    guide: item.values.horizontalGuide?.slot == item.values.horizontal
                        ? item.values.horizontalGuide?.offset : nil)
                frame = NSRect(x: x, y: origin + margin.top, width: width,
                               height: extent - margin.top - margin.bottom)
            } else {
                let open = widths[track] - margin.top - margin.bottom
                let height = Extent.of(
                    option: item.values.vertical, stated: item.values.height,
                    natural: measured[identity]!.size.height,
                    available: max(0, open), minimum: item.values.minimumHeight,
                    maximum: item.values.maximumHeight)
                let y = trackOrigins[track] + margin.top + Extent.start(
                    option: item.values.vertical, extent: height, start: 0,
                    available: max(0, open),
                    guide: item.values.verticalGuide?.slot == item.values.vertical
                        ? item.values.verticalGuide?.offset : nil)
                frame = NSRect(x: origin + margin.left, y: y,
                               width: extent - margin.left - margin.right, height: height)
            }
            var placed = item
            if cells.inserting.remove(identity) == nil { placed.fadeIn = nil }
            var presentation = direction.places(frame.placed, in: bounds.placed)
            if axis == .vertical { presentation.y -= cells.anchorShift }
            else { presentation.x -= cells.anchorShift }
            self.place(placed, at: NSRect(placed: presentation))
        }
    }

    override func tellWindow(_ span: Range<Double>) {
        cells.show(span, perRun: perRun, grid: true)
    }
}

private extension Axis {
    /// Whether a scroller of this axis can clip a lazy run of `axis` - a
    /// vertical run answers a vertical scroller's window, or one going both
    /// ways.
    func takes(_ axis: StackArithmetic.Axis) -> Bool {
        switch (self, axis) {
        case (.both, _), (.vertical, .vertical), (.horizontal, .horizontal): true
        default: false
        }
    }
}

#endif
