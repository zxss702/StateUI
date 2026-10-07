// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI

@MainActor
extension AppKitElement {
    /// The `.pointerStyle`'s cursor on the view; AppKit owns pushing and
    /// popping it as the pointer crosses.
    func applyPointerStyle() {
        guard let view = view as? AppKitHitTestView else { return }
        view.pointerStyle = value(.pointerStyle)?.enumeration
            .flatMap { PointerStyle(rawValue: Int32($0)) }
            .flatMap(Self.cursor)
    }

    /// What a `PointerStyle` looks like in AppKit's cursors.
    private static func cursor(_ style: PointerStyle) -> NSCursor? {
        switch style {
        case .default: return nil
        case .text, .horizontalText, .alertText: return .iBeam
        case .verticalText: return .iBeamCursorForVerticalLayout
        case .link: return .pointingHand
        case .grabIdle: return .openHand
        case .grabActive: return .closedHand
        case .dragCopy: return .dragCopy
        case .dragLink: return .dragLink
        case .operationNotAllowed: return .operationNotAllowed
        case .rectangleSelection: return .crosshair
        case .columnResize: return .resizeLeftRight
        case .rowResize: return .resizeUpDown
        case .frameResize: return .resizeLeftRight
        }
    }

    /// What a `BlendMode` composits as in a CALayer's vocabulary.
    static func blendFilter(_ mode: Int32) -> String? {
        switch BlendMode(rawValue: mode) {
        case .normal, nil: return nil
        case .multiply: return "multiplyBlendMode"
        case .screen: return "screenBlendMode"
        case .overlay: return "overlayBlendMode"
        case .darken: return "darkenBlendMode"
        case .lighten: return "lightenBlendMode"
        case .colorDodge: return "colorDodgeBlendMode"
        case .colorBurn: return "colorBurnBlendMode"
        case .softLight: return "softLightBlendMode"
        case .hardLight: return "hardLightBlendMode"
        case .difference: return "differenceBlendMode"
        case .exclusion: return "exclusionBlendMode"
        case .hue: return "hueBlendMode"
        case .saturation: return "saturationBlendMode"
        case .color: return "colorBlendMode"
        case .luminosity: return "luminosityBlendMode"
        case .sourceAtop: return "sourceAtopBlendMode"
        case .destinationOver: return "destinationOverBlendMode"
        case .destinationOut: return "destinationOutBlendMode"
        case .plusDarker: return "plusDarkerBlendMode"
        case .plusLighter: return "plusLighterBlendMode"
        }
    }
}
#endif
