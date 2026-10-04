// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import QuartzCore
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// A native scroll surface: its document geometry, its offset reported on the
/// display's frames, and the moment it comes to rest. Where it rests is the
/// platform's - an application that wants it somewhere else writes the offset
/// when it hears it stop.
@MainActor
final class AppKitScrollView: NSScrollView, AppKitWidthConstrainedMeasuring {
    var onOffsetChanged: ((NSPoint, NSPoint) -> Void)?
    var onScrollStopped: (() -> Void)?

    /// Asks for the display's frames: the scroller is moving or has something
    /// to say, and it says it only on a frame - see `frame(now:)`.
    var onFramesWanted: (() -> Void)?

    private(set) var orientation = Axis.vertical
    private(set) var padding = NSEdgeInsets()
    private(set) var isScrollDisabled = false
    private var verticalBarVisibility: Int32 = 0
    private var horizontalBarVisibility: Int32 = 0

    private let documentSurface = AppKitScrollDocumentView()
    private let stackWrapper = AppKitStackView(axis: .vertical)
    private var usesStackWrapper = false
    /// The offset the tree writes, kept for the first layout where it comes before it (`WrittenScrollOffset`).
    private var writtenOffset = WrittenScrollOffset()
    private var lastObservedOffset = NSPoint.zero
    private var gestureScroller: WheelScroller?

    /// The user's movement of this scroller, and its rest.
    private let movement = ScrollMovement()

    var offset: NSPoint { reachable(contentView.bounds.origin) }
    var usesStackWrapperForTesting: Bool { usesStackWrapper }
    var documentChildCountForTesting: Int {
        usesStackWrapper ? stackWrapper.items.count : (documentSurface.item == nil ? 0 : 1)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        drawsBackground = false
        borderType = .noBorder
        // Design: docs/design/platforms/appkit/views.md#scroll-bars
        scrollerStyle = .overlay
        // Offsets the tree writes are content-relative: StateUI keeps its own
        // safe-area accounts, so AppKit's title-bar inset must not move the
        // viewport the contract measures.
        automaticallyAdjustsContentInsets = false
        contentView.postsBoundsChangedNotifications = true
        documentView = documentSurface
        movement.onFramesWanted = { [weak self] in self?.onFramesWanted?() }

        // BORN IN ITS CONTRACT'S DEFAULT STATE. A registration applies on
        // CHANGE, so a scroller nothing describes would otherwise keep
        // AppKit's own resting state - no vertical scroller - where the
        // contract says a scroller scrolls vertically. Applied through the
        // same path, so the two can never drift apart.
        apply(
            orientation: Axis.vertical.rawValue,
            padding: NSEdgeInsets(),
            verticalBarVisibility: 0,
            horizontalBarVisibility: 0,
            isScrollDisabled: false,
            scrollBounceBehavior: ScrollBounceBehavior.automatic.rawValue,
            scrollContentBackground: nil,
            clipsContent: nil,
            defaultAnchor: nil,
            offset: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipBoundsChanged(_:)),
            name: NSView.boundsDidChangeNotification,
            object: contentView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willStartLiveScroll(_:)),
            name: NSScrollView.willStartLiveScrollNotification,
            object: self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEndLiveScroll(_:)),
            name: NSScrollView.didEndLiveScrollNotification,
            object: self)
    }

    convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AppKitScrollView is created in code")
    }

    func setItems(_ items: [AppKitLayoutItem]) {
        if items.occupying.count > 1 { usesStackWrapper = true }

        if usesStackWrapper {
            stackWrapper.setItems(items)
            documentSurface.item = AppKitLayoutItem(view: stackWrapper)
        } else {
            documentSurface.item = items.occupying.first
        }
    }

    func apply(
        orientation: Int32,
        padding: NSEdgeInsets,
        verticalBarVisibility: Int32,
        horizontalBarVisibility: Int32,
        isScrollDisabled: Bool,
        scrollBounceBehavior: Int32,
        scrollContentBackground: Bool?,
        clipsContent: Bool?,
        defaultAnchor: [NSNumber]?,
        offset: NSPoint?
    ) {
        self.orientation = Axis(rawValue: orientation) ?? .vertical
        self.padding = padding
        self.isScrollDisabled = isScrollDisabled
        self.verticalBarVisibility = verticalBarVisibility
        self.horizontalBarVisibility = horizontalBarVisibility
        documentSurface.padding = padding
        documentSurface.orientation = self.orientation

        // `.scrollClipDisabled` lets the document draw past the viewport;
        // a scroller clips by contract default.
        if let clipsContent {
            clipsToBounds = clipsContent
            contentView.clipsToBounds = clipsContent
        }

        let allowsHorizontal = self.orientation == .horizontal || self.orientation == .both
        let allowsVertical = self.orientation == .vertical || self.orientation == .both
        hasHorizontalScroller = allowsHorizontal && horizontalBarVisibility != 2
        hasVerticalScroller = allowsVertical && verticalBarVisibility != 2
        autohidesScrollers = verticalBarVisibility != 1 && horizontalBarVisibility != 1

        // `.always` is elastic both ways; `.basedOnSize` and the platform's own
        // share AppKit's automatic.
        let elasticity: NSScrollView.Elasticity =
            ScrollBounceBehavior(rawValue: scrollBounceBehavior) == .always ? .allowed : .automatic
        horizontalScrollElasticity = allowsHorizontal ? elasticity : .none
        verticalScrollElasticity = allowsVertical ? elasticity : .none

        if let scrollContentBackground { drawsBackground = scrollContentBackground }
        if let defaultAnchor, defaultAnchor.count == 2 {
            self.defaultAnchor = (x: defaultAnchor[0].doubleValue, y: defaultAnchor[1].doubleValue)
        }

        // Design: docs/design/host/layout.md#an-offset-the-tree-writes
        if let target = writtenOffset.written(
            offset.map { Point($0) }, standing: Point(lastObservedOffset), orientation: self.orientation
        ) {
            move(to: NSPoint(x: target.x, y: target.y), asUser: false)
        }
    }

    override var intrinsicContentSize: NSSize {
        fittingContentSize(width: nil)
    }

    /// The document's natural extent before the parent chooses a viewport.
    /// The scrolling axis may then be clipped, while the other axis keeps the
    /// measured size needed by rows such as a tab strip or a code block.
    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        documentSurface.fittingContentSize(width: availableWidth)
    }

    /// The scroller's own box: its outline and the shape it cuts what it shows to, on its layer - a colour's
    /// outline on a rectangle or a rounded one; an oval cuts and draws none.
    /// Design: docs/design/platforms/appkit/views.md#a-layouts-own-box
    func setBox(stroke: HostValue?, strokeWidth: Double?, shape: HostValue?) {
        boxShape = BoxArithmetic.outline(shape)
        let width = BoxArithmetic.outlineWidth(stroke: stroke, width: strokeWidth)
        boxOutline = AppKitBrush(stroke).lineColor.flatMap { width > 0 ? ($0.cgColor, CGFloat(width)) : nil }
        paintBox()
    }

    /// The colour the scroller paints behind what it shows; nil for none.
    var boxBackground: NSColor? {
        didSet { paintBox() }
    }

    private var boxShape = ContainerShape.rectangle
    private var boxOutline: (colour: CGColor, width: CGFloat)?

    /// Where the scroller rests before anything is written: the anchor's
    /// fractions across and down the content and the room. Applied once, on
    /// the first layout with a document to place.
    private var defaultAnchor: (x: Double, y: Double)?
    private var anchoredOnce = false

    // AppKit repaints a scroller's layer as it displays it, its colour and outline cleared: the box is put back
    // each time.
    override func updateLayer() {
        super.updateLayer()
        paintBox()
    }

    private func paintBox() {
        wantsLayer = true
        guard let layer else { return }
        layer.backgroundColor = boxBackground?.cgColor
        layer.borderColor = boxOutline?.colour
        layer.borderWidth = boxOutline?.width ?? 0
        cutToShape()
    }

    private func cutToShape() {
        guard let layer else { return }
        layer.masksToBounds = true
        boxShape.cut(layer)
    }

    override func layout() {
        super.layout()
        cutToShape()
        documentSurface.arrange(in: contentSize)
        super.layout()

        if let target = writtenOffset.laidOutNow() {
            move(to: NSPoint(x: target.x, y: target.y), asUser: false)
        } else if let defaultAnchor, !anchoredOnce, documentSurface.frame.width > 0 {
            anchoredOnce = true
            let document = documentSurface.frame.size
            let room = contentView.bounds.size
            move(to: reachable(NSPoint(
                x: defaultAnchor.x * document.width - defaultAnchor.x * room.width,
                y: defaultAnchor.y * document.height - defaultAnchor.y * room.height)), asUser: false)
        } else {
            move(to: contentView.bounds.origin, asUser: false)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        if wheelScroller(for: event) == .enclosing,
            let enclosingScroller = enclosingScrollView {
            enclosingScroller.scrollWheel(with: event)
            return
        }

        super.scrollWheel(with: event)
    }

    private enum WheelScroller { case own, enclosing }

    /// A one-axis viewport owns gestures along that axis. A dominant gesture
    /// along its disabled axis belongs to the nearest enclosing viewport, so a
    /// horizontal strip does not interrupt its vertical page.
    ///
    /// A wheel click decides alone. A trackpad gesture is decided once, by
    /// its first moving event, and keeps that viewport through its end and
    /// its momentum, which carry no direction of their own: the viewport that
    /// sees a gesture begin is the one that sees it end and settles.
    private func wheelScroller(for event: NSEvent) -> WheelScroller {
        guard !event.phase.isEmpty || !event.momentumPhase.isEmpty else {
            gestureScroller = nil
            return scroller(followingDirectionOf: event) ?? .own
        }
        if event.phase.contains(.mayBegin) || event.phase.contains(.began) {
            gestureScroller = nil
        }
        if gestureScroller == nil {
            gestureScroller = scroller(followingDirectionOf: event)
        }
        return gestureScroller ?? .own
    }

    private func scroller(followingDirectionOf event: NSEvent) -> WheelScroller? {
        if isScrollDisabled || orientation == .neither { return .enclosing }
        let horizontal = abs(event.scrollingDeltaX)
        let vertical = abs(event.scrollingDeltaY)
        guard max(horizontal, vertical) > 0.000_001 else { return nil }

        let handsOver = switch orientation {
        case .horizontal:
            !event.modifierFlags.contains(.shift) && vertical > horizontal
        case .vertical:
            horizontal > vertical
        case .both, .neither:
            false
        }
        return handsOver ? .enclosing : .own
    }

    @objc private func willStartLiveScroll(_ notification: Notification) {
        movement.holdBegan()
    }

    /// A live scroll ends when the movement it began has run out.
    @objc private func didEndLiveScroll(_ notification: Notification) {
        movement.holdEnded(rests: true)
    }

    @objc private func clipBoundsChanged(_ notification: Notification) {
        guard !ProgramWrite.isWriting else { return }
        let current = offset
        guard current != lastObservedOffset else { return }
        // WHERE IT STANDS FIRST, then the report: the report runs the render
        // that writes the state back, and that write is told apart from an
        // application's by where the scroller already stands.
        let previous = lastObservedOffset
        lastObservedOffset = current
        movement.userMoved(from: Point(previous), to: Point(current))
    }

    /// How many times something other than the user moved the scroller.
    private(set) var programmaticMovesForTesting = 0

    private func move(to requested: NSPoint, asUser: Bool) {
        if !asUser { programmaticMovesForTesting += 1 }
        let old = offset
        let target = reachable(normalized(requested))
        ProgramWrite.perform {
            contentView.scroll(to: target)
            reflectScrolledClipView(contentView)
        }
        let current = offset
        lastObservedOffset = current

        if asUser {
            movement.userMoved(from: Point(old), to: Point(current))
        }
    }

    /// Whether the scroller needs the display's frames: it is moving, or it
    /// has something to say.
    var wantsFrames: Bool { movement.wantsFrames }

    /// One frame of the display's clock. What the scroller has to say is said
    /// here and nowhere else, in order: where it went, and that it came to
    /// rest.
    func frame(now: Double) {
        for report in movement.frame(now: now) {
            switch report {
            case .moved(let from, let to):
                onOffsetChanged?(NSPoint(x: from.x, y: from.y), NSPoint(x: to.x, y: to.y))
            case .rested:
                onScrollStopped?()
            }
        }
    }

    private func normalized(_ point: NSPoint) -> NSPoint {
        switch orientation {
        case .horizontal: return NSPoint(x: point.x, y: 0)
        case .vertical: return NSPoint(x: 0, y: point.y)
        case .both: return point
        case .neither: return .zero
        }
    }

    private func reachable(_ point: NSPoint) -> NSPoint {
        let documentSize = documentSurface.frame.size
        return NSPoint(
            x: Self.reachable(point.x, content: documentSize.width, viewport: contentSize.width),
            y: Self.reachable(point.y, content: documentSize.height, viewport: contentSize.height))
    }

    /// An offset inside measured content. Before either extent is known only
    /// the leading edge can be enforced without discarding a pending offset.
    private static func reachable(_ offset: CGFloat, content: CGFloat, viewport: CGFloat) -> CGFloat {
        let leading = max(0, offset.isFinite ? offset : 0)
        guard content.isFinite, viewport.isFinite, content > 0, viewport > 0 else {
            return leading
        }
        return min(leading, max(0, content - viewport))
    }

    /// Scrolls until `descendant` - a view somewhere in the document - stands
    /// where the anchor says: `a` means the point `a` across the target is
    /// brought to the point `a` across the room, on each axis the scroller
    /// moves. Absent, it moves only where the target is not wholly in view -
    /// the shorter way, as `nearest` does on an items view.
    func scroll(toDescendant descendant: NSView, anchorX: Double?, anchorY: Double?) {
        let target = descendant.convert(descendant.bounds, to: documentSurface)
        let visible = contentView.bounds
        var place = visible.origin

        if orientation == .horizontal || orientation == .both {
            place.x = anchorX.map { target.minX + $0 * target.width - $0 * visible.width }
                ?? Self.nearest(of: target.minX, length: target.width, in: visible.width, at: visible.minX)
        }
        if orientation == .vertical || orientation == .both {
            place.y = anchorY.map { target.minY + $0 * target.height - $0 * visible.height }
                ?? Self.nearest(of: target.minY, length: target.height, in: visible.height, at: visible.minY)
        }

        move(to: place, asUser: false)
    }

    /// Where the room stands for the target to be wholly in view, moved the
    /// shorter way - nowhere where it already is.
    private static func nearest(of start: CGFloat, length: CGFloat, in room: CGFloat, at now: CGFloat) -> CGFloat {
        if start >= now, start + length <= now + room { return now }
        return start < now ? start : start + length - room
    }

    func beginMovementForTesting() {
        movement.begin()
    }

    func moveAsUserForTesting(to point: NSPoint) {
        move(to: point, asUser: true)
    }

    func restForTesting() {
        movement.rest()
    }
}

@MainActor
private final class AppKitScrollDocumentView: NSView, AppKitMeasurementCaching {
    let measurements = MeasurementCache()
    var item: AppKitLayoutItem? {
        didSet {
            guard !AppKitLayoutItem.sameArrangement(oldValue, item) else { return }
            replaceSubviews(with: item.map { [$0.view] } ?? [])
            invalidateMeasurements()
        }
    }
    var padding = NSEdgeInsets() {
        didSet { if !NSEdgeInsetsEqual(padding, oldValue) { invalidateMeasurements() } }
    }
    var orientation = Axis.vertical {
        didSet { if orientation != oldValue { invalidateMeasurements() } }
    }

    override var isFlipped: Bool { true }

    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        measurements.size(offering: availableWidth) {
            measuredContentSize(width: availableWidth)
        }
    }

    private func measuredContentSize(width availableWidth: CGFloat?) -> NSSize {
        NSSize(ScrollArithmetic.contentSize(
            of: item, padding: EdgeInsets(padding), orientation: orientation,
            width: availableWidth.map(Double.init)))
    }

    func arrange(in viewport: NSSize) {
        guard let item else {
            frame.size = viewport
            return
        }

        let arranged = ScrollArithmetic.arrange(
            item, padding: EdgeInsets(padding), orientation: orientation, in: LayoutSize(viewport))
        frame = NSRect(origin: .zero, size: NSSize(arranged.document))
        item.view.frame = NSRect(placed: arranged.place)
        item.view.needsLayout = true
    }
}

extension AppKitScrollView: FramedScroller {}

#endif
