// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost
import CStateUIAndroid

/// What a lazy container's view does alike: it keeps the children in view
/// mounted - and only those - telling the tree which identities the window
/// wants built, and standing each at the offset its measure says.
///
/// Where GTK's run finds its scroller by walking the widgets, an Android view
/// has no parent to ask: the scroller pushes the window down instead
/// (`AndroidScrollView.scrolled` and the document's `onArranged`), and a run no
/// scroller ever reaches builds all of its children from the frame report
/// after each layout pass.
/// Design: docs/design/host/items.md#the-view-moving
@MainActor
class AndroidLazyView: AndroidTravellingLayout {
    /// The direction the children stack in.
    let axis: StackArithmetic.Axis

    /// The cells' bookkeeping: identities, mounted children, the runs' measures.
    let cells: LazyCells

    /// The children mounted now, by identity.
    private(set) var mounted: [String: AndroidLayoutItem] = [:]

    /// Where the frame reports come from: a run outside every scroller builds
    /// all of its children, said once a layout pass is over.
    private weak var runtime: HostRuntime?

    /// Whether a scroller has told this run's window; until one does it stands
    /// as though fully in view.
    private var windowed = false

    init(axis: StackArithmetic.Axis, cells: LazyCells, runtime: HostRuntime) {
        self.axis = axis
        self.cells = cells
        self.runtime = runtime
        super.init()
        runtime.frames.follow(self, order: number, reads: true)
    }

    /// The mounted children, held by identity.
    func setItems(_ items: [(identity: String, item: AndroidLayoutItem)]) {
        let now = Dictionary(items.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        guard now.keys != mounted.keys || now.contains(where: { mounted[$0.key]?.view !== $0.value.view })
        else { return }
        mounted = now
        setChildren(items.map(\.item.view))
        invalidateMeasurements()
    }

    /// The scroller clipping this run on its own axis pushed the window's span
    /// - the part of the run in view, along the run; nil where it shows none,
    /// which asks nothing new of the tree.
    func windowMoved(to span: Range<Double>?) {
        windowed = true
        if let span { tellWindow(span) }
    }

    /// The places standing in `span`, as the kind's runs count them.
    func tellWindow(_ span: Range<Double>) {}

    override func detach() {
        super.detach()
        runtime?.frames.follow(self, order: number, reads: false)
        runtime = nil
    }
}

extension AndroidLazyView: FrameReporter {
    /// A layout pass ended: a run no scroller narrows stands wholly in view.
    func reportFrame() {
        if !windowed { cells.tellAll() }
    }
}

/// A lazy stack: one child a place.
final class AndroidLazyStackView: AndroidLazyView {
    /// The room between two children.
    var spacing = 0.0 {
        didSet { if spacing != oldValue { cells.extents.spacing = spacing; invalidateMeasurements() } }
    }

    /// The room inside the stack's own edge.
    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.extents.padding = (head: head, tail: tail)
                invalidateMeasurements()
            }
        }
    }

    /// The padding before the first child on the run.
    private var head: Double { axis == .vertical ? padding.top : padding.left }

    /// The padding after the last child on the run.
    private var tail: Double { axis == .vertical ? padding.bottom : padding.right }

    /// The room a child gets across - inside the padding.
    private func acrossRoom(in bounds: Rect) -> Double {
        axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom
    }

    /// As wide as offered and as long as the run measures.
    override func contentSize(width: Double?) -> LayoutSize {
        let total = cells.total
        return axis == .vertical
            ? LayoutSize(width: width ?? 0, height: total)
            : LayoutSize(width: total, height: 0)
    }

    /// Every mounted child measures, is stood at its offset, and the window
    /// re-asks what the tree builds.
    override func arrange(in bounds: Rect) {
        beginArrangement(width: bounds.width)
        let estimate = cells.extents.estimate
        let across = max(0, acrossRoom(in: bounds))
        for (identity, item) in mounted {
            let margin = item.values.margin
            let size = item.size(offered: axis == .vertical
                ? max(0, across - margin.left - margin.right) : nil)
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            cells.extents.measure(identity, extent: extent)

            guard let place = cells.position(of: identity) else { continue }
            let run = cells.offset(of: place)
            let frame: Rect
            if axis == .vertical {
                let open = across - margin.left - margin.right
                let width = Extent.of(
                    option: item.values.horizontal, stated: item.values.width,
                    natural: size.width - margin.left - margin.right,
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
                let height = Extent.of(
                    option: item.values.vertical, stated: item.values.height,
                    natural: size.height - margin.top - margin.bottom,
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
            self.place(item, at: direction.places(frame, in: bounds))
        }
        if cells.extents.estimate != estimate { invalidateMeasurements() }
    }

    override func tellWindow(_ span: Range<Double>) {
        let wanted = cells.places(in: span, overscan: 0)
        cells.tell(first: wanted.lowerBound, last: wanted.upperBound - 1)
    }
}

/// A lazy grid: the cells fill the tracks across its run, a run at a time -
/// a `LazyVGrid`'s run is a row of its columns, a `LazyHGrid`'s a column of
/// its rows.
final class AndroidLazyGridView: AndroidLazyView {
    /// The tracks across - `flowColumns` down a grid, `flowRows` across one.
    var tracks: [GridItem] = [] { didSet { if tracks != oldValue { columns = [] } } }

    /// The room between one run and the next.
    var runSpacing = 0.0 {
        didSet { if runSpacing != oldValue { cells.runs.spacing = runSpacing; invalidateMeasurements() } }
    }

    /// The room between the tracks.
    var trackSpacing = 0.0 { didSet { if trackSpacing != oldValue { columns = [] } } }

    /// The room inside the grid's own edge.
    var padding = EdgeInsets(0) {
        didSet {
            if padding != oldValue {
                cells.runs.padding = (head: head, tail: tail)
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
    private var head: Double { axis == .vertical ? padding.top : padding.left }

    /// The padding after the last run.
    private var tail: Double { axis == .vertical ? padding.bottom : padding.right }

    /// The room across - inside the padding, the tracks take it all.
    private var acrossRoom = 0.0

    /// The cells a run holds.
    private var perRun: Int { max(1, columns.count) }

    /// The runs the cells make.
    private var runCount: Int { (cells.identities.count + perRun - 1) / perRun }

    /// Resolves the tracks for the room now where it moved.
    private func resolveTracks() {
        let room = max(0, acrossRoom)
        let next = LazyGridTracks.extents(
            LazyGridTracks.resolve(tracks, width: room, spacing: trackSpacing),
            width: room, spacing: trackSpacing)
        if next != columns { columns = next }
    }

    /// As wide as offered and as long as the runs measure.
    override func contentSize(width: Double?) -> LayoutSize {
        if let width { acrossRoom = width }
        let total = cells.runs.total(count: runCount)
        return axis == .vertical
            ? LayoutSize(width: width ?? 0, height: total)
            : LayoutSize(width: total, height: acrossRoom)
    }

    override func arrange(in bounds: Rect) {
        beginArrangement(width: bounds.width)
        acrossRoom = axis == .vertical
            ? bounds.width - padding.left - padding.right
            : bounds.height - padding.top - padding.bottom
        resolveTracks()
        let widths = columns
        guard !widths.isEmpty else { return }
        let estimate = cells.runs.estimate

        for (identity, item) in mounted {
            guard let place = cells.position(of: identity) else { continue }
            let run = place / widths.count, track = place % widths.count
            let margin = item.values.margin
            let offered: Double? = axis == .vertical
                ? max(0, widths[track] - margin.left - margin.right) : nil
            let size = item.size(offered: offered)
            let extent = axis == .vertical
                ? size.height + margin.top + margin.bottom
                : size.width + margin.left + margin.right
            cells.runs.measure(run, extent: extent)

            var trackOrigins: [Double] = []
            var start = axis == .vertical ? padding.left : padding.top
            for width in widths {
                trackOrigins.append(start)
                start += width + trackSpacing
            }

            let origin = cells.runs.offset(of: run, count: runCount)
            let runExtent = cells.runs.extent(of: run)
            let frame: Rect
            if axis == .vertical {
                let open = widths[track] - margin.left - margin.right
                let width = Extent.of(
                    option: item.values.horizontal, stated: item.values.width,
                    natural: size.width - margin.left - margin.right,
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
                let height = Extent.of(
                    option: item.values.vertical, stated: item.values.height,
                    natural: size.height - margin.top - margin.bottom,
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
            self.place(item, at: direction.places(frame, in: bounds))
        }
        if cells.runs.estimate != estimate { invalidateMeasurements() }
    }

    override func tellWindow(_ span: Range<Double>) {
        resolveTracks()
        let wanted = cells.runs.places(in: span, overscan: 0, count: runCount)
        cells.tellRuns(first: wanted.lowerBound, last: wanted.upperBound - 1, perRun: perRun)
    }
}

extension Axis {
    /// Whether a scroller of this axis can clip a lazy run of `axis`.
    func takes(_ axis: StackArithmetic.Axis) -> Bool {
        switch (self, axis) {
        case (.both, _), (.vertical, .vertical), (.horizontal, .horizontal): true
        default: false
        }
    }
}
