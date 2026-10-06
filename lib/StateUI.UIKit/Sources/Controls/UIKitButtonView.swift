// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(iOS)
import UIKit
@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// A Button: UIKit's own, its configuration what the tree says - its caption and their look, an icon beside it, the
/// box behind them and the room inside it; a tap is its click, and the press is heard as it goes down and is let go.
@MainActor
final class UIKitButtonView: UIButton {
    /// What the button does when the user taps it, and as a press goes down and is let go.
    var onClicked: (() -> Void)?
    var onPressed: (() -> Void)?
    var onReleased: (() -> Void)?

    /// What a staying-pressed button reports when a tap flips it - `isOn`
    /// worn on the element at all makes it one.
    var onToggled: ((Bool) -> Void)?

    /// Whether a tap keeps - `isOn` worn at all. What keeps nothing flips
    /// `isSelected` and gives it back, so the press only lasts the touch.
    private var toggleable = false

    private var look = TextLook()

    init() {
        super.init(frame: .zero)
        configuration = .plain()
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            onClicked?()
            if toggleable {
                isSelected.toggle()
                onToggled?(isSelected)
            }
        }, for: .primaryActionTriggered)
        addAction(UIAction { [weak self] _ in self?.onPressed?() }, for: .touchDown)
        addAction(UIAction { [weak self] _ in self?.onReleased?() }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("UIKitButtonView is made in code")
    }

    /// The staying-pressed look, or none: `nil` for a button that only
    /// flashes under the touch; worn at all the selected look keeps, and the
    /// user's flips come back through `onToggled`.
    func setOn(_ on: Bool?) {
        toggleable = on != nil
        isSelected = on ?? false
    }

    /// The button's words.
    func setText(_ text: String) {
        configuration?.title = text.isEmpty ? nil : text
        showLook()
    }

    /// Changes the words' look; what it leaves unsaid is the button's own.
    func setLook(_ change: (inout TextLook) -> Void) {
        change(&look)
        showLook()
    }

    /// The icon, where it stands beside the words, and the room between them.
    func setIcon(_ icon: UIImage?, position: IconPosition, spacing: Double?) {
        configuration?.image = icon
        configuration?.imagePlacement = switch position {
        case .leading: .leading
        case .top: .top
        case .trailing: .trailing
        case .bottom: .bottom
        }
        configuration?.imagePadding = spacing ?? 8
    }

    /// What `setBox` was last told, replayed when the style rebuilds the configuration.
    private var box: (background: HostValue?, stroke: HostValue?, width: Double?, shape: HostValue?)

    /// The logical style, as the configuration template it stands for.
    func setStyle(_ style: ButtonStyleKind?) {
        var made: UIButton.Configuration = switch style ?? .automatic {
        case .borderedProminent: .filled()
        case .bordered: .bordered()
        case .plain, .borderless, .link: .plain()
        default: .bordered()
        }
        made.title = configuration?.title
        made.image = configuration?.image
        made.imagePlacement = configuration?.imagePlacement ?? .leading
        made.imagePadding = configuration?.imagePadding ?? 8
        made.contentInsets = configuration?.contentInsets ?? made.contentInsets
        configuration = made
        let box = self.box
        setBox(background: box.background, stroke: box.stroke, width: box.width, shape: box.shape)
        showLook()
    }

    /// What fills the button's box, its outline and its shape (`BoxArithmetic`).
    func setBox(background: HostValue?, stroke: HostValue?, width: Double?, shape: HostValue?) {
        box = (background, stroke, width, shape)
        configuration?.background.backgroundColor = background.flatMap(UIColor.init(stateUI:))
        let outline = BoxArithmetic.outlineWidth(stroke: stroke, width: width)
        configuration?.background.strokeWidth = outline
        configuration?.background.strokeColor = outline > 0 ? UIKitBrush(stroke).lineColor : nil
        switch BoxArithmetic.outline(shape) {
        case .rectangle:
            configuration?.cornerStyle = .fixed
            configuration?.background.cornerRadius = 0
        case .roundedRectangle(let radius):
            configuration?.cornerStyle = .fixed
            configuration?.background.cornerRadius = radius
        case .ellipse, .capsule, .circle:
            configuration?.cornerStyle = .capsule
        }
    }

    /// The room between the button's edge and what it shows.
    func setPadding(_ insets: EdgeInsets?) {
        configuration?.contentInsets = insets.map {
            NSDirectionalEdgeInsets(top: $0.top, leading: $0.left, bottom: $0.bottom, trailing: $0.right)
        } ?? UIButton.Configuration.plain().contentInsets
    }

    /// How the words break.
    func setLineBreak(_ breaking: LineBreak) {
        configuration?.titleLineBreakMode = switch breaking {
        case .noWrap: .byClipping
        case .wordWrap: .byWordWrapping
        case .characterWrap: .byCharWrapping
        case .headTruncation: .byTruncatingHead
        case .tailTruncation: .byTruncatingTail
        case .middleTruncation: .byTruncatingMiddle
        }
    }

    private func showLook() {
        let attributes = look.attributes(standing: .preferredFont(forTextStyle: .body), color: tintColor)
        // The configuration keeps the transformer: it holds the look's values, never the button that holds it.
        let colored = look.color != nil
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = attributes[.font] as? UIFont
            if colored { outgoing.foregroundColor = attributes[.foregroundColor] as? UIColor }
            if let kern = attributes[.kern] as? Double { outgoing.uiKit.kern = kern }
            return outgoing
        }
    }
}
#endif
