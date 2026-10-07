// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// The native font a caption is drawn in: the text style's font where one is
/// named, else the family where one is named, at the size given or the
/// fallback's - shaped by the design, drawn at the weight, bold and italic
/// where the attributes say so. The host composes it from an element's values
/// and a registration from the members it reads - one composition, either way.
@MainActor
func appKitFont(
    family: String?, size: Double?, attributes: FontAttributes?,
    textStyle: FontTextStyle?, weight: Double?, design: FontDesign?,
    fallback: NSFont
) -> NSFont {
    let traits = attributes ?? .none
    var font: NSFont
    if let textStyle, let nsStyle = appKitTextStyle(textStyle) {
        font = NSFont.preferredFont(forTextStyle: nsStyle)
        if let size { font = NSFont(descriptor: font.fontDescriptor, size: size) ?? font }
    } else {
        let points = size ?? fallback.pointSize
        if let weight, family == nil {
            font = NSFont.systemFont(ofSize: points, weight: NSFont.Weight(rawValue: weight / 100.0))
        } else {
            font = family.flatMap { NSFont(name: $0, size: points) } ?? NSFont.systemFont(ofSize: points)
        }
    }
    if let design, let shaped = font.fontDescriptor.withDesign(appKitFontDesign(design)) {
        font = NSFont(descriptor: shaped, size: font.pointSize) ?? font
    }
    if traits.contains(.bold) { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
    if traits.contains(.italic) { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
    return font
}

/// A SwiftOmniUI text style as AppKit's own.
func appKitTextStyle(_ style: FontTextStyle) -> NSFont.TextStyle? {
    switch style {
    case .largeTitle: .largeTitle
    case .title: .title1
    case .title2: .title2
    case .title3: .title3
    case .headline: .headline
    case .subheadline: .subheadline
    case .body: .body
    case .callout: .callout
    case .footnote: .footnote
    case .caption: .caption1
    case .caption2: .caption2
    }
}

extension NSAttributedString.Key {
    /// Which of a label's span runs these words came from - written by
    /// `attributedLabelText`, read by a `TextLayoutReport` grouping the
    /// typesetter's glyphs back into the element's own runs.
    static let stateUIRunIndex = NSAttributedString.Key("swiftomniui.runIndex")
}

/// A SwiftOmniUI font design as AppKit's own.
func appKitFontDesign(_ design: FontDesign) -> NSFontDescriptor.SystemDesign {
    switch design {
    case .default: .default
    case .serif: .serif
    case .rounded: .rounded
    case .monospaced: .monospaced
    }
}

/// Words' attributes from how the host layer says they look (`TextLook`), drawn in `font`: their colour, else
/// `fallbackColor`, what stands behind them, the space between the letters, the lines' height and decorations.
/// Design: docs/design/host/tree.md#runs-of-words
@MainActor
func appKitAttributes(_ look: TextLook, font: NSFont, fallbackColor: NSColor) -> [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: look.color.flatMap(nsColor) ?? fallbackColor,
        .kern: look.letterSpacing,
    ]
    if let background = look.background.flatMap(nsColor) { attributes[.backgroundColor] = background }
    if let offset = look.baselineOffset, offset.isFinite { attributes[.baselineOffset] = offset }
    if look.decorations.contains(.underline) { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
    if look.decorations.contains(.strikethrough) {
        attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }
    if let lineHeight = look.lineHeight, lineHeight.isFinite, lineHeight > 0 {
        let paragraph = NSMutableParagraphStyle()
        let height = font.boundingRectForFont.height * lineHeight
        paragraph.minimumLineHeight = height
        paragraph.maximumLineHeight = height
        attributes[.paragraphStyle] = paragraph
    }
    return attributes
}

/// Where text sits across its element, as AppKit draws it.
func appKitTextAlignment(_ value: Int32?) -> NSTextAlignment {
    switch value {
    case 1: return .center
    case 2: return .right
    default: return .left
    }
}

#endif
