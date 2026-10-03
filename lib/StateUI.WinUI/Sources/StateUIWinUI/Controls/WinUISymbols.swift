// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The logical symbol names `Image(systemName:)` writes, mapped to the Segoe
/// Fluent Icons glyph each stands for - the platform's own symbol set.
///
/// The table is Swift's rather than the relay's, so a name is mapped where a
/// rebuild is cheap; the codepoint and not the name crosses. A name nobody
/// knows answers the question mark.
enum WinUISymbols {
    /// The Fluent glyph `name` draws, or the question mark's.
    static func glyph(named name: String) -> UInt32 {
        glyphs[name] ?? glyphs["__fallback__"]!
    }

    /// `systemName` to codepoint, on the names SF Symbols calls things.
    private static let glyphs: [String: UInt32] = [
        "alarm": 0xE856,
        "arrow.clockwise": 0xE72C,
        "arrow.counterclockwise": 0xE72B,
        "arrow.down": 0xE74B,
        "arrow.left": 0xE72B,
        "arrow.right": 0xE72A,
        "arrow.up": 0xE74A,
        "bell": 0xEA8F,
        "bell.fill": 0xEA8F,
        "bell.slash": 0xEA8D,
        "book": 0xE82D,
        "bookmark": 0xE8A4,
        "bookmark.fill": 0xEB41,
        "calendar": 0xE787,
        "camera": 0xE722,
        "checkmark": 0xE73E,
        "checkmark.circle": 0xE73E,
        "checkmark.circle.fill": 0xF168,
        "chevron.down": 0xE70D,
        "chevron.left": 0xE76B,
        "chevron.right": 0xE76C,
        "chevron.up": 0xE70E,
        "clock": 0xE917,
        "doc": 0xE8A5,
        "doc.fill": 0xE8A5,
        "ellipsis": 0xE712,
        "envelope": 0xE715,
        "envelope.fill": 0xE8A8,
        "eye": 0xE7B3,
        "eye.slash": 0xED1A,
        "flag": 0xE7C1,
        "folder": 0xE8B7,
        "folder.fill": 0xE8D5,
        "gear": 0xE713,
        "gearshape": 0xE713,
        "gearshape.fill": 0xE713,
        "globe": 0xE774,
        "heart": 0xEB51,
        "heart.fill": 0xEB52,
        "house": 0xE80F,
        "house.fill": 0xEA8A,
        "link": 0xE71B,
        "list.bullet": 0xE8FD,
        "lock": 0xE72E,
        "lock.fill": 0xE72E,
        "lock.open": 0xE785,
        "magnifyingglass": 0xE721,
        "minus": 0xE738,
        "moon": 0xE708,
        "paintbrush": 0xED03,
        "paperplane": 0xE724,
        "paperplane.fill": 0xEB0D,
        "pause.fill": 0xE769,
        "pencil": 0xE70F,
        "person": 0xE77B,
        "person.fill": 0xE77B,
        "phone": 0xE717,
        "photo": 0xEB9F,
        "pin": 0xE718,
        "play.fill": 0xE768,
        "plus": 0xE710,
        "printer": 0xE749,
        "questionmark": 0xE897,
        "questionmark.circle": 0xE897,
        "questionmark.square": 0xE897,
        "square.and.arrow.up": 0xE72D,
        "star": 0xE734,
        "star.fill": 0xE735,
        "stop.fill": 0xE71A,
        "sun.max": 0xE706,
        "tag": 0xE8EC,
        "trash": 0xE74D,
        "trash.fill": 0xE74D,
        "tray": 0xEC42,
        "wifi": 0xE701,
        "wifi.slash": 0xEB55,
        "xmark": 0xE711,
        "xmark.circle": 0xE711,

        "__fallback__": 0xE897,
    ]
}
