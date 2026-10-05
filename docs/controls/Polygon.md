<!-- Rendered by ControlDictionaryTests from the contracts and the verdicts each host's runs of its tests wrote under exports/marks: STATEUI_UPDATE_DOCS=1 swift test --filter ControlDictionaryTests writes it again. -->

# Polygon

A closed outline through a list of points.

Layer: `stateUI`. StateUI composes it from smaller primitives before a host receives the tree.

Inherits: [PropertyContainer](tiers/PropertyContainer.md) · [VisualElement](tiers/VisualElement.md) · [View](tiers/View.md) · [Shape](tiers/Shape.md)

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

| Host | Created | Members (103) | Realization | Notes |
| --- | :---: | --- | --- | --- |
| AppKit | ✅ | 27 ✅ · 1 ☑️ · 3 – | `NSView` drawing `NSBezierPath` |  |
| UIKit | ✅ | 28 ✅ · 3 – | `UIView` drawing `UIBezierPath` |  |
| Android Views | ✅ | 51 ✅ · 1 ☑️ · 3 – | `View` drawing `Path` |  |
| WinUI 3 | ✅ | 60 ✅ · 3 – | `Microsoft.UI.Xaml.Shapes` |  |
| GTK 4 | ✅ | 20 ✅ | `GskPath` in a snapshot |  |
| Web |  |  | inline SVG | no host yet |

Declared in `lib/StateUI/Sources/Contracts/Elements/Shapes/PolygonContract.swift`.

## Polygon's own members

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `fillRule` | property | `FillRule` | stateUI | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
| `points` | property | `[Point]` | stateUI | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |

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
| `accessibilityHeadingLevel` | property | `HeadingLevel` | native | · | · | · | ✅ | · |  | cannot read a heading's level - AppKit marks a heading, not its level; UIKit: cannot read a heading's level - UIKit marks a heading, not its level; Android Views: cannot read a heading's level - Android marks a heading, not its level; GTK 4: cannot read accessibilityHeadingLevel of Polygon - GTK's driver has no path for it yet |
| `accessibilityHint` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityHint of Polygon - GTK's driver has no path for it yet |
| `accessibilityLabel` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityLabel of Polygon - GTK's driver has no path for it yet |
| `accessibilityTraits` | property | `AccessibilityTraits` | native |  |  |  |  |  |  |  |
| `automationExcludedWithChildren` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read automationExcludedWithChildren of Polygon - GTK's driver has no path for it yet |
| `background` | property | `Background` | native | ☑️ |  | ✅ |  |  |  | AppKit paints a colour on this view; a brush is drawn only by a layout.; UIKit: not realized; WinUI 3: not realized; GTK 4: not realized |
| `blur` | property | `Double` | native |  |  |  |  |  |  |  |
| `contentTransition` | property | `String` | native |  |  |  |  |  |  |  |
| `focus` | act | `() -> Bool` |  | – | – | – | – | ⏸ |  | Polygon takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; GTK 4: waits on Polygon.isFocusedChanged, not realized yet |
| `frame` | property | `Rect` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `height` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `hint` | property | `String` | native |  |  |  |  |  |  |  |
| `hintKey` | property | `LocalizedStringKey` | native |  |  |  |  |  |  |  |
| `ignoresInput` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isAccessibilityHidden` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read isAccessibilityHidden of Polygon - GTK's driver has no path for it yet |
| `isEnabled` | property | `Bool` | native |  |  |  |  | ✅ |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized |
| `isFocusedChanged` | event | `Bool` | native | – | – | – | – |  |  | Polygon takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; GTK 4: not realized |
| `isVisible` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `layoutDirection` | property | `LayoutDirection` | native |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `matchedGeometry` | property | `String` | native |  |  |  |  |  |  |  |
| `matchedGeometrySource` | property | `Bool` | native |  |  |  |  |  |  |  |
| `maximumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `maximumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `opacity` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `pivotX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotX of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotX of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotX of Polygon - GTK's driver has no path for it yet |
| `pivotY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotY of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotY of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotY of Polygon - GTK's driver has no path for it yet |
| `rotation` | property | `Angle` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read rotation of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotation of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read rotation of Polygon - GTK's driver has no path for it yet |
| `rotationX` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationX of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationX of Polygon: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationX of Polygon - GTK's driver has no path for it yet |
| `rotationY` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationY of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationY of Polygon: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationY of Polygon - GTK's driver has no path for it yet |
| `scale` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scale of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scale of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scale of Polygon - GTK's driver has no path for it yet |
| `scaleX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleX of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleX of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleX of Polygon - GTK's driver has no path for it yet |
| `scaleY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleY of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleY of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleY of Polygon - GTK's driver has no path for it yet |
| `shadow` | property | `DropShadow` | native |  |  |  |  |  |  |  |
| `style` | property | `Name` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `symbolEffect` | property | `String` | native |  |  |  |  |  |  |  |
| `symbolEffectActive` | property | `Bool` | native |  |  |  |  |  |  |  |
| `symbolEffectOptions` | property | `Int` | native |  |  |  |  |  |  |  |
| `symbolEffectValue` | property | `String` | native |  |  |  |  |  |  |  |
| `transition` | property | `AnyTransition` | native |  |  |  |  |  |  |  |
| `translationX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationX of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationX of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationX of Polygon - GTK's driver has no path for it yet |
| `translationY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationY of Polygon: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationY of Polygon: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationY of Polygon - GTK's driver has no path for it yet |
| `unfocus` | act | `() -> Void` |  | – | – | – | – | ⏸ |  | Polygon takes no keyboard focus here: it refuses it, and nothing is heard; UIKit: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; Android Views: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; WinUI 3: Polygon takes no keyboard focus here: it refuses it, and nothing is heard; GTK 4: waits on Polygon.isFocusedChanged, not realized yet |
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
| `panTouchCount` | property | `Int` | structure | 🔌 | 🔌 | ☑️ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; Android Views: The host layer hears a one-finger pan only; any other `panTouchCount` turns the pan off.; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `onPanUpdated` (`panUpdated`) | event | `(GesturePhase, Double, Double, Point?, Point?)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `panXChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `panYChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `pinchUpdated` | event | `(GesturePhase, Double, Point)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pinch on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pinch on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pinch on Polygon - GTK's driver has no path for it yet |
| `pointerEntered` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on Polygon - GTK's driver has no path for it yet |
| `pointerExited` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on Polygon - GTK's driver has no path for it yet |
| `pointerMoved` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on Polygon - GTK's driver has no path for it yet |
| `pointerPressed` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on Polygon - GTK's driver has no path for it yet |
| `pointerReleased` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on Polygon - GTK's driver has no path for it yet |
| `pointerStyle` | property | `PointerStyle` | native |  |  |  |  |  |  |  |
| `swipeDirection` | property | `SwipeDirection` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `swipeThreshold` | property | `Double` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `onSwiped` (`swiped`) | event | `SwipeDirection` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on Polygon - GTK's driver has no path for it yet |
| `tag` | property | `PropValue` | stateUI |  |  |  |  |  |  |  |
| `tapCount` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on Polygon - GTK's driver has no path for it yet |
| `onTapGesture` (`tapGesture`) | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on Polygon: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on Polygon: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on Polygon - GTK's driver has no path for it yet |
| `verticalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `verticalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |

## From [Shape](tiers/Shape.md)

What every drawn shape has: what fills it, the line around it, how it fits its room, and a transform of its own drawing.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `aspect` | property | `ContentMode` | native | ◐ | ◐ | ◐ | ✅ | · |  | cannot read aspect of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its aspect; its drawing proves it; UIKit: cannot read aspect of Polygon - StateUI places and moves a shape's figure into its layer's path, which holds no aspect; its drawing proves it; Android Views: cannot read aspect of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its aspect; its drawing proves it; GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
| `fill` | property | `Brush` | stateUI | ◐ | ✅ | ◐ | ✅ | · |  | cannot read fill of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its fill; its drawing proves it; Android Views: cannot read fill of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its fill; its drawing proves it; GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
| `renderTransform` | property | `ViewTransform` | native | ◐ | ◐ | ◐ | ✅ | · |  | cannot read renderTransform of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its renderTransform; its drawing proves it; UIKit: cannot read renderTransform of Polygon - StateUI places and moves a shape's figure into its layer's path, which holds no renderTransform; its drawing proves it; Android Views: cannot read renderTransform of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its renderTransform; its drawing proves it; GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
| `stroke` | property | `Brush` | stateUI | ◐ | ✅ | ◐ | ✅ | · |  | cannot read stroke of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its stroke; its drawing proves it; Android Views: cannot read stroke of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its stroke; its drawing proves it; GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
| `strokeBorder` | property | `Brush` | stateUI |  |  |  |  |  |  |  |
| `strokeDashOffset` | property | `Double` | stateUI | · | · | · | ✅ | · |  | cannot read strokeDashOffset of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeDashOffset; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeDashOffset of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeDashOffset; its drawing proves it; GTK 4: cannot read strokeDashOffset of Polygon - StateUI draws a shape on GTK's snapshot, which holds none of its strokeDashOffset; its drawing proves it |
| `strokeDashPattern` | property | `[Double]` | stateUI | · | · | · | ✅ | · |  | cannot read strokeDashPattern of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeDashPattern; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeDashPattern of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeDashPattern; its drawing proves it; GTK 4: cannot read strokeDashPattern of Polygon - StateUI draws a shape on GTK's snapshot, which holds none of its strokeDashPattern; its drawing proves it |
| `strokeLineCap` | property | `LineCap` | stateUI | · | · | · | ✅ | · |  | cannot read strokeLineCap of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeLineCap; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeLineCap of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeLineCap; its drawing proves it; GTK 4: cannot read strokeLineCap of Polygon - StateUI draws a shape on GTK's snapshot, which holds none of its strokeLineCap; its drawing proves it |
| `strokeLineJoin` | property | `LineJoin` | stateUI | · | · | · | ✅ | · |  | cannot read strokeLineJoin of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeLineJoin; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeLineJoin of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeLineJoin; its drawing proves it; GTK 4: cannot read strokeLineJoin of Polygon - StateUI draws a shape on GTK's snapshot, which holds none of its strokeLineJoin; its drawing proves it |
| `strokeMiterLimit` | property | `Double` | stateUI | · | · | · | ✅ | · |  | cannot read strokeMiterLimit of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeMiterLimit; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeMiterLimit of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeMiterLimit; its drawing proves it; GTK 4: cannot read strokeMiterLimit of Polygon - StateUI draws a shape on GTK's snapshot, which holds none of its strokeMiterLimit; its drawing proves it |
| `strokeWidth` | property | `Double` | stateUI | ◐ | ◐ | ◐ | ✅ | · |  | cannot read strokeWidth of Polygon - StateUI draws a shape in its view's draw(_:), which holds none of its strokeWidth; its drawing proves it; UIKit: cannot read the line of a shape drawing no outline - UIKit draws no outline for a shape given no stroke, and holds none of its line; Android Views: cannot read strokeWidth of Polygon - StateUI draws a shape in its view's onDraw, which holds none of its strokeWidth; its drawing proves it; GTK 4: cannot read the colour of Polygon - GTK's driver has no path for it yet |
