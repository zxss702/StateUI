// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost
import CSwiftOmniUIWinUI

/// What a lazy container's view does alike: it keeps the children in view
/// mounted - and only those - telling the tree which identities the window
/// wants built, and standing each at the offset its measure says.
///
/// The run's length is the estimates' before the children exist, so the
/// scroll room answers at once; a child's own measure lands as it mounts and
/// shifts the places after it, the way a scroller of estimated rows does.
/// Design: docs/design/host/items.md#the-view-moving
@MainActor
class WinUILazyView: WinUITravellingLayout {
    /// The direction the children stack in.
    let axis: StackArithmetic.Axis

    /// The cells' bookkeeping: identities, mounted children, the runs' measures.
    let cells: LazyCells

    /// The children mounted now, by identity.
    private(set) var mounted: [String: WinUILayoutItem] = [:]

    /// The scroller whose window the run answers, and the ear it hears it by.
    private weak var watching: WinUIScrollView?
    private var ear: WinUIScrollEar?

    /// Natural sizes survive scrolling; content invalidation or a changed
    /// cross-axis proposal clears only the measurements that can be stale.
    var measured: [String: (proposal: Double?, size: LayoutSize)] = [:]
    /// Only actual placements adopt the child layout revisions measured with these sizes.
    var measuredLayoutRevisions: [String: (view: Int64, revision: Int)] = [:]
    var measuredRevision = -1
    var measuredAcross: Double?
    var naturalAcross = 44.0
    var geometryChanged = false
    var measuredExtent = 0.0

    /// A window change under way asks the run again once, not per notice.
    private var retellQueued = false
    /// Physical clipping within the native scroll viewport, independent of its requested offset.
    private var effectiveViewport: Rect?
    private var lastTargetViewport: Rect?
    #if DEBUG
    private static var traced = 0
    #endif

    init(axis: StackArithmetic.Axis, cells: LazyCells) {
        self.axis = axis
        self.cells = cells
        super.init()
        swiftomniui_winui_panel_watch_viewport(handle, true)
    }

    /// The mounted children, held by identity.
    func setItems(_ items: [(identity: String, item: WinUILayoutItem)]) {
        let now = Dictionary(items.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        guard now.keys != mounted.keys || now.contains(where: {
            mounted[$0.key]?.view !== $0.value.view || mounted[$0.key]?.values != $0.value.values
        }) else { return }
        if now.contains(where: { identity, item in
            mounted[identity].map { $0.values != item.values } ?? false
        }) {
            cells.extents.reset()
            cells.runs.reset()
        }
        for (identity, previous) in mounted {
            if now[identity]?.view !== previous.view {
                swiftomniui_winui_scroller_anchor(previous.view.handle, false)
            }
            if now[identity]?.view !== previous.view || now[identity]?.values != previous.values {
                measured.removeValue(forKey: identity)
                measuredLayoutRevisions.removeValue(forKey: identity)
            }
        }
        mounted = now
        for item in items {
            item.item.view.placingLayout = self
            swiftomniui_winui_scroller_anchor(item.item.view.handle, !item.item.departing)
        }
        setChildren(items.map(\.item.view))
        invalidateMeasurements()
        measuredRevision = measurements.revision
    }

    /// The nearest scroller clipping this run on its own axis, found up the
    /// placing layouts through the document it holds, or none: a scroller
    /// turned the other way narrows nothing of this run's window.
    private var clip: WinUIScrollView? {
        var layout: WinUILayoutView? = placingLayout
        while let current = layout {
            if let document = current as? WinUIScrollDocument {
                guard let scroll = document.scrollView else { break }
                if scroll.orientation.takes(axis) { return scroll }
                layout = scroll.placingLayout
            } else {
                layout = current.placingLayout
            }
        }
        return nil
    }

    /// Realization follows the input offset; the document's displayed offset is committed after arrangement.
    /// Reading the compensated effective viewport here would keep asking for the previous displayed window.
    private var viewport: Rect? {
        guard let scroll = clip else { return nil }
        var values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        swiftomniui_winui_scroller_viewport(scroll.scroller.handle, handle, &values)
        // The document displays the last arranged offset. The next realization must follow input,
        // independently of that compensated visual transform, or the viewport would feed back on itself.
        if let next = scroll.scroller.nextOffset {
            let now = scroll.scroller.standing.offset
            values[0] += next.x - now.x
            values[1] += next.y - now.y
        }
        guard let clipped = effectiveViewport else {
            return Rect(x: values[0], y: values[1], width: values[2], height: values[3])
        }
        let x = max(0, clipped.x), y = max(0, clipped.y)
        let right = min(values[2], clipped.x + clipped.width)
        let bottom = min(values[3], clipped.y + clipped.height)
        return Rect(x: values[0] + x, y: values[1] + y,
                    width: max(0, right - x), height: max(0, bottom - y))
    }

    /// A viewport notification requests layout. The visual tree changes inside Measure, where XAML can
    /// measure and arrange the complete new window before composing it, never midway through a notification.
    func viewportChanged(_ rect: Rect, effective: Bool = true) {
        guard let scroll = clip else { return }
        if effective {
            var values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
            swiftomniui_winui_scroller_viewport(scroll.scroller.handle, handle, &values)
            effectiveViewport = Rect(x: rect.x + values[4], y: rect.y + values[5],
                                     width: rect.width, height: rect.height)
        }
        guard let target = viewport else { return }
        #if DEBUG
        if Self.traced < 100 {
            Self.traced += 1
            print("LAZY VIEWPORT view=\(number) axis=\(axis) target=\(target) span=\(String(describing: span)) built=\(cells.built) revision=\(measurements.revision)")
        }
        #endif
        let grid = self is WinUILazyGridView
        let revision = grid ? cells.runs.revision : cells.extents.revision
        guard lastTargetViewport != target || cells.window?.span != (span ?? 0..<0)
            || cells.window?.revision != revision else { return }
        let previous = lastTargetViewport
        lastTargetViewport = target
        if !geometryChanged, !cells.animatesChanges,
           measuredRevision == measurements.revision, cells.window?.revision == revision,
           previous?.width == target.width, previous?.height == target.height, let span {
            let perRun = cells.window?.perRun ?? 1
            let wanted = grid
                ? cells.runs.places(in: span, overscan: 0, count: (cells.identities.count + perRun - 1) / perRun)
                : cells.places(in: span, overscan: 0)
            let lower = min(cells.identities.count, max(0, wanted.lowerBound - 1) * perRun)
            let upper = min(cells.identities.count, (wanted.upperBound + 1) * perRun)
            if !wanted.isEmpty, (lower..<upper) == cells.built {
                cells.show(span, perRun: perRun, grid: grid)
                // The document arranges all lazy siblings together before advancing its visual offset.
                // Its arithmetic remains valid while every mounted identity and cross proposal is unchanged.
                var parent = placingLayout
                while let layout = parent {
                    if let document = layout as? WinUIScrollDocument, document.scrollView === scroll {
                        document.invalidateArrange()
                        return
                    }
                    parent = (layout as? WinUIScrollDocument)?.scrollView?.placingLayout ?? layout.placingLayout
                }
            }
        }
        // These panels report zero DesiredSize to their native parents. Marking this panel alone
        // can leave the placing chain's cached arithmetic intact and skip its realization entirely.
        invalidateMeasurements()
        var parent = placingLayout
        while let layout = parent {
            layout.forgetMeasurements()
            layout.invalidateMeasure()
            parent = (layout as? WinUIScrollDocument)?.scrollView ?? layout.placingLayout
        }
    }

    /// The window the run shows, clipped to its document extent.
    var span: Range<Double>? {
        guard !cells.identities.isEmpty, let viewport else { return nil }
        let start = axis == .vertical ? viewport.y : viewport.x
        let room = axis == .vertical ? viewport.height : viewport.width
        let own = axis == .vertical
            ? (placed?.height ?? laidOutFrame.height) : (placed?.width ?? laidOutFrame.width)
        let low = max(0, start), high = min(own, start + room)
        guard high > low else { return nil }
        return low..<high
    }

    /// Asks the tree for the children the window wants; each kind answers
    /// which places a span holds. No scroller to narrow by means all of them.
    /// One retell a pass, once the layout under way is over.
    private func retell() {
        guard !retellQueued else { return }
        retellQueued = true
        WinUIDoorbell.afterPass { [weak self] in
            guard let self else { return }
            self.retellQueued = false
            self.watchClip()
            if self.geometryChanged {
                self.geometryChanged = false
                self.invalidateMeasurements()
                self.measuredRevision = self.measurements.revision
                // SwiftOmniUI panels report zero DesiredSize to their native parents. Native invalidation
                // alone therefore cannot tell a cached scroll document that the estimated extent grew
                // or shrank. Invalidate the actual placing chain, including the internal document.
                var parent = self.placingLayout
                while let layout = parent {
                    layout.forgetMeasurements()
                    layout.invalidateMeasure()
                    parent = (layout as? WinUIScrollDocument)?.scrollView ?? layout.placingLayout
                }
            }
            // No clip to narrow by means all of it stands in view - a lazy
            // container outside any scroller builds every child.
            guard self.watching != nil else {
                self.cells.tellAll()
                return
            }
            let revision = self is WinUILazyGridView ? self.cells.runs.revision : self.cells.extents.revision
            if self.cells.window?.span != (self.span ?? 0..<0) || self.cells.window?.revision != revision {
                if let viewport = self.viewport { self.viewportChanged(viewport, effective: false) }
            }
        }
    }

    /// The places standing in `span`, as the kind's runs count them.
    func tellWindow(_ span: Range<Double>) {}

    /// Recomputes the places when the scroller's window moved.
    private func watchClip() {
        let scroll = clip
        guard scroll !== watching else { return }
        ear?.owner = nil
        watching = scroll
        effectiveViewport = nil
        lastTargetViewport = nil
        let ear = WinUIScrollEar(owner: self) { [weak self] in
            guard let self, let viewport = self.viewport else { return }
            self.viewportChanged(viewport, effective: false)
        }
        self.ear = ear
        scroll?.scroller.ears.append(ear)
    }

    /// Every pass re-asks the window: a place in the air lands in the one it
    /// asks for, and a move of the scroller's brings one.
    override func arrange(in bounds: Rect) {
        places.begin(width: axis == .vertical ? bounds.width : bounds.height, animating: cells.animatesChanges)
        cells.animatesChanges = false
        if cells.anchorShift != 0 {
            places.layoutMotion?.shift(mounts: mounted.values.map(\.mount),
                                       by: Point(axis == .horizontal ? cells.anchorShift : 0,
                                                 axis == .vertical ? cells.anchorShift : 0))
            cells.anchorShift = 0
        }
        retell()
    }

    /// Measuring again, the window is re-asked: a new pass is a new chance
    /// for the places the run holds.
    override func measure(width: Double, height: Double) -> LayoutSize {
        #if DEBUG
        if Self.traced < 100 { Self.traced += 1; print("LAZY MEASURE view=\(number) axis=\(axis) width=\(width) arranging=\(WinUIView.arranging) span=\(String(describing: span)) built=\(cells.built)") }
        #endif
        if WinUIView.arranging == 0 {
            watchClip()
            if watching != nil { tellWindow(span ?? 0..<0) }
        }
        retell()
        return super.measure(width: width, height: height)
    }

    override func detach() {
        super.detach()
        swiftomniui_winui_panel_watch_viewport(handle, false)
        effectiveViewport = nil
        lastTargetViewport = nil
        ear?.owner = nil
        ear = nil
        watching = nil
    }
}

/// A lazy stack: one child a place.
final class WinUILazyStackView: WinUILazyView {
    /// Each proposal is measured separately; arrangement adopts only its actual allocation.
    private var prepared: [Double?: (measured: [String: (proposal: Double?, size: LayoutSize)],
        layoutRevisions: [String: (view: Int64, revision: Int)], extents: LazyExtents, naturalAcross: Double, revision: Int)] = [:]
    private var preparing = false

    /// The room between two children.
    var spacing = 0.0 {
        didSet { if spacing != oldValue { cells.extents.spacing = spacing; invalidateMeasurements() } }
    }

    /// The room inside the stack's own edge.
    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.extents.padding = (head: axis == .vertical ? padding.top : padding.left,
                                       tail: axis == .vertical ? padding.bottom : padding.right)
                invalidateMeasurements()
            }
        }
    }

    /// Measure prepares the proposal without changing the extents or anchor currently displayed.
    override func contentSize(width: Double?) -> LayoutSize {
        let width = width.map { Double(Float($0)) }
        let across = axis == .vertical
            ? width.map { max(0, $0 - padding.left - padding.right) } : nil
        var extents = cells.extents
        var acrossSize = naturalAcross
        if WinUIView.arranging == 0 {
            if measuredAcross != across {
                extents.reset()
            }
            var sizes: [String: (proposal: Double?, size: LayoutSize)] = [:]
            var layoutRevisions: [String: (view: Int64, revision: Int)] = [:]
            let knownSizes = prepared[across]?.measured ?? measured
            let knownRevisions = prepared[across]?.layoutRevisions ?? measuredLayoutRevisions
            for (identity, item) in mounted {
                guard !item.departing, cells.position(of: identity) != nil else { continue }
                let margin = item.values.margin
                let proposal = across.map { Double(Float(max(0, $0 - margin.left - margin.right))) }
                let layout = item.view as? WinUILayoutView
                let size: LayoutSize
                if let cached = knownSizes[identity], cached.proposal == proposal,
                   let layout, knownRevisions[identity]?.view == layout.number,
                   knownRevisions[identity]?.revision == layout.measurementRevision {
                    size = cached.size
                } else {
                    #if DEBUG
                    if cells.measurements < 130 { print("LAZY MISS view=\(number) id=\(identity) proposal=\(String(describing: proposal)) cached=\(String(describing: knownSizes[identity]?.proposal)) rev=\(String(describing: knownRevisions[identity])) actual=\(String(describing: layout?.measurementRevision))") }
                    #endif
                    size = item.size(offered: proposal)
                    cells.measurements += 1
                }
                if let layout { layoutRevisions[identity] = (layout.number, layout.measurementRevision) }
                sizes[identity] = (proposal, size)
                let extent = axis == .vertical
                    ? size.height + margin.top + margin.bottom
                    : size.width + margin.left + margin.right
                extents.measure(identity, extent: extent)
            }
            acrossSize = mounted.compactMap { identity, item -> Double? in
                guard !item.departing, let size = sizes[identity]?.size else { return nil }
                let margin = item.values.margin
                return axis == .vertical
                    ? size.width + margin.left + margin.right : size.height + margin.top + margin.bottom
            }.max() ?? (cells.identities.isEmpty ? 0 : 44)
            if prepared.count == 8, prepared[across] == nil, let oldest = prepared.keys.first {
                prepared.removeValue(forKey: oldest)
            }
            prepared[across] = (sizes, layoutRevisions, extents, acrossSize, measurements.revision)
        }
        let total = extents.total(in: cells.identities)
        return axis == .vertical
            ? LayoutSize(width: width ?? acrossSize + padding.left + padding.right, height: total)
            : LayoutSize(width: total, height: acrossSize + padding.top + padding.bottom)
    }

    /// Commit an actual native measurement before XAML applies its new scroll extent.
    override func measure(width: Double, height: Double) -> LayoutSize {
        let size = super.measure(width: width, height: height)
        let proposal = axis == .vertical ? max(0, width - padding.left - padding.right) : nil
        if WinUIView.arranging == 0, let standsAt, Double(Float(standsAt)) == width,
           let ready = prepared[proposal], ready.revision == measurements.revision {
            let revision = cells.extents.revision
            measured = ready.measured
            measuredLayoutRevisions = ready.layoutRevisions
            cells.extents = ready.extents
            if naturalAcross != ready.naturalAcross { geometryChanged = true }
            naturalAcross = ready.naturalAcross
            measuredAcross = proposal
            _ = cells.correctedOrigin()
            if cells.extents.revision != revision || cells.total != measuredExtent { geometryChanged = true }
            measuredExtent = cells.total
            measuredRevision = measurements.revision
        }
        return size
    }

    /// Place only measurements completed before this arrangement. Native subtrees are never measured here.
    override func arrange(in bounds: Rect) {
        let across = max(0, axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom)
        let proposal = axis == .vertical ? across : nil
        if let ready = prepared[proposal], ready.revision == measurements.revision {
            let revision = cells.extents.revision
            measured = ready.measured
            measuredLayoutRevisions = ready.layoutRevisions
            cells.extents = ready.extents
            if naturalAcross != ready.naturalAcross { geometryChanged = true }
            naturalAcross = ready.naturalAcross
            measuredAcross = proposal
            _ = cells.correctedOrigin()
            let total = cells.total
            if cells.extents.revision != revision || total != measuredExtent { geometryChanged = true }
            measuredExtent = total
            measuredRevision = measurements.revision
        } else {
            if !preparing {
                preparing = true
                WinUIDoorbell.afterPass { [weak self] in
                    guard let self else { return }
                    self.preparing = false
                    self.invalidateMeasure()
                    _ = self.measure(width: self.standsAt ?? bounds.width, height: nil)
                    var parent = self.placingLayout
                    while let layout = parent {
                        layout.forgetMeasurements()
                        layout.invalidateMeasure()
                        parent = (layout as? WinUIScrollDocument)?.scrollView ?? layout.placingLayout
                    }
                }
            }
            return
        }
        super.arrange(in: bounds)
        for (identity, item) in mounted {
            let margin = item.values.margin
            guard let place = cells.position(of: identity), let size = measured[identity]?.size else { continue }
            let extent = cells.extents.extent(of: identity)
            let run = cells.offset(of: place)
            let frame: Rect
            if axis == .vertical {
                let open = across - margin.left - margin.right
                let expands = item.values.expandingAxes == .horizontal || item.values.expandingAxes == .both
                let width = Extent.of(
                    option: expands ? 3 : item.values.horizontal, stated: item.values.width,
                    natural: size.width,
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
                    natural: size.height,
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
            var placed = item
            if cells.inserting.remove(identity) == nil { placed.fadeIn = nil }
            self.place(placed, at: direction.places(frame, in: bounds))
        }
    }

    override func tellWindow(_ span: Range<Double>) {
        cells.show(span)
    }
}

/// A lazy grid: the cells fill the tracks across its run, a run at a time -
/// a `LazyVGrid`'s run is a row of its columns, a `LazyHGrid`'s a column of
/// its rows.
final class WinUILazyGridView: WinUILazyView {
    /// The tracks across - `flowColumns` down a grid, `flowRows` across one.
    var tracks: [GridItem] = [] {
        didSet {
            if tracks != oldValue {
                columns = []
                invalidateMeasurements()
            }
        }
    }

    /// The room between one run and the next.
    var runSpacing = 0.0 {
        didSet { if runSpacing != oldValue { cells.runs.spacing = runSpacing; invalidateMeasurements() } }
    }

    /// Where the tracks stand together across the grid.
    var trackAlignment: AxisAlignment = .center {
        didSet { if trackAlignment != oldValue { invalidateMeasurements() } }
    }
    /// The room between the tracks.
    var trackSpacing = 0.0 {
        didSet {
            if trackSpacing != oldValue {
                columns = []
                invalidateMeasurements()
            }
        }
    }

    /// The room inside the grid's own edge.
    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.runs.padding = (head: axis == .vertical ? padding.top : padding.left,
                                       tail: axis == .vertical ? padding.bottom : padding.right)
                invalidateMeasurements()
            }
        }
    }

    /// The track extents at the room now, kept until the room or they change;
    /// a changed count makes new runs, and their measures go.
    private var columns: [Double] = []

    /// The room across - inside the padding, the tracks take it all.
    private var acrossRoom = 0.0

    /// Proposals prepare geometry without replacing the tracks currently displayed.
    /// Arrange adopts the result for its actual allocation, including when the size cache answered it.
    private var prepared: [Double: (columns: [Double],
        measured: [String: (proposal: Double?, size: LayoutSize)], layoutRevisions: [String: (view: Int64, revision: Int)],
        runs: LazyRunExtents, revision: Int)] = [:]
    private var preparingRoom: Double?

    /// The cells a run holds.
    private var perRun: Int { max(1, columns.count) }

    /// The runs the cells make.
    private var runCount: Int { (cells.identities.count + perRun - 1) / perRun }

    /// Measure prepares each proposal independently; only an actual allocation changes the displayed runs.
    override func contentSize(width: Double?) -> LayoutSize {
        let width = width.map { Double(Float($0)) }
        let room = max(0, axis == .vertical
            ? ((width ?? standsAt).map { $0 - padding.left - padding.right } ?? acrossRoom)
            : acrossRoom)
        let proposed = LazyGridTracks.resolve(tracks, width: room, spacing: trackSpacing)
        let widths = LazyGridTracks.extents(proposed, width: room, spacing: trackSpacing)
        var runs = cells.runs
        if WinUIView.arranging == 0 {
            if widths != columns { runs.reset() }
            var sizes: [String: (proposal: Double?, size: LayoutSize)] = [:]
            var layoutRevisions: [String: (view: Int64, revision: Int)] = [:]
            let knownSizes = prepared[room]?.measured ?? measured
            let knownRevisions = prepared[room]?.layoutRevisions ?? measuredLayoutRevisions
            var runExtents: [Int: Double] = [:]
            for (identity, item) in mounted {
                guard !item.departing, let place = cells.position(of: identity), !widths.isEmpty else { continue }
                let run = place / widths.count, track = place % widths.count
                let margin = item.values.margin
                let proposal: Double? = axis == .vertical
                    ? Double(Float(max(0, widths[track] - margin.left - margin.right))) : nil
                let layout = item.view as? WinUILayoutView
                let size: LayoutSize
                if let cached = knownSizes[identity], cached.proposal == proposal,
                   let layout, knownRevisions[identity]?.view == layout.number,
                   knownRevisions[identity]?.revision == layout.measurementRevision {
                    size = cached.size
                } else {
                    #if DEBUG
                    if cells.measurements < 130 { print("LAZY GRID MISS view=\(number) id=\(identity) proposal=\(String(describing: proposal)) cached=\(String(describing: knownSizes[identity]?.proposal)) rev=\(String(describing: knownRevisions[identity])) actual=\(String(describing: layout?.measurementRevision))") }
                    #endif
                    size = item.size(offered: proposal)
                    cells.measurements += 1
                }
                if let layout { layoutRevisions[identity] = (layout.number, layout.measurementRevision) }
                sizes[identity] = (proposal, size)
                let extent = axis == .vertical
                    ? size.height + margin.top + margin.bottom
                    : size.width + margin.left + margin.right
                runExtents[run] = max(runExtents[run] ?? 0, extent)
            }
            for (run, extent) in runExtents { runs.measure(run, extent: extent) }
            if prepared.count == 8, prepared[room] == nil, let oldest = prepared.keys.first {
                prepared.removeValue(forKey: oldest)
            }
            prepared[room] = (widths, sizes, layoutRevisions, runs, measurements.revision)
        }
        let count = (cells.identities.count + max(1, proposed.count) - 1) / max(1, proposed.count)
        let total = runs.total(count: count)
        return axis == .vertical
            ? LayoutSize(width: width ?? 0, height: total)
            : LayoutSize(width: total, height: widths.reduce(0, +)
                + Double(max(widths.count - 1, 0)) * trackSpacing + padding.top + padding.bottom)
    }

    /// Native extents and window arithmetic adopt the same actual measurement before clamping.
    override func measure(width: Double, height: Double) -> LayoutSize {
        let size = super.measure(width: width, height: height)
        let room = axis == .vertical ? max(0, width - padding.left - padding.right) : acrossRoom
        if WinUIView.arranging == 0, let standsAt, Double(Float(standsAt)) == width,
           let ready = prepared[room], ready.revision == measurements.revision {
            let revision = cells.runs.revision
            if columns != ready.columns { geometryChanged = true }
            columns = ready.columns
            measured = ready.measured
            measuredLayoutRevisions = ready.layoutRevisions
            cells.runs = ready.runs
            _ = cells.correctedOrigin(perRun: perRun, grid: true)
            let total = cells.runs.total(count: runCount)
            if cells.runs.revision != revision || total != measuredExtent { geometryChanged = true }
            measuredExtent = total
            measuredRevision = measurements.revision
        }
        return size
    }

    override func arrange(in bounds: Rect) {
        acrossRoom = max(0, axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom)
        if let ready = prepared[acrossRoom], ready.revision == measurements.revision {
            let revision = cells.runs.revision
            if columns != ready.columns { geometryChanged = true }
            columns = ready.columns
            measured = ready.measured
            measuredLayoutRevisions = ready.layoutRevisions
            cells.runs = ready.runs
            _ = cells.correctedOrigin(perRun: perRun, grid: true)
            let total = cells.runs.total(count: runCount)
            if cells.runs.revision != revision || total != measuredExtent { geometryChanged = true }
            measuredExtent = total
            measuredRevision = measurements.revision
        } else {
            if preparingRoom != acrossRoom {
                preparingRoom = acrossRoom
                WinUIDoorbell.afterPass { [weak self] in
                    guard let self else { return }
                    self.preparingRoom = nil
                    self.invalidateMeasure()
                    _ = self.measure(width: self.standsAt ?? bounds.width, height: nil)
                    var parent = self.placingLayout
                    while let layout = parent {
                        layout.forgetMeasurements()
                        layout.invalidateMeasure()
                        parent = (layout as? WinUIScrollDocument)?.scrollView ?? layout.placingLayout
                    }
                }
            }
            return
        }
        super.arrange(in: bounds)
        let widths = columns
        guard !widths.isEmpty else { return }
        var trackOrigins: [Double] = []
        let extent = widths.reduce(0, +) + Double(max(widths.count - 1, 0)) * trackSpacing
        var start = Extent.start(option: trackAlignment.rawValue, extent: extent,
                                 start: axis == .vertical ? padding.left : padding.top,
                                 available: acrossRoom)
        for width in widths {
            trackOrigins.append(start)
            start += width + trackSpacing
        }

        for (identity, item) in mounted {
            guard let place = cells.position(of: identity) else { continue }
            let run = place / widths.count, track = place % widths.count
            let margin = item.values.margin
            guard let size = measured[identity]?.size else { continue }
            let origin = cells.runs.offset(of: run, count: runCount)
            let runExtent = cells.runs.extent(of: run)
            let frame: Rect
            if axis == .vertical {
                let open = widths[track] - margin.left - margin.right
                let expands = item.values.expandingAxes == .horizontal || item.values.expandingAxes == .both
                let width = Extent.of(
                    option: expands ? 3 : item.values.horizontal, stated: item.values.width,
                    natural: size.width,
                    available: max(0, open), minimum: item.values.minimumWidth,
                    maximum: item.values.maximumWidth)
                let x = trackOrigins[track] + margin.left + Extent.start(
                    option: item.values.horizontal, extent: width, start: 0,
                    available: max(0, open),
                    guide: item.values.horizontalGuide?.slot == item.values.horizontal
                        ? item.values.horizontalGuide?.offset : nil)
                frame = Rect(x: x, y: origin + margin.top, width: width,
                             height: runExtent - margin.top - margin.bottom)
            } else {
                let open = widths[track] - margin.top - margin.bottom
                let expands = item.values.expandingAxes == .vertical || item.values.expandingAxes == .both
                let height = Extent.of(
                    option: expands ? 3 : item.values.vertical, stated: item.values.height,
                    natural: size.height,
                    available: max(0, open), minimum: item.values.minimumHeight,
                    maximum: item.values.maximumHeight)
                let y = trackOrigins[track] + margin.top + Extent.start(
                    option: item.values.vertical, extent: height, start: 0,
                    available: max(0, open),
                    guide: item.values.verticalGuide?.slot == item.values.vertical
                        ? item.values.verticalGuide?.offset : nil)
                frame = Rect(x: origin + margin.left, y: y,
                             width: runExtent - margin.left - margin.right, height: height)
            }
            var placed = item
            if cells.inserting.remove(identity) == nil { placed.fadeIn = nil }
            self.place(placed, at: direction.places(frame, in: bounds))
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
