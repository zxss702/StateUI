// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import CSwiftOmniUIGTK

/// The logical symbol names `Image(systemName:)` writes, mapped to the
/// freedesktop icon names the platform's icon theme calls them - the system's
/// own symbols, drawn as the theme draws them.
///
/// A name is asked of the icon theme rather than a file table, so whichever
/// theme the user runs answers it; a name nobody knows answers the theme's
/// missing-image icon.
enum GTKSymbols {
    /// The file the icon theme keeps `name`'s icon at, or nil where the theme has none.
    static func path(of name: String, size: Int32 = 32) -> String? {
        guard let display = gdk_display_get_default() else { return nil }
        guard let theme = gtk_icon_theme_get_for_display(display) else { return nil }
        let iconName = icons[name] ?? "image-missing"
        guard let icon = g_themed_icon_new(iconName) else { return nil }
        defer { g_object_unref(UnsafeMutableRawPointer(icon)) }
        let scale = 1
        let paintable = gtk_icon_theme_lookup_by_gicon(
            theme, icon, size, Int32(scale), GTK_TEXT_DIR_LTR, GTK_ICON_LOOKUP_FORCE_SYMBOLIC)
        guard let paintable, let file = gtk_icon_paintable_get_file(paintable) else { return nil }
        defer {
            g_object_unref(UnsafeMutableRawPointer(paintable))
            g_object_unref(UnsafeMutableRawPointer(file))
        }
        return g_file_get_path(file).map { String(cString: $0) }
    }

    /// `systemName` to freedesktop icon name, on the names SF Symbols calls things.
    private static let icons: [String: String] = [
        "alarm": "alarm-symbolic",
        "arrow.clockwise": "view-refresh-symbolic",
        "arrow.down": "go-down-symbolic",
        "arrow.left": "go-previous-symbolic",
        "arrow.right": "go-next-symbolic",
        "arrow.up": "go-up-symbolic",
        "bell": "preferences-system-notifications-symbolic",
        "book": "x-office-document-symbolic",
        "bookmark": "bookmark-new-symbolic",
        "calendar": "x-office-calendar-symbolic",
        "camera": "camera-photo-symbolic",
        "checkmark": "emblem-ok-symbolic",
        "checkmark.circle": "emblem-ok-symbolic",
        "chevron.down": "pan-down-symbolic",
        "chevron.left": "go-previous-symbolic",
        "chevron.right": "go-next-symbolic",
        "chevron.up": "pan-up-symbolic",
        "clock": "preferences-system-time-symbolic",
        "doc": "text-x-generic-symbolic",
        "ellipsis": "view-more-symbolic",
        "envelope": "mail-unread-symbolic",
        "eye": "view-reveal-symbolic",
        "eye.slash": "view-conceal-symbolic",
        "flag": "flag-thick-symbolic",
        "folder": "folder-symbolic",
        "folder.fill": "folder-symbolic",
        "gear": "emblem-system-symbolic",
        "gearshape": "emblem-system-symbolic",
        "gearshape.fill": "emblem-system-symbolic",
        "globe": "applications-internet-symbolic",
        "heart": "emblem-favorite-symbolic",
        "heart.fill": "starred-symbolic",
        "house": "go-home-symbolic",
        "house.fill": "go-home-symbolic",
        "link": "insert-link-symbolic",
        "list.bullet": "view-list-symbolic",
        "lock": "system-lock-screen-symbolic",
        "lock.fill": "system-lock-screen-symbolic",
        "lock.open": "channel-secure-symbolic",
        "magnifyingglass": "system-search-symbolic",
        "minus": "list-remove-symbolic",
        "moon": "night-light-symbolic",
        "paintbrush": "applications-graphics-symbolic",
        "paperplane": "mail-send-symbolic",
        "pause.fill": "media-playback-pause-symbolic",
        "pencil": "document-edit-symbolic",
        "person": "avatar-default-symbolic",
        "person.fill": "avatar-default-symbolic",
        "phone": "call-start-symbolic",
        "photo": "insert-image-symbolic",
        "pin": "mark-location-symbolic",
        "play.fill": "media-playback-start-symbolic",
        "plus": "list-add-symbolic",
        "printer": "printer-symbolic",
        "questionmark": "dialog-question-symbolic",
        "questionmark.circle": "dialog-question-symbolic",
        "questionmark.square": "dialog-question-symbolic",
        "square.and.arrow.up": "document-send-symbolic",
        "star": "non-starred-symbolic",
        "star.fill": "starred-symbolic",
        "stop.fill": "media-playback-stop-symbolic",
        "sun.max": "display-brightness-symbolic",
        "tag": "tag-symbolic",
        "trash": "user-trash-symbolic",
        "trash.fill": "user-trash-symbolic",
        "tray": "mail-folder-inbox-symbolic",
        "wifi": "network-wireless-symbolic",
        "wifi.slash": "network-wireless-disabled-symbolic",
        "xmark": "window-close-symbolic",
        "xmark.circle": "window-close-symbolic",
    ]
}
