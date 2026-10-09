// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import SwiftOmniUI

/// Where an element stands, said to the tree that reads it, the same on every host.
/// Design: docs/design/host/runtime.md#where-a-view-stands
extension MountedElement {
    /// Whether this element receives its position, including Text's passive
    /// origin report. Only business geometry reads set `framesRead`.
    public var readsOwnFrame: Bool {
        driven[.frame] != nil || events[.frameChanged] != nil
            || events[.namedFramesChanged] != nil || events[.textFrameChanged] != nil
    }

    /// Says where the element stands - `numbers`, a frame report's ten, and the named spaces enclosing it -
    /// where that changed since it last said: its place in its parent onto the state its frame drives, the
    /// named spaces ahead of the numbers so one pass hears them together, and the whole report to its handler.
    public func reportFrame(_ numbers: [Double], named: [NamedSpaceFrame], in runtime: HostRuntime) {
        guard readsOwnFrame else { return }
        if named != reportedNamedFrames {
            reportedNamedFrames = named
            if let handler = handler(.namedFramesChanged) {
                runtime.dispatch(handler, payload: [named.propValue])
            }
        }
        guard numbers != reportedFrame else { return }
        reportedFrame = numbers
        if let binding = driven[.frame] {
            runtime.report(.lanes(Array(numbers.prefix(4))), through: binding)
        }
        if let handler = handler(.frameChanged) {
            runtime.dispatch(handler, payload: [.numbers(numbers)])
        }
        if let handler = handler(.textFrameChanged) {
            runtime.dispatch(handler, payload: [.numbers(numbers)])
        }
    }

    /// Says how the typesetter laid the words out, where a handler hears it -
    /// the same report again says nothing (`TextLayoutReport` crossing
    /// `textLayoutChanged`).
    public func reportTextLayout(_ report: TextLayoutReport, in runtime: HostRuntime) {
        guard let handler = handler(.textLayoutChanged), report != reportedTextLayout else { return }
        reportedTextLayout = report
        runtime.dispatch(handler, payload: [report.propValue])
    }

    /// The named coordinate spaces enclosing this element, innermost first - each name an ancestor declared
    /// and that ancestor's frame in window coordinates, `windowRect` answering the latter the host's way.
    public func namedSpaceFrames(windowRect: (MountedElement) -> Rect?) -> [NamedSpaceFrame] {
        var frames: [NamedSpaceFrame] = []
        var element = parent
        while let ancestor = element {
            if let name = resolvedValue(.coordinateSpaceName)?.string,
               let frame = windowRect(ancestor) {
                frames.append(NamedSpaceFrame(name: name, frame: frame))
            }
            element = ancestor.parent
        }
        return frames
    }

    /// A frame report's ten numbers for a view standing at `place` in its parent, its top left corner at `corner`
    /// in its window, and the window's content - clear of its chrome - standing at `safeArea` in the window: the
    /// place, the corner in the window, and the safe area's own frame there, whose origin measures the view's
    /// corner in safe-area space and whose size bounds the insets it leaves inside the view.
    public static func frameNumbers(place: Rect, corner: Point, safeArea: Rect) -> [Double] {
        [place.x, place.y, place.width, place.height, corner.x, corner.y,
         safeArea.x, safeArea.y, safeArea.width, safeArea.height]
    }
}
