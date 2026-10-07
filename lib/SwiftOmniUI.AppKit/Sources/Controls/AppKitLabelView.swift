// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

enum AppKitVerticalTextAlignment: Int32, Equatable {
    case start = 0
    case center = 1
    case end = 2
}

/// A native read-only text surface with SwiftOmniUI-owned padding and vertical
/// placement. AppKit still owns glyph shaping, wrapping and drawing.
@MainActor
final class AppKitLabelView: AppKitHitTestView, AppKitWidthConstrainedMeasuring,
    AppKitMeasurementCaching {
    private let textField = NSTextField(labelWithString: "")
    let measurements = MeasurementCache()

    private(set) var padding = NSEdgeInsets()
    private(set) var multilineTextAlignment: NSTextAlignment = .left
    private(set) var verticalTextAlignment: AppKitVerticalTextAlignment = .start
    private(set) var maximumNumberOfLines = 0
    private(set) var lineBreakMode: NSLineBreakMode = .byWordWrapping

    var attributedStringValue: NSAttributedString { textField.attributedStringValue }
    var stringValue: String { textField.stringValue }
    var textFrame: NSRect { textField.frame }
    var nativeTextSizeForTesting: NSSize { textField.cell?.cellSize ?? .zero }
    private(set) var nativeMeasurementCountForTesting = 0
    var textForTesting: NSAttributedString { textField.attributedStringValue }

    /// What runs once the words' place is set - the element reporting its
    /// layout, so the report follows the label's own pass and no frame clock.
    var onLaidOut: (() -> Void)?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.maximumNumberOfLines = 0
        addSubview(textField)
    }

    convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AppKitLabelView is created in code")
    }

    func apply(
        attributedText: NSAttributedString,
        padding: NSEdgeInsets,
        horizontalAlignment: NSTextAlignment,
        verticalAlignment: AppKitVerticalTextAlignment,
        breaking: LineBreak,
        maximumNumberOfLines: Int,
        selectable: Bool = false
    ) {
        let lineBreakMode = NSLineBreakMode(breaking)
        let styled = paragraphStyled(
            attributedText, alignment: horizontalAlignment, breaking: lineBreakMode)
        let unchanged = textField.attributedStringValue.isEqual(to: styled)
            && multilineTextAlignment == horizontalAlignment
            && verticalTextAlignment == verticalAlignment
            && self.lineBreakMode == lineBreakMode
            && self.maximumNumberOfLines == max(0, maximumNumberOfLines)
            && NSEdgeInsetsEqual(self.padding, padding)
            && textField.isSelectable == selectable
        guard !unchanged else { return }

        textField.attributedStringValue = styled
        textField.alignment = horizontalAlignment
        textField.maximumNumberOfLines = max(0, maximumNumberOfLines)
        textField.lineBreakMode = lineBreakMode
        textField.isSelectable = selectable
        textField.cell?.wraps = breaking.wraps
        textField.cell?.isScrollable = false

        self.padding = padding
        multilineTextAlignment = horizontalAlignment
        verticalTextAlignment = verticalAlignment
        self.lineBreakMode = lineBreakMode
        self.maximumNumberOfLines = max(0, maximumNumberOfLines)
        invalidateMeasurements()
    }

    /// `text` carrying the paragraph rules this label draws by.
    ///
    /// A cell draws an attributed string by the style inside that string, so a
    /// text field's own `alignment` moves nothing once the words arrive
    /// attributed. `.left` becomes `.natural`, leaving words written right to
    /// left starting at their own edge.
    private func paragraphStyled(
        _ text: NSAttributedString,
        alignment: NSTextAlignment,
        breaking lineBreakMode: NSLineBreakMode
    ) -> NSAttributedString {
        let styled = NSMutableAttributedString(attributedString: text)
        let whole = NSRange(location: 0, length: styled.length)
        var runs: [(range: NSRange, paragraph: NSParagraphStyle?)] = []
        styled.enumerateAttribute(.paragraphStyle, in: whole) { value, range, _ in
            runs.append((range, value as? NSParagraphStyle))
        }

        for run in runs {
            let paragraph = run.paragraph?.mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            paragraph.alignment = alignment == .left ? .natural : alignment
            paragraph.lineBreakMode = lineBreakMode
            styled.addAttribute(.paragraphStyle, value: paragraph, range: run.range)
        }

        return styled
    }

    override var intrinsicContentSize: NSSize {
        fittingContentSize(width: nil)
    }

    func fittingContentSize(width: CGFloat?) -> NSSize {
        measurements.size(offering: width) { measuredContentSize(width: width) }
    }

    /// Asks the native cell for the text's size inside `width`.
    private func measuredContentSize(width: CGFloat?) -> NSSize {
        let horizontalInsets = padding.left + padding.right
        let verticalInsets = padding.top + padding.bottom
        let contentWidth = width.map { max(0, $0 - horizontalInsets) }
        let bounds = NSRect(
            x: 0,
            y: 0,
            width: contentWidth ?? .greatestFiniteMagnitude,
            height: .greatestFiniteMagnitude)
        nativeMeasurementCountForTesting += 1
        let measured = textField.cell?.cellSize(forBounds: bounds)
            ?? attributedStringValue.boundingRect(
                with: bounds.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading]).size
        let naturalWidth = ceil(measured.width) + horizontalInsets
        return NSSize(
            width: width.map { min(max(0, $0), naturalWidth) } ?? naturalWidth,
            height: ceil(measured.height) + verticalInsets)
    }

    override func layout() {
        super.layout()
        let content = NSRect(
            x: bounds.minX + padding.left,
            y: bounds.minY + padding.top,
            width: max(0, bounds.width - padding.left - padding.right),
            height: max(0, bounds.height - padding.top - padding.bottom))
        let measured = fittingContentSize(width: bounds.width)
        let naturalHeight = max(0, measured.height - padding.top - padding.bottom)
        let height = min(content.height, naturalHeight)
        let y: CGFloat = switch verticalTextAlignment {
        case .start: content.minY
        case .center: content.midY - height / 2
        case .end: content.maxY - height
        }
        textField.frame = NSRect(x: content.minX, y: y, width: content.width, height: height)
        onLaidOut?()
    }

    /// How TextKit laid the words out: each line's rectangle, each run's
    /// (grouped by the span index the words were tagged with), each glyph
    /// cluster's slice - all in this label's own coordinates, for
    /// `textLayoutChanged`.
    /// Design: docs/design/host/tree.md#runs-of-words
    func textLayoutReport() -> TextLayoutReport? {
        let text = attributedStringValue
        let area = textField.frame
        guard !text.string.isEmpty, area.width > 0, area.height > 0 else { return nil }

        let storage = NSTextStorage(attributedString: text)
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: area.size)
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = maximumNumberOfLines
        container.lineBreakMode = lineBreakMode
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)

        var lines: [TextLayoutReport.Line] = []
        let whole = NSRange(location: 0, length: manager.numberOfGlyphs)
        manager.enumerateLineFragments(forGlyphRange: whole) {
            lineRect, _, _, glyphRange, _ in
            var runs: [TextLayoutReport.Run] = []
            let characterRange = manager.characterRange(
                forGlyphRange: glyphRange, actualGlyphRange: nil)
            text.enumerateAttribute(.stateUIRunIndex, in: characterRange) { value, range, _ in
                let span = value as? Int ?? -1
                let runGlyphs = manager.glyphRange(
                    forCharacterRange: range, actualCharacterRange: nil)
                var slices: [Rect] = []
                (text.string as NSString).enumerateSubstrings(
                    in: range, options: .byComposedCharacterSequences
                ) { _, clusterRange, _, _ in
                    let clusterGlyphs = manager.glyphRange(
                        forCharacterRange: clusterRange, actualCharacterRange: nil)
                    slices.append(self.reportRect(manager.boundingRect(
                        forGlyphRange: clusterGlyphs, in: container)))
                }
                let directions = text.attribute(.writingDirection, at: range.location, effectiveRange: nil)
                    as? [NSNumber] ?? []
                let runRect = manager.boundingRect(forGlyphRange: runGlyphs, in: container)
                runs.append(TextLayoutReport.Run(
                    rect: self.reportRect(runRect),
                    direction: directions.contains(NSNumber(value: NSWritingDirection.rightToLeft.rawValue))
                        ? .rightToLeft : .leftToRight,
                    span: span,
                    slices: slices))
            }
            lines.append(TextLayoutReport.Line(rect: self.reportRect(lineRect), runs: runs))
        }
        return TextLayoutReport(lines: lines)
    }

    /// A container rectangle as the report's, moved into this label's
    /// coordinates.
    private func reportRect(_ container: NSRect) -> Rect {
        Rect(
            container.minX + textField.frame.minX,
            container.minY + textField.frame.minY,
            container.width, container.height)
    }

}

#endif
