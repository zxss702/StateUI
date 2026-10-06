// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// What a lazy container's view does alike: it keeps the children in view
/// mounted - and only those - telling the tree which identities the window
/// wants built, and standing each at the offset its measure says.
///
/// The run's length is the estimates' before the children exist, so the
/// scroll room answers at once; a child's own measure lands as it mounts and
/// shifts the places after it, the way a scroller of estimated rows does.
/// Design: docs/design/host/items.md#the-view-moving
@MainActor
class AppKitLazyView: AppKitTravellingLayout {
    /// The direction the children stack in.
    let axis: StackArithmetic.Axis

    /// The cells' bookkeeping: identities, mounted children, the runs' measures.
    let cells: LazyCells

    /// The children mounted now, by identity.
    private(set) var held: [String: AppKitLayoutItem] = [:]

    /// The clip whose bounds moving re-asks the window; the nearest scroller's.
    private weak var watching: NSView?

    /// A window change under way asks the run again once, not per notice.
    private var retellQueued = false

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
        guard now.keys != held.keys || now.contains(where: { held[$0.key]?.view !== $0.value.view })
        else { return }
        replaceSubviews(with: items.map(\.1.view))
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
            // No clip to narrow by means all of it stands in view - a lazy
            // container outside any scroller builds every child.
            guard self.watching != nil else {
                if self.window != nil { self.cells.tellAll() }
                return
            }
            guard let span = self.span else { return }
            self.tellWindow(span)
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
        retell()
        needsLayout = true
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
final class AppKitLazyStackView: AppKitLazyView, AppKitWidthConstrainedMeasuring,
    AppKitMeasurementCaching
{
    let measurements = MeasurementCache()
    var spacing: CGFloat = 0 {
        didSet { if spacing != oldValue { cells.extents.spacing = Double(spacing); invalidateMeasurements() } }
    }
    var padding = NSEdgeInsets() {
        didSet {
            if !NSEdgeInsetsEqual(padding, oldValue) {
                cells.extents.padding = (head: Double(head), tail: Double(tail))
                invalidateMeasurements()
            }
        }
    }

    /// The padding before the first child on the run.
    private var head: CGFloat { axis == .vertical ? padding.top : padding.left }

    /// The padding after the last child on the run.
    private var tail: CGFloat { axis == .vertical ? padding.bottom : padding.right }

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
                : NSSize(width: total, height: max(0, self.acrossRoom))
        }
    }

    /// Every mounted child measures, is stood at its offset, and the window
    /// re-asks what the tree builds.
    override func layout() {
        super.layout()
        measureHeld()
        arrangeHeld()
    }

    override func tellWindow(_ span: Range<Double>) {
        let wanted = cells.places(in: span, overscan: 0)
        cells.tell(first: wanted.lowerBound, last: wanted.upperBound - 1)
    }

    /// Measures every held child on the run and keeps its extent, margin in.
    /// A changed mean moves every place after the measured - the whole run's
    /// estimate is the scroll room, so it asks to be laid out again.
    private func measureHeld() {
        let estimate = cells.extents.estimate
        let offered = Double(max(0, acrossRoom))
        for (identity, item) in held {
            let margin = item.values.margin
            let size = item.size(offered: axis == .vertical
                ? max(0, offered - margin.left - margin.right) : nil)
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            cells.extents.measure(identity, extent: extent)
        }
        if cells.extents.estimate != estimate { invalidateMeasurements() }
    }

    /// Stands every held child at its offset on the run.
    private func arrangeHeld() {
        beginArrangement()
        let across = Double(max(0, acrossRoom))
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
                    natural: Double(item.view.fittingSize.width),
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
                    natural: Double(item.view.fittingSize.height),
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
            self.place(item, at: NSRect(placed: direction.places(frame.placed, in: bounds.placed)))
        }
    }
}

/// A lazy grid: the cells fill the tracks across its run, a run at a time -
/// a `LazyVGrid`'s run is a row of its columns, a `LazyHGrid`'s a column of
/// its rows.
final class AppKitLazyGridView: AppKitLazyView, AppKitWidthConstrainedMeasuring,
    AppKitMeasurementCaching
{
    let measurements = MeasurementCache()

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
                cells.runs.padding = (head: Double(head), tail: Double(tail))
                invalidateMeasurements()
            }
        }
    }

    /// The track extents at the room now, kept until the room or they change;
    /// a changed count makes new runs, and their measures go.
    private var columns: [Double] = [] {
        didSet {
            if columns.count != oldValue.count {
                cells.runs.reset()
                invalidateMeasurements()
            }
        }
    }

    /// The padding before the first run.
    private var head: CGFloat { axis == .vertical ? padding.top : padding.left }

    /// The padding after the last run.
    private var tail: CGFloat { axis == .vertical ? padding.bottom : padding.right }

    /// The room across - inside the padding, the tracks take it all.
    private var acrossRoom: CGFloat {
        axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom
    }

    /// The tracks' extents at the room now, resolved where the room changed.
    private var tracksNow: [Double] { columns }

    /// The cells a run holds.
    private var perRun: Int { max(1, columns.count) }

    /// The runs the cells make.
    private var runCount: Int { (cells.identities.count + perRun - 1) / perRun }

    /// Resolves the tracks for the room now where it moved.
    private func resolveTracks() {
        let room = Double(max(0, acrossRoom))
        let next = LazyGridTracks.extents(
            LazyGridTracks.resolve(tracks, width: room, spacing: Double(trackSpacing)),
            width: room, spacing: Double(trackSpacing))
        if next != columns { columns = next }
    }

    /// As wide as offered and as long as the runs measure.
    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        measurements.size(offering: availableWidth) {
            let total = CGFloat(self.cells.runs.total(count: self.runCount))
            return self.axis == .vertical
                ? NSSize(width: availableWidth ?? 0, height: total)
                : NSSize(width: total, height: max(0, self.acrossRoom))
        }
    }

    override func layout() {
        super.layout()
        resolveTracks()
        measureHeld()
        arrangeHeld()
    }

    override func tellWindow(_ span: Range<Double>) {
        resolveTracks()
        let wanted = cells.runs.places(in: span, overscan: 0, count: runCount)
        cells.tellRuns(first: wanted.lowerBound, last: wanted.upperBound - 1, perRun: perRun)
    }

    /// Measures every held cell's run: its extent is the longest cell's. A
    /// changed mean moves every run after the measured, so the scroll room is
    /// laid out again.
    private func measureHeld() {
        let estimate = cells.runs.estimate
        let widths = tracksNow
        guard !widths.isEmpty else { return }
        for (identity, item) in held {
            guard let place = cells.position(of: identity) else { continue }
            let row = place / widths.count, column = place % widths.count
            let margin = item.values.margin
            let offered: Double? = axis == .vertical
                ? max(0, Double(widths[column]) - margin.left - margin.right) : nil
            let size = item.size(offered: offered)
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            cells.runs.measure(row, extent: extent)
        }
        if cells.runs.estimate != estimate { invalidateMeasurements() }
    }

    /// Stands every held cell at its run and track.
    private func arrangeHeld() {
        beginArrangement()
        let widths = tracksNow
        guard !widths.isEmpty else { return }
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
                    natural: Double(item.view.fittingSize.width),
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
                    natural: Double(item.view.fittingSize.height),
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
            self.place(item, at: NSRect(placed: direction.places(frame.placed, in: bounds.placed)))
        }
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
