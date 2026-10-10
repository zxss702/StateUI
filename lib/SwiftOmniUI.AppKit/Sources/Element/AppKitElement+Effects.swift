// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// Where the last frame of an element that carried a `matchedGeometry`
/// identity goes while the patch it left in is applied: the next element to
/// arrive under the same key inherits the place its match stood, in window
/// coordinates.
@MainActor
enum AppKitMatchedGeometry {
    /// `key` -> the frame the element left, window coordinates. Bounded: an
    /// unmatched departure keeps no room forever.
    private static var frames: [(key: String, frame: NSRect)] = []

    /// Stands `frame` down for `key`, so the next element under it inherits it.
    static func retire(_ key: String, frame: NSRect) {
        frames.removeAll { $0.key == key }
        frames.append((key, frame))
        if frames.count > 32 { frames.removeFirst(frames.count - 32) }
    }

    /// The frame the last element under `key` left; taking it spends it, so a
    /// match joins once rather than flying into every later lookalike.
    static func take(_ key: String) -> NSRect? {
        guard let index = frames.firstIndex(where: { $0.key == key }) else { return nil }
        return frames.remove(at: index).frame
    }
}

extension AppKitElement {
    /// What this element's `matchedGeometry` key is, when it carries one and
    /// is written `isSource: true`.
    var matchedKey: String? {
        guard let key = string(.matchedGeometry), value(.matchedGeometrySource)?.bool != false
        else { return nil }
        return key
    }

    /// The frame an arriving element under `key` flies from, window
    /// coordinates; nil where no match left one.
    func matchedStart() -> Rect? {
        guard let key = matchedKey, let from = AppKitMatchedGeometry.take(key) else { return nil }
        return Rect(x: Double(from.minX), y: Double(from.minY),
                    width: Double(from.width), height: Double(from.height))
    }

    /// Leaves this element's frame for a match under the same key.
    func retireMatchedFrame() {
        guard let view, let key = matchedKey else { return }
        AppKitMatchedGeometry.retire(key, frame: view.convert(view.bounds, to: nil))
    }

    /// The symbol effect and content-transition parts of `changed`;
    /// `wasDescribed` is true where the element stands already.
    func applyEffects(changed: Set<Prop>, wasDescribed described: Bool) {
        guard let view else { return }

        // A content swap: the drawn words or picture changed under a
        // `.contentTransition` - push for a rolling number, a fade for the
        // rest; `identity` is the platform's plain swap.
        if let kind = string(.contentTransition),
           changed.contains(.text) || changed.contains(.source) || changed.contains(.icon) {
            let transition = CATransition()
            transition.duration = 0.18
            switch kind {
            case "numericText":
                transition.type = .push
                transition.subtype = .fromTop
            case "numericTextDown":
                transition.type = .push
                transition.subtype = .fromBottom
            case "identity":
                transition.duration = 0
            default:
                transition.type = .fade
            }
            if transition.duration > 0 {
                view.wantsLayer = true
                view.layer?.add(transition, forKey: "stateUIContentTransition")
            }
        }

        guard let effect = string(.symbolEffect) else { return }
        view.wantsLayer = true
        guard let layer = view.layer else { return }

        switch effect {
        case "bounce":
            // A `value:` write replays it each time the value moves; a plain
            // write plays it as the element arrives.
            guard changed.contains(.symbolEffectValue) || !described
            else { break }
            let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
            bounce.values = [1.0, 1.3, 0.9, 1.1, 1.0]
            bounce.keyTimes = [0, 0.3, 0.6, 0.8, 1.0]
            bounce.duration = 0.4
            layer.add(bounce, forKey: "stateUISymbolBounce")
        case "pulse":
            let active = value(.symbolEffectActive)?.bool ?? true
            let repeats = (value(.symbolEffectOptions)?.number ?? 0) > 0
            if active, repeats {
                if layer.animation(forKey: "stateUISymbolPulse") == nil {
                    let pulse = CABasicAnimation(keyPath: "opacity")
                    pulse.fromValue = 1.0
                    pulse.toValue = 0.35
                    pulse.duration = 0.8
                    pulse.autoreverses = true
                    pulse.repeatCount = .infinity
                    layer.add(pulse, forKey: "stateUISymbolPulse")
                }
            } else if active, !repeats, changed.contains(.symbolEffectValue) || !described {
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 1.0
                pulse.toValue = 0.35
                pulse.duration = 0.8
                pulse.autoreverses = true
                layer.add(pulse, forKey: "stateUISymbolPulseOnce")
            } else {
                layer.removeAnimation(forKey: "stateUISymbolPulse")
                layer.opacity = 1
            }
        default:
            break
        }
    }
}
#endif
