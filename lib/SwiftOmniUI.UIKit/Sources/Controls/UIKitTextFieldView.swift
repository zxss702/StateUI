// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import SwiftOmniUICore
@_spi(Host) import SwiftOmniUIHost

/// A TextField: UIKit's own field on one line. The user's words are reported; the program's are only written.
@MainActor
final class UIKitTextFieldView: UITextField, UIKitInputView {
    let typing = UIKitTyping()

    private let madeFont = UIFont.preferredFont(forTextStyle: .body)

    init() {
        super.init(frame: .zero)
        borderStyle = .roundedRect
        font = madeFont
        hearTyping()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("UIKitTextFieldView is made in code")
    }

    func setLook(_ look: TextLook) {
        font = .stateUI(look, standing: madeFont)
        textColor = look.color.flatMap(UIColor.init(stateUI:)) ?? .label
    }

    /// The logical style, as the border UITextField draws for it.
    func setStyle(_ style: TextFieldStyleKind?) {
        borderStyle = switch style ?? .automatic {
        case .plain: .none
        case .squareBorder: .line
        default: .roundedRect
        }
    }
}
#endif
