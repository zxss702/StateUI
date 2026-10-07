<!-- Rendered by ControlDictionaryTests from the contracts and the verdicts each host's runs of its tests wrote under exports/marks: SWIFTOMNIUI_UPDATE_DOCS=1 swift test --filter ControlDictionaryTests writes it again. -->

# ScrollView

A scrollable container.

Layer: `native`. Every base host presents it with its native toolkit.

Inherits: [PropertyContainer](tiers/PropertyContainer.md) · [VisualElement](tiers/VisualElement.md) · [View](tiers/View.md) · [Layout](tiers/Layout.md) · [PaddingElement](tiers/PaddingElement.md) · [BorderElement](tiers/BorderElement.md) · [ScrollContentElement](tiers/ScrollContentElement.md)

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

| Host | Created | Members (112) | Realization | Notes |
| --- | :---: | --- | --- | --- |
| AppKit | ✅ | 33 ✅ · 2 ☑️ · 3 – | `NSScrollView` |  |
| UIKit | ✅ | 33 ✅ · 3 – | `UIScrollView` |  |
| Android Views | ✅ | 52 ✅ · 1 ☑️ · 3 – | `ScrollView` / `HorizontalScrollView` |  |
| WinUI 3 | ✅ | 60 ✅ · 3 – | `ScrollViewer` |  |
| GTK 4 | ✅ | 30 ✅ | `GtkScrolledWindow` |  |
| Web |  |  | `overflow: auto` | no host yet |

Declared in `lib/SwiftOmniUI/Sources/Contracts/Elements/Layouts/ScrollViewContract.swift`.

## ScrollView's own members

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `defaultScrollAnchor` | property | `UnitPoint` | native |  |  |  |  |  |  |  |
| `horizontalScrollIndicators` | property | `ScrollIndicatorVisibility` | adaptive | ✅ | · | ✅ | ✅ | ✅ |  | UIKit: cannot read horizontalScrollIndicators of ScrollView - UIKit shows a scroll indicator only while the user scrolls: always and as UIKit decides show alike |
| `isScrollDisabled` | property | `Bool` | native |  |  |  |  |  |  |  |
| `orientation` | property | `Axis` | native | ✅ | ✅ | ◐ | ✅ | ✅ |  | Android Views: cannot scroll on ScrollView - Android's driver has no path for it yet |
| `scrollBounceBehavior` | property | `ScrollBounceBehavior` | native |  |  |  |  |  |  |  |
| `scrollOffset` | property | `Point` | structure | ✅ | ✅ | · | ✅ | ✅ |  | Android Views: cannot read scrollOffset of ScrollView - Android's driver has no path for it yet |
| `onScrollStopped` (`scrollStopped`) | event |  | native | 🔌 | ✅ | · | ✅ | ✅ |  | only through the host's own: scroll on ScrollView: the host's movement moved, not the clip view; Android Views: cannot scroll on ScrollView - Android's driver has no path for it yet |
| `scrollTargetBehavior` | property | `ScrollTargetBehavior` | native |  |  |  |  |  |  |  |
| `scrollToDescendant` | act | `(String, Double?, Double?) -> Void` |  |  |  |  |  |  |  |  |
| `scrollXChanged` | event | `Double` | native | 🔌 | ✅ | · | ✅ | ✅ |  | only through the host's own: scroll on ScrollView: the host's movement moved, not the clip view; Android Views: cannot scroll on ScrollView - Android's driver has no path for it yet |
| `scrollYChanged` | event | `Double` | native | ✅ | ✅ | · | ✅ | ✅ |  | Android Views: cannot read scrollOffset of ScrollView - Android's driver has no path for it yet |
| `verticalScrollIndicators` | property | `ScrollIndicatorVisibility` | adaptive | ✅ | · | ✅ | ✅ | ✅ |  | UIKit: cannot read verticalScrollIndicators of ScrollView - UIKit shows a scroll indicator only while the user scrolls: always and as UIKit decides show alike |

## From [PropertyContainer](tiers/PropertyContainer.md)

What anything carrying values in the tree has - a control, a `Style`, a text run: the name automation finds it by.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `accessibilityIdentifier` | property | `String` | native | ✅ | ✅ | ✅ | ✅ |  |  | GTK 4: not realized |

## From [VisualElement](tiers/VisualElement.md)

What every drawn element has: its size and its bounds, how it is shown and turned, whether it answers input and holds the keyboard focus, the visual states it enters, and what a screen reader says about it.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `blendMode` | property | `BlendMode` | native |  |  |  |  |  |  |  |
| `accessibilityChildBehavior` | property | `AccessibilityChildBehavior` | native |  |  |  |  |  |  |  |
| `accessibilityHeadingLevel` | property | `HeadingLevel` | native | · | · | · | ✅ | · |  | cannot read a heading's level - AppKit marks a heading, not its level; UIKit: cannot read a heading's level - UIKit marks a heading, not its level; Android Views: cannot read a heading's level - Android marks a heading, not its level; GTK 4: cannot read accessibilityHeadingLevel of ScrollView - GTK's driver has no path for it yet |
| `accessibilityHint` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityHint of ScrollView - GTK's driver has no path for it yet |
| `accessibilityLabel` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityLabel of ScrollView - GTK's driver has no path for it yet |
| `accessibilityTraits` | property | `AccessibilityTraits` | native |  |  |  |  |  |  |  |
| `automationExcludedWithChildren` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read automationExcludedWithChildren of ScrollView - GTK's driver has no path for it yet |
| `background` | property | `Background` | native | ☑️ | ✅ | ✅ | ✅ | · |  | AppKit paints a colour on this view; a brush is drawn only by a layout.; GTK 4: cannot read background of ScrollView - SwiftOmniUI draws a layout's box on GTK's snapshot, which holds none of its background; its drawing proves it |
| `blur` | property | `Double` | native |  |  |  |  |  |  |  |
| `contentTransition` | property | `String` | native |  |  |  |  |  |  |  |
| `focus` | act | `() -> Bool` |  | – | – | – | – | ✅ |  | ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard |
| `frame` | property | `Rect` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `height` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `hint` | property | `String` | native |  |  |  |  |  |  |  |
| `hintKey` | property | `LocalizedStringKey` | native |  |  |  |  |  |  |  |
| `ignoresInput` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isAccessibilityHidden` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read isAccessibilityHidden of ScrollView - GTK's driver has no path for it yet |
| `isEnabled` | property | `Bool` | native |  |  |  |  | ✅ |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized |
| `isFocusedChanged` | event | `Bool` | native | – | – | – | – | ✅ |  | ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard |
| `isVisible` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `layoutDirection` | property | `LayoutDirection` | native |  |  |  |  | · |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: cannot read layoutDirection of ScrollView - GTK's driver has no path for it yet |
| `matchedGeometry` | property | `String` | native |  |  |  |  |  |  |  |
| `matchedGeometrySource` | property | `Bool` | native |  |  |  |  |  |  |  |
| `maximumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `maximumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `opacity` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `pivotX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotX of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotX of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotX of ScrollView - GTK's driver has no path for it yet |
| `pivotY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotY of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotY of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotY of ScrollView - GTK's driver has no path for it yet |
| `rotation` | property | `Angle` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read rotation of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotation of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read rotation of ScrollView - GTK's driver has no path for it yet |
| `rotationX` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationX of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationX of ScrollView: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationX of ScrollView - GTK's driver has no path for it yet |
| `rotationY` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationY of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationY of ScrollView: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationY of ScrollView - GTK's driver has no path for it yet |
| `scale` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scale of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scale of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scale of ScrollView - GTK's driver has no path for it yet |
| `scaleX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleX of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleX of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleX of ScrollView - GTK's driver has no path for it yet |
| `scaleY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleY of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleY of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleY of ScrollView - GTK's driver has no path for it yet |
| `shadow` | property | `DropShadow` | native |  |  |  |  |  |  |  |
| `style` | property | `Name` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `symbolEffect` | property | `String` | native |  |  |  |  |  |  |  |
| `symbolEffectActive` | property | `Bool` | native |  |  |  |  |  |  |  |
| `symbolEffectOptions` | property | `Int` | native |  |  |  |  |  |  |  |
| `symbolEffectValue` | property | `String` | native |  |  |  |  |  |  |  |
| `transition` | property | `AnyTransition` | native |  |  |  |  |  |  |  |
| `translationX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationX of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationX of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationX of ScrollView - GTK's driver has no path for it yet |
| `translationY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationY of ScrollView: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationY of ScrollView: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationY of ScrollView - GTK's driver has no path for it yet |
| `unfocus` | act | `() -> Void` |  | – | – | – | – | ✅ |  | ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: ScrollView takes no keyboard focus here: it refuses it, and nothing is heard |
| `width` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `zIndex` | property | `Double` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |

## From [View](tiers/View.md)

What every view a layout positions has: where it sits in its layout, the space kept around it, and the gestures, drags and frame reports it answers.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `allowDrop` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `area` | property | `Area` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `canDrag` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `coordinateSpaceName` | property | `String` | stateUI |  |  |  |  |  |  |  |
| `dragLeave` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `dragOver` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `dragStarting` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `dragText` | property | `String` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `onDrop` (`drop`) | event | `String` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `dropCompleted` | event |  | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `dropPaths` | event | `([String], Point)` | native |  |  |  |  |  |  |  |
| `flex` | property | `Double` | stateUI |  |  |  |  |  |  |  |
| `frameChanged` | event | `[Double]` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `gridColumn` | property | `Int` | stateUI | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `gridColumnSpan` | property | `Int` | stateUI | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `gridRow` | property | `Int` | stateUI | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `gridRowSpan` | property | `Int` | stateUI | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `horizontalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `horizontalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |
| `layoutPriority` | property | `Double` | stateUI |  |  |  |  |  |  |  |
| `namedFramesChanged` | event | `[NamedSpaceFrame]` | native |  |  |  |  |  |  |  |
| `padding` | property | `EdgeInsets` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `panTouchCount` | property | `Int` | structure | 🔌 | 🔌 | ☑️ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; Android Views: The host layer hears a one-finger pan only; any other `panTouchCount` turns the pan off.; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `onPanUpdated` (`panUpdated`) | event | `(GesturePhase, Double, Double, Point?, Point?)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `panXChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `panYChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `pinchUpdated` | event | `(GesturePhase, Double, Point)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pinch on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pinch on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pinch on ScrollView - GTK's driver has no path for it yet |
| `pointerEntered` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on ScrollView - GTK's driver has no path for it yet |
| `pointerExited` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on ScrollView - GTK's driver has no path for it yet |
| `pointerMoved` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on ScrollView - GTK's driver has no path for it yet |
| `pointerPressed` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on ScrollView - GTK's driver has no path for it yet |
| `pointerReleased` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on ScrollView - GTK's driver has no path for it yet |
| `pointerStyle` | property | `PointerStyle` | native |  |  |  |  |  |  |  |
| `swipeDirection` | property | `SwipeDirection` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `swipeThreshold` | property | `Double` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `onSwiped` (`swiped`) | event | `SwipeDirection` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on ScrollView - GTK's driver has no path for it yet |
| `tag` | property | `PropValue` | stateUI |  |  |  |  |  |  |  |
| `tapCount` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on ScrollView - GTK's driver has no path for it yet |
| `onTapGesture` (`tapGesture`) | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on ScrollView: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on ScrollView: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on ScrollView - GTK's driver has no path for it yet |
| `verticalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `verticalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |

## From [Layout](tiers/Layout.md)

What every layout has: the screen's unsafe strips it keeps clear of, and whether its children are clipped or let input through.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `ignoresSafeArea` | property | `SafeAreaEdges` | adaptive |  | · |  |  |  |  | not realized; UIKit: cannot read ignoresSafeArea of ScrollView - UIKit's view places its children where SwiftOmniUI's layout says; their frames prove it; GTK 4: not realized |
| `clipsContent` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; GTK 4: not realized |
| `letsInputThrough` | property | `Bool` | native | ◐ |  |  |  |  |  | cannot read letsInputThrough of ScrollView - AppKit's driver has no path for it yet; UIKit: not realized; GTK 4: not realized |
| `hitShape` | property | `ContainerShape` | native | ◐ |  |  |  |  |  | cannot read hitShape of ScrollView - AppKit's driver has no path for it yet; UIKit: not realized; GTK 4: not realized |
| `scrollTargetLayout` | property | `Bool` | adaptive |  |  |  |  |  |  |  |

## From [PaddingElement](tiers/PaddingElement.md)

The space kept inside an element, around what it holds.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `contentPadding` | property | `EdgeInsets` | native | ◐ | ✅ | ✅ | ✅ | ◐ |  | cannot read contentPadding of ScrollView - AppKit's driver has no path for it yet; GTK 4: cannot read contentPadding of ScrollView - GTK's driver has no path for it yet |

## From [BorderElement](tiers/BorderElement.md)

What an element draws of its own box: the shape its background, its outline and its cut follow, and the outline.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `shape` | property | `ContainerShape` | stateUI | ✅ | · | · | ✅ | · |  | UIKit: cannot read shape of ScrollView - UIKit holds a layout's outline as its layer's path, no shape; its drawing proves it; Android Views: cannot read shape of ScrollView - SwiftOmniUI draws a layout's box in a drawable of its own, which holds none of its shape; its drawing proves it; GTK 4: cannot read shape of ScrollView - SwiftOmniUI draws a layout's box on GTK's snapshot, which holds none of its shape; its drawing proves it |
| `stroke` | property | `Brush` | stateUI | ☑️ | ✅ | · | ✅ | · |  | AppKit outlines a scroller in a colour on a rectangle or a rounded one; an oval, or a gradient, draws none.; Android Views: cannot read stroke of ScrollView - SwiftOmniUI draws a layout's box in a drawable of its own, which holds none of its stroke; its drawing proves it; GTK 4: cannot read stroke of ScrollView - SwiftOmniUI draws a layout's box on GTK's snapshot, which holds none of its stroke; its drawing proves it |
| `strokeWidth` | property | `Double` | stateUI | ✅ | ✅ | · | ✅ | · |  | Android Views: cannot read strokeWidth of ScrollView - SwiftOmniUI draws a layout's box in a drawable of its own, which holds none of its strokeWidth; its drawing proves it; GTK 4: cannot read strokeWidth of ScrollView - SwiftOmniUI draws a layout's box on GTK's snapshot, which holds none of its strokeWidth; its drawing proves it |

## From [ScrollContentElement](tiers/ScrollContentElement.md)

What shows behind a scrollable view's content - a list's or an editor's own canvas, where the platform draws one.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `scrollContentBackground` | property | `Visibility` | native |  |  |  |  |  |  |  |
