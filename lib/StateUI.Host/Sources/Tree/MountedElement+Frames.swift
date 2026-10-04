// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI

/// Where an element stands, said to the tree that reads it, the same on every host.
/// Design: docs/design/host/runtime.md#where-a-view-stands
extension MountedElement {
    /// Whether the tree reads where this element itself stands: a state its frame drives, or a handler of its
    /// changes.
    public var readsOwnFrame: Bool {
        driven[.frame] != nil || events[.frameChanged] != nil || events[.namedFramesChanged] != nil
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
