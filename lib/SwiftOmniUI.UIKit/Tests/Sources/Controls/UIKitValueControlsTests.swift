// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

import UIKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost
@testable import SwiftOmniUIUIKit
import XCTest

/// A value in a range on UIKit's controls, by the host layer's arithmetic (`ValueArithmetic`).
final class UIKitValueControlsTests: XCTestCase {
    /// A range the tree gives the wrong way round stands the lower end first, and a step that is no positive number
    /// moves by one - as on every host.
    @MainActor
    func testAReversedRangeStandsInOrderAndAStepThatCannotMoveIsOne() {
        let slider = UIKitSliderView()
        slider.apply(value: 5, minimum: 10, maximum: 0)
        XCTAssertEqual([slider.minimumValue, slider.maximumValue], [0, 10])

        let stepper = UIKitStepperView()
        stepper.apply(value: 5, minimum: 10, maximum: 0, step: .infinity)
        XCTAssertEqual([stepper.minimumValue, stepper.maximumValue, stepper.stepValue], [0, 10, 1])
    }
}
