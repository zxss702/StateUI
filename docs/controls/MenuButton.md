<!-- Rendered by ControlDictionaryTests from the contracts and the verdicts each host's runs of its tests wrote under exports/marks: SWIFTOMNIUI_UPDATE_DOCS=1 swift test --filter ControlDictionaryTests writes it again. -->

# MenuButton

A menu that lives in the view: a button whose label opens its entries.

Layer: `native`. Every base host presents it with its native toolkit.

Inherits: [PropertyContainer](tiers/PropertyContainer.md) · [VisualElement](tiers/VisualElement.md) · [View](tiers/View.md)

| Mark | Meaning |
| :---: | --- |
| ✅ | Proven by every test of it that ran on that host. |
| ☑️ | Proven, the host recording what is missing. |
| – | Never on that host's family, which meets the contract there. |
| ❌ | A test of it failed. |
| ◐ | Some of its tests proved it, another could not run or read. |
| 🔌 | Proven only through the host's own entry or record, not the toolkit's. |
| · | The driver cannot yet do or read what its test needs. |
| ⏸ | Its test waits on a member the host does not realize. |
| ⌛ | Said at another revision of its family than it stands at. |
| empty | Not realized, or no run - the note says which. |

See [the dictionary](README.md) for how a mark is given.

| Host | Created | Members (92) | Realization | Notes |
| --- | :---: | --- | --- | --- |
| AppKit |  | 24 ✅ · 1 ☑️ · 3 – | `AppKitMenuButtonView` (label + `NSMenu`) | no run of it on these sources |
| UIKit |  |  | `UIMenu` on a `UIButton` | no run of it on these sources |
| Android Views |  |  | `PopupMenu` on a button | no run of it on these sources |
| WinUI 3 |  |  | `DropDownButton` + `MenuFlyout` | no run of it on these sources |
| GTK 4 |  | 22 ✅ | `GtkMenuButton` + `GMenu` | no run of it on these sources |
| Web |  |  | `<details>` / ARIA `button` + `menu` | no host yet |

Declared in `lib/SwiftOmniUI/Sources/Contracts/Elements/Menus/MenuButtonContract.swift`.

## MenuButton's own members

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `menuIndicator` | property | `MenuIndicatorVisibility` | native |  |  |  |  |  |  |  |
| `menuStyle` | property | `String` | native |  |  |  |  |  |  |  |

## From [PropertyContainer](tiers/PropertyContainer.md)

What anything carrying values in the tree has - a control, a `Style`, a text run: the name automation finds it by.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `accessibilityIdentifier` | property | `String` | native | ✅ |  |  |  |  |  | UIKit: not realized; GTK 4: not realized |

## From [VisualElement](tiers/VisualElement.md)

What every drawn element has: its size and its bounds, how it is shown and turned, whether it answers input and holds the keyboard focus, the visual states it enters, and what a screen reader says about it.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `blendMode` | property | `BlendMode` | native |  |  |  |  |  |  |  |
| `accessibilityChildBehavior` | property | `AccessibilityChildBehavior` | native |  |  |  |  |  |  |  |
| `accessibilityHeadingLevel` | property | `HeadingLevel` | native | · |  |  |  | · |  | cannot read a heading's level - AppKit marks a heading, not its level; UIKit: not realized; GTK 4: cannot read accessibilityHeadingLevel of MenuButton - GTK's driver has no path for it yet |
| `accessibilityHint` | property | `String` | native | ✅ |  |  |  | · |  | UIKit: not realized; GTK 4: cannot read accessibilityHint of MenuButton - GTK's driver has no path for it yet |
| `accessibilityLabel` | property | `String` | native | ✅ |  |  |  | · |  | UIKit: not realized; GTK 4: cannot read accessibilityLabel of MenuButton - GTK's driver has no path for it yet |
| `accessibilityTraits` | property | `AccessibilityTraits` | native |  |  |  |  |  |  |  |
| `automationExcludedWithChildren` | property | `Bool` | native | ✅ |  |  |  | · |  | UIKit: not realized; GTK 4: cannot read automationExcludedWithChildren of MenuButton - GTK's driver has no path for it yet |
| `background` | property | `Background` | native | ☑️ |  |  |  |  |  | AppKit paints a colour on this view; a brush is drawn only by a layout.; UIKit: not realized; GTK 4: not realized |
| `blur` | property | `Double` | native |  |  |  |  |  |  |  |
| `contentTransition` | property | `String` | native |  |  |  |  |  |  |  |
| `focus` | act | `() -> Bool` |  | – |  |  |  | ✅ |  | MenuButton takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: not realized |
| `frame` | property | `Rect` | structure | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `height` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `hint` | property | `String` | native |  |  |  |  |  |  |  |
| `hintKey` | property | `LocalizedStringKey` | native |  |  |  |  |  |  |  |
| `ignoresInput` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; GTK 4: not realized |
| `isAccessibilityHidden` | property | `Bool` | native | ✅ |  |  |  | · |  | UIKit: not realized; GTK 4: cannot read isAccessibilityHidden of MenuButton - GTK's driver has no path for it yet |
| `isEnabled` | property | `Bool` | native | · |  |  |  | ✅ |  | cannot read isEnabled of MenuButton - AppKit's driver has no path for it yet; UIKit: not realized |
| `isFocusedChanged` | event | `Bool` | native | – |  |  |  | ✅ |  | MenuButton takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: not realized |
| `isVisible` | property | `Bool` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `layoutDirection` | property | `LayoutDirection` | native |  |  |  |  | · |  | not realized; UIKit: not realized; GTK 4: cannot read layoutDirection of MenuButton - GTK's driver has no path for it yet |
| `matchedGeometry` | property | `String` | native |  |  |  |  |  |  |  |
| `matchedGeometrySource` | property | `Bool` | native |  |  |  |  |  |  |  |
| `maximumHeight` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `maximumWidth` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `minimumHeight` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `minimumWidth` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `opacity` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `pivotX` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read pivotX of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read pivotX of MenuButton - GTK's driver has no path for it yet |
| `pivotY` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read pivotY of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read pivotY of MenuButton - GTK's driver has no path for it yet |
| `rotation` | property | `Angle` | native | 🔌 |  |  |  | · |  | only through the host's own: read rotation of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read rotation of MenuButton - GTK's driver has no path for it yet |
| `rotationX` | property | `Angle` | native | 🔌 |  |  |  | · |  | only through the host's own: read rotationX of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read rotationX of MenuButton - GTK's driver has no path for it yet |
| `rotationY` | property | `Angle` | native | 🔌 |  |  |  | · |  | only through the host's own: read rotationY of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read rotationY of MenuButton - GTK's driver has no path for it yet |
| `scale` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read scale of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read scale of MenuButton - GTK's driver has no path for it yet |
| `scaleX` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read scaleX of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read scaleX of MenuButton - GTK's driver has no path for it yet |
| `scaleY` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read scaleY of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read scaleY of MenuButton - GTK's driver has no path for it yet |
| `shadow` | property | `DropShadow` | native |  |  |  |  |  |  |  |
| `style` | property | `Name` | structure |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `symbolEffect` | property | `String` | native |  |  |  |  |  |  |  |
| `symbolEffectActive` | property | `Bool` | native |  |  |  |  |  |  |  |
| `symbolEffectOptions` | property | `Int` | native |  |  |  |  |  |  |  |
| `symbolEffectValue` | property | `String` | native |  |  |  |  |  |  |  |
| `transition` | property | `AnyTransition` | native |  |  |  |  |  |  |  |
| `translationX` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read translationX of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read translationX of MenuButton - GTK's driver has no path for it yet |
| `translationY` | property | `Double` | native | 🔌 |  |  |  | · |  | only through the host's own: read translationY of MenuButton: the host's own transform, checked against the layer it composed itself; UIKit: not realized; GTK 4: cannot read translationY of MenuButton - GTK's driver has no path for it yet |
| `unfocus` | act | `() -> Void` |  | – |  |  |  | ✅ |  | MenuButton takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: not realized |
| `width` | property | `Double` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `zIndex` | property | `Double` | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |

## From [View](tiers/View.md)

What every view a layout positions has: where it sits in its layout, the space kept around it, and the gestures, drags and frame reports it answers.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `allowDrop` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `area` | property | `Area` | structure | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `canDrag` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `coordinateSpaceName` | property | `String` | stateUI |  |  |  |  |  |  |  |
| `dragLeave` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `dragOver` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `dragStarting` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `dragText` | property | `String` | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `onDrop` (`drop`) | event | `String` | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `dropCompleted` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; GTK 4: not realized |
| `dropPaths` | event | `([String], Point)` | native |  |  |  |  |  |  |  |
| `flex` | property | `Double` | stateUI |  |  |  |  |  |  |  |
| `frameChanged` | event | `[Double]` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `gridColumn` | property | `Int` | stateUI | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `gridColumnSpan` | property | `Int` | stateUI | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `gridRow` | property | `Int` | stateUI | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `gridRowSpan` | property | `Int` | stateUI | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `horizontalAlignment` | property | `AxisAlignment` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `horizontalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |
| `layoutPriority` | property | `Double` | stateUI |  |  |  |  |  |  |  |
| `namedFramesChanged` | event | `[NamedSpaceFrame]` | native |  |  |  |  |  |  |  |
| `padding` | property | `EdgeInsets` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `panTouchCount` | property | `Int` | structure | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `onPanUpdated` (`panUpdated`) | event | `(GesturePhase, Double, Double, Point?, Point?)` | native | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `panXChannel` | property | `Int` | structure | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `panYChannel` | property | `Int` | structure | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `pinchUpdated` | event | `(GesturePhase, Double, Point)` | native | 🔌 |  |  |  | · |  | only through the host's own: pinch on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pinch on MenuButton - GTK's driver has no path for it yet |
| `pointerEntered` | event |  | native | 🔌 |  |  |  | · |  | only through the host's own: hover on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot hover on MenuButton - GTK's driver has no path for it yet |
| `pointerExited` | event |  | native | 🔌 |  |  |  | · |  | only through the host's own: hover on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot hover on MenuButton - GTK's driver has no path for it yet |
| `pointerMoved` | event | `Point?` | native | 🔌 |  |  |  | · |  | only through the host's own: hover on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot hover on MenuButton - GTK's driver has no path for it yet |
| `pointerPressed` | event | `Point?` | native | 🔌 |  |  |  | · |  | only through the host's own: hover on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot hover on MenuButton - GTK's driver has no path for it yet |
| `pointerReleased` | event | `Point?` | native | 🔌 |  |  |  | · |  | only through the host's own: hover on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot hover on MenuButton - GTK's driver has no path for it yet |
| `pointerStyle` | property | `PointerStyle` | native |  |  |  |  |  |  |  |
| `swipeDirection` | property | `SwipeDirection` | structure | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `swipeThreshold` | property | `Double` | structure | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `onSwiped` (`swiped`) | event | `SwipeDirection` | native | 🔌 |  |  |  | · |  | only through the host's own: pan on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot pan on MenuButton - GTK's driver has no path for it yet |
| `tag` | property | `PropValue` | stateUI |  |  |  |  |  |  |  |
| `tapCount` | property | `Int` | structure | 🔌 |  |  |  | · |  | only through the host's own: tap on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot tap on MenuButton - GTK's driver has no path for it yet |
| `onTapGesture` (`tapGesture`) | event |  | native | 🔌 |  |  |  | · |  | only through the host's own: tap on MenuButton: handed to the host's recognizer or handler, no NSEvent sent; UIKit: not realized; GTK 4: cannot tap on MenuButton - GTK's driver has no path for it yet |
| `verticalAlignment` | property | `AxisAlignment` | native | ✅ |  |  |  | ✅ |  | UIKit: not realized |
| `verticalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |
