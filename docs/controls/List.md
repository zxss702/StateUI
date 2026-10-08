<!-- Rendered by ControlDictionaryTests from the contracts and the verdicts each host's runs of its tests wrote under exports/marks: SWIFTOMNIUI_UPDATE_DOCS=1 swift test --filter ControlDictionaryTests writes it again. -->

# List

The platform's own collection of items: SwiftOmniUI says which items there are, in order, and builds the one the platform asks for; the platform scrolls them, holds each in a cell it reuses, lets the user choose and open one, and tells assistive technology about them.

Layer: `native`. Every base host presents it with its native toolkit.

Inherits: [PropertyContainer](tiers/PropertyContainer.md) · [VisualElement](tiers/VisualElement.md) · [View](tiers/View.md) · [ScrollContentElement](tiers/ScrollContentElement.md)

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

| Host | Created | Members (104) | Realization | Notes |
| --- | :---: | --- | --- | --- |
| AppKit | ✅ | 33 ✅ · 1 ☑️ | `NSCollectionView` / `NSTableView` |  |
| UIKit | ✅ | 29 ✅ · 3 – | `UICollectionView` |  |
| Android Views | ✅ | 60 ✅ · 1 ☑️ | AndroidX `RecyclerView` |  |
| WinUI 3 | ✅ | 59 ✅ | `List` |  |
| GTK 4 | ✅ | 32 ✅ | `GtkListView` / `GtkGridView` |  |
| Web |  |  | semantic list or grid | no host yet |

Declared in `lib/SwiftOmniUI/Sources/Contracts/Elements/Collections/ListContract.swift`.

## List's own members

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `items` | property | `ItemsEntries` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `itemsLayout` | property | `ItemsLayout` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `listStyle` | property | `ListStyleKind` | native |  |  |  |  |  |  |  |
| `selectionMode` | property | `SelectionMode` | native | 🔌 | 🔌 | 🔌 | ✅ | ✅ |  | only through the host's own: choose on List: the collection's delegate told, no click; UIKit: only through the host's own: choose on List: the collection's delegate told, no touch; Android Views: only through the host's own: read selectionMode of List: the mode the relay keeps, which its cells tell TalkBack |
| `selectedItems` | property | `[String]` | native | 🔌 | 🔌 | ✅ | ✅ | ✅ |  | only through the host's own: choose on List: the collection's delegate told, no click; UIKit: only through the host's own: choose on List: the collection's delegate told, no touch |
| `selectionChanged` | event | `[String]` | native | 🔌 | 🔌 | ✅ | ✅ | ✅ |  | only through the host's own: choose on List: the collection's delegate told, no click; UIKit: only through the host's own: choose on List: the collection's delegate told, no touch |
| `itemActivated` | event | `String` | adaptive | 🔌 | 🔌 | ✅ | ✅ | ✅ |  | only through the host's own: activate on an item of List: the collection's delegate told, no click; UIKit: only through the host's own: activate on an item of List: the collection's delegate told, no touch |
| `endReachedWithin` | property | `Int` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `endReached` | event |  | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `realizedChanged` | event | `[String]` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `scrollTo` | act | `(String, ScrollAnchor) -> Void` |  | ✅ | ✅ | ✅ | ❌ | ✅ |  | WinUI 3: threw no element has the id "80 of List" |

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
| `accessibilityHeadingLevel` | property | `HeadingLevel` | native | · | · | · | ✅ | · |  | cannot read a heading's level - AppKit marks a heading, not its level; UIKit: cannot read a heading's level - UIKit marks a heading, not its level; Android Views: cannot read a heading's level - Android marks a heading, not its level; GTK 4: cannot read accessibilityHeadingLevel of List - GTK's driver has no path for it yet |
| `accessibilityHint` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityHint of List - GTK's driver has no path for it yet |
| `accessibilityLabel` | property | `String` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read accessibilityLabel of List - GTK's driver has no path for it yet |
| `accessibilityTraits` | property | `AccessibilityTraits` | native |  |  |  |  |  |  |  |
| `automationExcludedWithChildren` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read automationExcludedWithChildren of List - GTK's driver has no path for it yet |
| `background` | property | `Background` | native | ☑️ |  | ✅ |  |  |  | AppKit paints a colour on this view; a brush is drawn only by a layout.; UIKit: not realized; WinUI 3: not realized; GTK 4: not realized |
| `blur` | property | `Double` | native |  |  |  |  |  |  |  |
| `contentTransition` | property | `String` | native |  |  |  |  |  |  |  |
| `compositingGroup` | property | `Bool` | native |  |  |  |  |  |  |  |
| `drawingGroup` | property | `Bool` | native |  |  |  |  |  |  |  |
| `focus` | act | `() -> Bool` |  | ✅ | – | ✅ | ✅ | ✅ |  | UIKit: List takes no keyboard focus here: it refuses it, and nothing is heard |
| `frame` | property | `Rect` | structure | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `height` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `hint` | property | `String` | native |  |  |  |  |  |  |  |
| `hintKey` | property | `LocalizedStringKey` | native |  |  |  |  |  |  |  |
| `ignoresInput` | property | `Bool` | native | ✅ |  |  |  |  |  | UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `isAccessibilityHidden` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | · |  | GTK 4: cannot read isAccessibilityHidden of List - GTK's driver has no path for it yet |
| `isEnabled` | property | `Bool` | native |  |  |  |  | ✅ |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized |
| `isFocusedChanged` | event | `Bool` | native | ✅ | – | ✅ | ✅ | ✅ |  | UIKit: List takes no keyboard focus here: it refuses it, and nothing is heard |
| `isVisible` | property | `Bool` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `layoutDirection` | property | `LayoutDirection` | native |  |  |  |  | · |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: cannot read layoutDirection of List - GTK's driver has no path for it yet |
| `matchedGeometry` | property | `String` | native |  |  |  |  |  |  |  |
| `matchedGeometrySource` | property | `Bool` | native |  |  |  |  |  |  |  |
| `maximumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `maximumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumHeight` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `minimumWidth` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `opacity` | property | `Double` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `pivotX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotX of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotX of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotX of List - GTK's driver has no path for it yet |
| `pivotY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read pivotY of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read pivotY of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read pivotY of List - GTK's driver has no path for it yet |
| `rotation` | property | `Angle` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read rotation of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotation of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read rotation of List - GTK's driver has no path for it yet |
| `rotationX` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationX of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationX of List: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationX of List - GTK's driver has no path for it yet |
| `rotationY` | property | `Angle` | native | 🔌 | 🔌 | ✅ |  | · |  | only through the host's own: read rotationY of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read rotationY of List: the host's own transform, checked against the layer it composed itself; WinUI 3: not realized; GTK 4: cannot read rotationY of List - GTK's driver has no path for it yet |
| `scale` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scale of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scale of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scale of List - GTK's driver has no path for it yet |
| `scaleX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleX of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleX of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleX of List - GTK's driver has no path for it yet |
| `scaleY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read scaleY of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read scaleY of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read scaleY of List - GTK's driver has no path for it yet |
| `shadow` | property | `DropShadow` | native |  |  |  |  |  |  |  |
| `style` | property | `Name` | structure |  |  |  |  |  |  | not realized; UIKit: not realized; Android Views: not realized; WinUI 3: not realized; GTK 4: not realized |
| `symbolEffect` | property | `String` | native |  |  |  |  |  |  |  |
| `symbolEffectActive` | property | `Bool` | native |  |  |  |  |  |  |  |
| `symbolEffectOptions` | property | `Int` | native |  |  |  |  |  |  |  |
| `symbolEffectValue` | property | `String` | native |  |  |  |  |  |  |  |
| `transition` | property | `AnyTransition` | native |  |  |  |  |  |  |  |
| `translationX` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationX of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationX of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationX of List - GTK's driver has no path for it yet |
| `translationY` | property | `Double` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: read translationY of List: the host's own transform, checked against the layer it composed itself; UIKit: only through the host's own: read translationY of List: the host's own transform, checked against the layer it composed itself; GTK 4: cannot read translationY of List - GTK's driver has no path for it yet |
| `unfocus` | act | `() -> Void` |  | ✅ | – | ✅ | ✅ | ✅ |  | UIKit: List takes no keyboard focus here: it refuses it, and nothing is heard |
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
| `panTouchCount` | property | `Int` | structure | 🔌 | 🔌 | ☑️ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; Android Views: The host layer hears a one-finger pan only; any other `panTouchCount` turns the pan off.; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `onPanUpdated` (`panUpdated`) | event | `(GesturePhase, Double, Double, Point?, Point?)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `panXChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `panYChannel` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `pinchUpdated` | event | `(GesturePhase, Double, Point)` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pinch on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pinch on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pinch on List - GTK's driver has no path for it yet |
| `pointerEntered` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on List - GTK's driver has no path for it yet |
| `pointerExited` | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on List - GTK's driver has no path for it yet |
| `pointerMoved` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on List - GTK's driver has no path for it yet |
| `pointerPressed` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on List - GTK's driver has no path for it yet |
| `pointerReleased` | event | `Point?` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: hover on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: hover on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot hover on List - GTK's driver has no path for it yet |
| `pointerStyle` | property | `PointerStyle` | native |  |  |  |  |  |  |  |
| `swipeDirection` | property | `SwipeDirection` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `swipeThreshold` | property | `Double` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `onSwiped` (`swiped`) | event | `SwipeDirection` | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: pan on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: pan on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot pan on List - GTK's driver has no path for it yet |
| `tag` | property | `PropValue` | stateUI |  |  |  |  |  |  |  |
| `tapCount` | property | `Int` | structure | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on List - GTK's driver has no path for it yet |
| `onTapGesture` (`tapGesture`) | event |  | native | 🔌 | 🔌 | ✅ | ✅ | · |  | only through the host's own: tap on List: handed to the host's recognizer or handler, no NSEvent sent; UIKit: only through the host's own: tap on List: the view's listening handed the recognizer's states, no touch sent; GTK 4: cannot tap on List - GTK's driver has no path for it yet |
| `verticalAlignment` | property | `AxisAlignment` | native | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| `verticalGuide` | property | `[Double]` | stateUI |  |  |  |  |  |  |  |

## From [ScrollContentElement](tiers/ScrollContentElement.md)

What shows behind a scrollable view's content - a list's or an editor's own canvas, where the platform draws one.

| Member | Kind | Value | Layer | AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web | Notes |
| --- | --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | --- |
| `scrollContentBackground` | property | `Visibility` | native |  |  |  |  |  |  |  |
