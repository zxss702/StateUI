// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// A container an author's `Layout` arranges: the layout object pulled back
/// over the boundary, its children handed to it as `LayoutSubview`s measuring
/// through this view's items and placing through `place(_:at:)`.
@MainActor
final class AppKitCustomLayoutView: AppKitTravellingLayout, AppKitWidthConstrainedMeasuring,
    AppKitMeasurementCaching {
    let measurements = MeasurementCache()
    private var items: [AppKitLayoutItem] = []
    private var box: LayoutBox?

    /// The room inside the container's own edge.
    var padding = NSEdgeInsets() {
        didSet { if !NSEdgeInsetsEqual(padding, oldValue) { invalidateMeasurements() } }
    }

    override var isFlipped: Bool { true }

    /// A fresh set of children and the layout that arranges them.
    func setItems(_ items: [AppKitLayoutItem], layout: LayoutBox?) {
        box = layout
        replaceSubviews(with: items.map(\.view))
        self.items = items
        box?.update(subviews: subviews())
        invalidateMeasurements()
    }

    /// The items as the layout sees them: measured through `fittingSize`,
    /// placed through this view's arrangement, their `.layoutValue` tags and
    /// guides read back over the boundary.
    private func subviews() -> LayoutSubviews {
        LayoutSubviews(items.occupying.map { item in
            LayoutSubview(
                layoutValues: item.codeId.map { CoreLink().layoutValues(for: $0) } ?? [:],
                priority: item.values.priority,
                measureSize: { proposal in
                    let measured = item.fittingSize(width: proposal.width.map { CGFloat($0) })
                    return SwiftOmniUI.Size(width: Double(measured.width), height: Double(measured.height))
                },
                measureDimensions: { proposal in
                    let measured = item.fittingSize(width: proposal.width.map { CGFloat($0) })
                    var guides: [Int32: Double] = [:]
                    var explicit: Set<Int32> = []
                    if let guide = item.values.horizontalGuide {
                        guides[guide.slot] = guide.offset
                        explicit.insert(guide.slot)
                    }
                    if let guide = item.values.verticalGuide {
                        guides[guide.slot] = guide.offset
                        explicit.insert(guide.slot)
                    }
                    if let baseline = item.firstBaseline {
                        guides[AxisAlignment.firstTextBaseline.rawValue] = baseline
                    }
                    if let baseline = item.lastBaseline {
                        guides[AxisAlignment.lastTextBaseline.rawValue] = baseline
                    }
                    return ViewDimensions(
                        width: Double(measured.width), height: Double(measured.height),
                        guides: guides, explicitSlots: explicit)
                },
                placeView: { [weak self] position, anchor, proposal in
                    guard let self else { return }
                    let measured = item.fittingSize(width: proposal.width.map { CGFloat($0) })
                    let frame = NSRect(
                        x: CGFloat(position.x - anchor.x * Double(measured.width)),
                        y: CGFloat(position.y - anchor.y * Double(measured.height)),
                        width: measured.width, height: measured.height)
                    self.place(item, at: frame)
                })
        }, direction: direction)
    }

    override var intrinsicContentSize: NSSize {
        fittingContentSize(width: nil)
    }

    /// The size the layout answers for the width offered.
    func fittingContentSize(width availableWidth: CGFloat?) -> NSSize {
        measurements.size(offering: availableWidth) {
            guard let box else { return NSSize(width: 0, height: 0) }
            let offered = availableWidth.map {
                max(0, Double($0) - padding.left - padding.right) }
            let measured = box.measure(
                proposal: ProposedViewSize(width: offered), subviews: subviews())
            return NSSize(
                width: measured.width + padding.left + padding.right,
                height: measured.height + padding.top + padding.bottom)
        }
    }

    override func layout() {
        super.layout()

        guard let box else { return }
        beginArrangement()
        for item in items.occupying {
            item.drawing?.placement = nil
            item.drawing?.placedOpacity = 1
        }
        let room = NSRect(
            x: padding.left, y: padding.top,
            width: max(0, bounds.width - padding.left - padding.right),
            height: max(0, bounds.height - padding.top - padding.bottom))
        box.place(
            in: room.placed,
            proposal: ProposedViewSize(
                width: Double(room.width), height: Double(room.height)),
            subviews: subviews())
    }
}

#endif
