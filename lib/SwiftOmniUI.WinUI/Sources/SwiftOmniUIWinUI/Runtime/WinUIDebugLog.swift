// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if DEBUG
import Foundation

/// Temporary scrolling diagnostics: one line per event in C:\Users\zxs20\lui-lazy.log.
@MainActor
enum WinUIDebugLog {
    private static var opened = false
    private static var pending = ""

    static func log(_ line: String) {
        let stamp = String(format: "%.1f", ProcessInfo.processInfo.systemUptime * 1000)
        pending += "\(stamp)  \(line)\n"
        if pending.count > 4096 { flush() }
    }

    static func flush() {
        guard !pending.isEmpty else { return }
        let url = URL(fileURLWithPath: #"C:\Users\zxs20\lui-lazy.log"#)
        if !opened {
            opened = true
            try? pending.write(to: url, atomically: true, encoding: .utf8)
        } else if let file = try? FileHandle(forWritingTo: url) {
            defer { try? file.close() }
            _ = try? file.seekToEnd()
            try? file.write(contentsOf: Data(pending.utf8))
        }
        pending = ""
    }
}
#endif
