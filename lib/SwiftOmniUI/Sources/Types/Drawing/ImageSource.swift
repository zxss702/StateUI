// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// Where a picture comes from: one file, or one for each color scheme.
// Design: docs/design/types/colour-and-color-scheme.md#pictures-for-each-color-scheme

/// A picture, by file name.
///
///     Image("tab_list.png")
///     ToolbarItem("Media").icon("tab_list.png")
///     Image(light: "tab_list.png", dark: "tab_list_dark.png")
///
/// A file in the application's `Resources/Images`, by name. An SVG is asked
/// for by its `.png` name - `tab_list.svg` as `tab_list.png` - and the host
/// finds the SVG where no PNG of that name exists. A plain string is one of
/// these, so only artwork that differs between the themes needs the type
/// written out.
public struct ImageSource: Equatable, Sendable, ExpressibleByStringLiteral, HostRepresentable {
    /// The file, by name - empty where the picture is a symbol instead.
    public let file: String

    /// The file to use when the system is in dark mode, when there is one.
    public let dark: String?

    /// A logical symbol's name - what `Image(systemName:)` writes, drawn by
    /// each platform's own symbol set: SF Symbols on Apple's, the Fluent icons
    /// on Windows, the toolkit's theme icons elsewhere.
    public let symbol: String?

    /// One picture, by file name.
    public init(_ file: String) {
        self.file = file
        self.dark = nil
        self.symbol = nil
    }

    /// Two files, one for each color scheme; the element showing the picture follows
    /// the system color scheme.
    ///
    ///     ImageSource(light: "logo.png", dark: "logo_dark.png")
    ///
    /// For artwork that would vanish into one of the two backgrounds. A
    /// picture that reads on both is one file and a plain string.
    public init(light: String, dark: String) {
        self.file = light
        self.dark = dark
        self.symbol = nil
    }

    /// A symbol from the platform's set, by its cross-platform name -
    /// `Image(systemName: "star")`.
    ///
    /// The name is the contract: every host maps it to the glyph it owns. A
    /// name a platform's set does not know draws its fallback glyph there.
    public static func symbol(_ name: String) -> ImageSource {
        ImageSource(file: "", dark: nil, symbol: name)
    }

    private init(file: String, dark: String?, symbol: String?) {
        self.file = file
        self.dark = dark
        self.symbol = symbol
    }

    /// What lets every one-picture call site stay a plain string:
    /// `Image("tab_list.png")`, `.icon("tab_list.png")`.
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// Whether it names anything at all - what a view asks before drawing one.
    public var isEmpty: Bool { file.isEmpty && symbol == nil }

    /// The file name as text, or both names as a themed pair - and a symbol's
    /// name as a name from the open vocabulary.
    ///
    /// Design: docs/design/types/values.md#text-and-names
    public var propValue: PropValue {
        if let symbol { return .name(symbol) }
        guard let dark else { return .string(file) }

        return .themed(light: .string(file), dark: .string(dark))
    }

    /// A picture back: one file's name, a pair of them, or a symbol's - nil
    /// for anything else.
    /// - Parameter propValue: what the host sent.
    public init?(propValue: PropValue) {
        switch propValue {
        case .string(let file):
            self.init(file)
        case .name(let symbol):
            self = .symbol(symbol)
        case .themed(light: .string(let light), dark: .string(let dark)):
            self.init(light: light, dark: dark)
        default:
            return nil
        }
    }

    /// Read back off a node, for the templates that are handed an item and have
    /// to draw it - a pair coming back as the pair it was written as.
    init(_ value: PropValue?) {
        if case .name(let symbol) = value {
            self = .symbol(symbol)
        } else if case .themed(let light, let dark) = value {
            self.init(light: light.string ?? "", dark: dark.string ?? "")
        } else {
            self.init(value?.string ?? "")
        }
    }
}
