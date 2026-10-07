<!-- Rendered by ControlDictionaryTests from the contracts and the verdicts each host's runs of its tests wrote under exports/marks: SWIFTOMNIUI_UPDATE_DOCS=1 swift test --filter ControlDictionaryTests writes it again. -->

# Map

A map of the world, with pins on it.

Layer: `provider`. An optional provider supplies it: a package, or the application that registers it with its hosts.

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

| Host | Created | Members (98) | Realization | Notes |
| --- | :---: | --- | --- | --- |
| AppKit | ✅ | 32 ✅ · 1 ☑️ · 3 – | `MKMapView` / `MKAnnotation` |  |
| UIKit | ✅ | 31 ✅ · 3 – | `MKMapView` / `MKAnnotation` |  |
| Android Views |  |  | Google Play services `MapView` / `Marker` (?) | not realized |
| WinUI 3 |  |  | `MapControl` (?) | not realized |
| GTK 4 |  |  | libshumate `ShumateMap` / `ShumateMarker` | not realized |
| Web |  |  | no honest native counterpart | no host yet |

Declared in `lib/SwiftOmniUI/Sources/Contracts/Elements/Controls/MapContract.swift`.

## Map's own members

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `isScrollEnabled` | property | `Bool` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isTrafficEnabled` | property | `Bool` | provider | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isZoomEnabled` | property | `Bool` | provider | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `onMapClicked` (`mapClicked`) | event | `Location` | provider | 🔌 | 🔌 |  |  |  |  | only through the host's own: tap on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `mapType` | property | `MapType` | provider | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `moveToRegion` | act | `(Double, Double, Double) -> Void` |  | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `region` | property | `MapRegion` | provider | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `showsUserLocation` | property | `Bool` | provider | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |

## From [PropertyContainer](tiers/PropertyContainer.md)

What anything carrying values in the tree has - a control, a `Style`, a text run: the name automation finds it by.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `accessibilityIdentifier` | property | `String` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |

## From [VisualElement](tiers/VisualElement.md)

What every drawn element has: its size and its bounds, how it is shown and turned, whether it answers input and holds the keyboard focus, the visual states it enters, and what a screen reader says about it.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `blendMode` | property | `BlendMode` | native |  |  |  |  |  |  |  |
| `accessibilityChildBehavior` | property | `AccessibilityChildBehavior` | native |  |  |  |  |  |  |  |
| `accessibilityHeadingLevel` | property | `HeadingLevel` | native | · | · |  |  |  |  | cannot read a heading's level - AppKit marks a heading, not its level; UIKit: cannot read a heading's level - UIKit marks a heading, not its level; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `accessibilityHint` | property | `String` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `accessibilityLabel` | property | `String` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `accessibilityTraits` | property | `AccessibilityTraits` | native |  |  |  |  |  |  |  |
| `automationExcludedWithChildren` | property | `Bool` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `background` | property | `Background` | native | ☑️ |  |  |  |  |  | AppKit paints a colour on this view; a brush is drawn only by a layout.; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `blur` | property | `Double` | native |  |  |  |  |  |  |  |
| `contentTransition` | property | `String` | native |  |  |  |  |  |  |  |
| `focus` | act | `() -> Bool` |  | – | – |  |  |  |  | Map takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Map takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `frame` | property | `Rect` | structure | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `height` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `hint` | property | `String` | native |  |  |  |  |  |  |  |
| `hintKey` | property | `LocalizedStringKey` | native |  |  |  |  |  |  |  |
| `ignoresInput` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isAccessibilityHidden` | property | `Bool` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isEnabled` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isFocusedChanged` | event | `Bool` | native | – | – |  |  |  |  | Map takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Map takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isVisible` | property | `Bool` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `layoutDirection` | property | `LayoutDirection` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `matchedGeometry` | property | `String` | native |  |  |  |  |  |  |  |
| `matchedGeometrySource` | property | `Bool` | native |  |  |  |  |  |  |  |
| `maximumHeight` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `maximumWidth` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `minimumHeight` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `minimumWidth` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `opacity` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pivotX` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read pivotX of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotX of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pivotY` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read pivotY of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotY of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `rotation` | property | `Angle` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read rotation of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotation of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `rotationX` | property | `Angle` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read rotationX of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationX of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `rotationY` | property | `Angle` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read rotationY of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationY of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `scale` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read scale of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scale of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `scaleX` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read scaleX of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleX of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `scaleY` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read scaleY of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleY of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `shadow` | property | `DropShadow` | native |  |  |  |  |  |  |  |
| `style` | property | `Name` | structure | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `symbolEffect` | property | `String` | native |  |  |  |  |  |  |  |
| `symbolEffectActive` | property | `Bool` | native |  |  |  |  |  |  |  |
| `symbolEffectOptions` | property | `Int` | native |  |  |  |  |  |  |  |
| `symbolEffectValue` | property | `String` | native |  |  |  |  |  |  |  |
| `transition` | property | `AnyTransition` | native |  |  |  |  |  |  |  |
| `translationX` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read translationX of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationX of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `translationY` | property | `Double` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: read translationY of Map: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationY of Map: the host's own transform, checked against the layer it composed itself; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `unfocus` | act | `() -> Void` |  | – | – |  |  |  |  | Map takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Map takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `width` | property | `Double` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `zIndex` | property | `Double` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |

## From [View](tiers/View.md)

What every view a layout positions has: where it sits in its layout, the space kept around it, and the gestures, drags and frame reports it answers.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `allowDrop` | property | `Bool` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `area` | property | `Area` | structure | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
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
| `frameChanged` | event | `[Double]` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `gridColumn` | property | `Int` | stateUI | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `gridColumnSpan` | property | `Int` | stateUI | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `gridRow` | property | `Int` | stateUI | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `gridRowSpan` | property | `Int` | stateUI | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `horizontalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `horizontalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |
| `layoutPriority` | property | `Double` | stateUI |  |  |  |  |  |  |  |
| `namedFramesChanged` | event | `[NamedSpaceFrame]` | native |  |  |  |  |  |  |  |
| `padding` | property | `EdgeInsets` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `panTouchCount` | property | `Int` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `onPanUpdated` (`panUpdated`) | event | `(GesturePhase, Double, Double, Point?, Point?)` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `panXChannel` | property | `Int` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `panYChannel` | property | `Int` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pinchUpdated` | event | `(GesturePhase, Double, Point)` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: pinch on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pinch on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerEntered` | event |  | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: hover on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerExited` | event |  | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: hover on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerMoved` | event | `Point?` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: hover on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerPressed` | event | `Point?` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: hover on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerReleased` | event | `Point?` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: hover on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `pointerStyle` | property | `PointerStyle` | native |  |  |  |  |  |  |  |
| `swipeDirection` | property | `SwipeDirection` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `swipeThreshold` | property | `Double` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `onSwiped` (`swiped`) | event | `SwipeDirection` | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: pan on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `tag` | property | `PropValue` | stateUI |  |  |  |  |  |  |  |
| `tapCount` | property | `Int` | structure | 🔌 | 🔌 |  |  |  |  | only through the host's own: tap on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `onTapGesture` (`tapGesture`) | event |  | native | 🔌 | 🔌 |  |  |  |  | only through the host's own: tap on Map: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on Map: the view's listening handed the recognizer's states, no touch sent; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `verticalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ |  |  |  |  | Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `verticalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |
