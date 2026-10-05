// SPDX-License-Identifier: Apache-2.0

// `Text(AttributedString)`: an attributed string shown as runs, each run's
// look mapped onto a span. StateUI's text already draws runs; the
// `AttributedString` it cannot name - Foundation's - is converted here.
//
// Attributes read: the platform scope the string was built in - AppKit's or
// UIKit's - foreground and background colours, font (size, weight, italic,
// monospaced), underline and strikethrough. A run carrying none renders as
// plain text.

import Foundation
@_spi(Host) import StateUI

#if canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#elseif canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#endif

extension Text {
    /// Text showing an attributed string's runs, each keeping its own look.
    ///
    /// Disfavoured so a string literal keeps meaning the localized key -
    /// `AttributedString` spells itself out of literals too.
    @_disfavoredOverload
    public init(_ attributed: AttributedString) {
        self = Text().spans {
            let runs = Array(attributed.runs)

            ForEach(0..<runs.count) { index in
                let run = runs[index]
                TextSpan(String(attributed[run.range].characters))
                    .styled(with: run)
            }
        }
    }
}

extension TextSpan {
    /// One attributed run's look, as span modifiers.
    fileprivate func styled(with run: AttributedString.Runs.Run) -> TextSpan {
        var span = self

        #if canImport(AppKit) || canImport(UIKit)
        if let color = run.platformForeground {
            span = span.foregroundStyle(Color(color))
        }
        if let font = run.platformFont {
            span = span.font(Font(font))
        }
        #endif

        #if canImport(AppKit)
        if let color = run.appKit.backgroundColor {
            span = span.background(Color(color))
        }
        if let underline = run.appKit.underlineStyle, underline.contains(.single) {
            span = span.underline()
        }
        if let strike = run.appKit.strikethroughStyle, strike.contains(.single) {
            span = span.strikethrough()
        }
        #endif

        return span
    }
}

#if canImport(AppKit) || canImport(UIKit)
extension AttributedString.Runs.Run {
    /// The run's foreground colour, whichever platform scope wrote it.
    fileprivate var platformForeground: PlatformColor? {
        #if canImport(AppKit)
        self.appKit.foregroundColor
        #else
        self.uiKit.foregroundColor
        #endif
    }

    /// The run's font.
    fileprivate var platformFont: PlatformFont? {
        #if canImport(AppKit)
        self.appKit.font
        #else
        self.uiKit.font
        #endif
    }
}

extension Color {
    /// A platform colour as a StateUI colour.
    fileprivate init(_ color: PlatformColor) {
        #if canImport(AppKit)
        let rgb = color.usingColorSpace(.sRGB) ?? color
        self.init(
            red: Double(rgb.redComponent),
            green: Double(rgb.greenComponent),
            blue: Double(rgb.blueComponent),
            alpha: Double(rgb.alphaComponent))
        #else
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(
            red: Double(red), green: Double(green),
            blue: Double(blue), alpha: Double(alpha))
        #endif
    }
}

extension Font {
    /// A platform font as a StateUI font: its size, and the traits the
    /// descriptor names - bold, italic, monospaced.
    fileprivate init(_ font: PlatformFont) {
        var style = Font.system(size: Double(font.pointSize))
        let traits = font.fontDescriptor.symbolicTraits

        #if canImport(AppKit)
        if traits.contains(.bold) { style = style.bold() }
        if traits.contains(.italic) { style = style.italic() }
        if traits.contains(.monoSpace) { style = style.monospaced() }
        #elseif canImport(UIKit)
        if traits.contains(.traitBold) { style = style.bold() }
        if traits.contains(.traitItalic) { style = style.italic() }
        if traits.contains(.traitMonoSpace) { style = style.monospaced() }
        #endif

        self = style
    }
}
#endif
