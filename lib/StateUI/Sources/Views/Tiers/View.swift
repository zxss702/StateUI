// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The properties every positioned view has: the value half of a control's
/// contract, shared by the control and its `Style`, including where it sits in
/// a Grid or a ZStack.
public protocol ViewProperties: VisualElementProperties {}

/// A piece of interface: a control, a layout, or a view composed of other
/// views.
///
///     struct Header: View {
///         private let title: String
///
///         init(_ title: String) {
///             self.title = title
///         }
///
///         var body: some View {
///             Text(title).fontSize(28).fontAttributes(.bold)
///         }
///     }
///
/// `body` is read the first time the view is built, and again when what it was
/// built with or a state it read changes; otherwise the view is carried
/// whole. A view that draws itself - a `Text`, a `VStack` - has no body and
/// declares none; its `Body` is `Never`.
///
/// Configure a composed view the way every control is configured: what it is
/// goes in the initializer, with no default, and what a caller may leave out
/// is a modifier written after it, which lands on the view's root:
///
///     Header("Settings")
///         .padding(0, 8)
///         .gridRow(1)
public protocol View: Element, Page {
    /// What this view is made of, read each time the view is built. A view
    /// that draws itself has no body - `Never` says so.
    associatedtype Body: View = Never

    /// The view this one is made of.
    @ViewBuilder var body: Body { get }
}

extension View {
    /// A composed view as a node: a placeholder the differ expands once it
    /// knows whether this view stood here last render - so its `@State` is
    /// kept. A view that draws itself provides its own `node`, so this default
    /// runs only for composed views.
    /// Design: docs/design/views/composition.md#a-composed-view-is-a-placeholder
    public var node: Node {
        Node.composed(self, type: String(reflecting: Self.self)) { body.node }
    }
}

extension View where Body == Never {
    /// A view that draws itself has no body; it is never read.
    public var body: Never { fatalError("\(Self.self) draws itself - it has no body") }
}

/// The absence of a view: the `Body` of a view that draws itself, and the
/// `Body` of a scene that draws itself.
extension Never: View {
    /// Never is built - never read.
    public var node: Node { fatalError("Never is not a view") }
}

extension View {
    /// One modifier step on any view: the change lands on the view's root
    /// node, and the result is opaque the way `some View` is.
    func revised(_ change: (inout Node) -> Void) -> ModifiedContent {
        var node = node
        change(&node)
        return ModifiedContent(node: node)
    }

    /// Sets a property by its token - what the typed `setValue` is written
    /// over, and every modifier that writes a value it built itself.
    func setting(_ property: Prop, _ value: PropValue) -> ModifiedContent {
        revised { $0.props[property] = value }
    }

    /// Sets one of this view's properties to a value of the type its contract
    /// declares.
    func setting<Owner: Contract, Value: HostRepresentable>(
        _ property: ElementProperty<Owner, Value>,
        _ value: Value
    ) -> ModifiedContent {
        setting(property.token, value.propValue)
    }
}

extension View {
    /// Hears one of this view's events that carries nothing, written with its
    /// contract.
    func hearing<Owner: Contract>(
        _ event: ElementEvent<Owner, Void>,
        _ handler: @escaping EventHandler
    ) -> ModifiedContent {
        revised {
            $0.addHandler(event.token) {
                guard MemberValues.carried(EventBuffer.current, by: event.name) != nil else { return }
                try await handler()
            }
        }
    }

    /// Hears one of this view's events, its value handed over as the type its
    /// contract declares.
    func hearing<Owner: Contract, Value: HostRepresentable>(
        _ event: ElementEvent<Owner, Value>,
        _ handler: @escaping ValueEventHandler<Value>
    ) -> ModifiedContent {
        revised {
            $0.addHandler(event.token) {
                guard let value = MemberValues.carried(
                    EventBuffer.current, by: event.name, as: Value.self)
                else { return }
                try await handler(value)
            }
        }
    }

    /// Hears one of this view's events that carries two values.
    func hearing<Owner: Contract, First: HostRepresentable, Second: HostRepresentable>(
        _ event: ElementEvent<Owner, (First, Second)>,
        _ handler: @escaping ValueEventHandler<First, Second>
    ) -> ModifiedContent {
        revised {
            $0.addHandler(event.token) {
                guard let (first, second) = MemberValues.carried(
                    EventBuffer.current, by: event.name, as: First.self, Second.self)
                else { return }
                try await handler(first, second)
            }
        }
    }

    /// Hears one of this view's events that carries three values.
    func hearing<
        Owner: Contract, First: HostRepresentable, Second: HostRepresentable, Third: HostRepresentable
    >(
        _ event: ElementEvent<Owner, (First, Second, Third)>,
        _ handler: @escaping ValueEventHandler<First, Second, Third>
    ) -> ModifiedContent {
        revised {
            $0.addHandler(event.token) {
                guard let (first, second, third) = MemberValues.carried(
                    EventBuffer.current, by: event.name, as: First.self, Second.self, Third.self)
                else { return }
                try await handler(first, second, third)
            }
        }
    }
}

extension ViewProperties {
    /// The space kept outside the view, between it and its neighbours.
    /// `contentPadding` is the space inside.
    ///
    ///     Text("Total").padding(16)                        // all four sides
    ///     Text("Total").padding(EdgeInsets(16, 0, 0, 0))   // the left edge only
    public func padding(_ value: EdgeInsets) -> Modified {
        setValue(ViewContract.padding, value)
    }

    /// Left and right, then top and bottom.
    public func padding(_ horizontalSize: Double, _ verticalSize: Double) -> Modified {
        padding(EdgeInsets(horizontalSize, verticalSize))
    }

    /// Each side in turn: left, top, right, bottom.
    public func padding(_ left: Double, _ top: Double, _ right: Double, _ bottom: Double) -> Modified {
        padding(EdgeInsets(left, top, right, bottom))
    }

    /// The same space on all four sides.
    public func padding(_ all: Double) -> Modified {
        padding(EdgeInsets(all, all, all, all))
    }

    /// The same space on all four sides, as a number literal.
    public func padding(_ all: Int) -> Modified {
        padding(EdgeInsets(Double(all)))
    }

    /// `padding` from a state, `$x`: the host animates the property to each
    /// new value, and no view is rebuilt for it.
    public func padding(_ state: Binding<EdgeInsets>) -> Modified {
        journey(ViewContract.padding, by: state)
    }

    /// The same space on all four sides, from a state, `$x`.
    public func padding(_ state: Binding<Double>) -> Modified {
        padding(state.convert { EdgeInsets($0, $0, $0, $0) })
    }

    /// The same space on all four sides, from a state holding a whole number, `$x`.
    public func padding(_ state: Binding<Int>) -> Modified {
        padding(state.convert { EdgeInsets(Double($0)) })
    }

    /// How the view uses the width its parent offers - filling it, or sitting
    /// at one end of it.
    ///
    ///     Button("Save").horizontalAlignment(.center)
    public func horizontalAlignment(_ value: Alignment) -> Modified {
        setValue(ViewContract.horizontalAlignment, value)
    }

    /// The same, for the height.
    public func verticalAlignment(_ value: Alignment) -> Modified {
        setValue(ViewContract.verticalAlignment, value)
    }

    /// `horizontalAlignment` from a state, `$x`: the host sets each new value
    /// as it stands, and no view is rebuilt for it.
    public func horizontalAlignment(_ state: Binding<Alignment>) -> Modified {
        plain(ViewContract.horizontalAlignment, by: state)
    }

    /// `verticalAlignment` from a state, `$x`: the host sets each new value as
    /// it stands, and no view is rebuilt for it.
    public func verticalAlignment(_ state: Binding<Alignment>) -> Modified {
        plain(ViewContract.verticalAlignment, by: state)
    }
}

extension View {
    /// Hears one of this view's events that carries nothing, landing on the
    /// root of what it is made of.
    ///
    /// - Parameters:
    ///   - event: the member, written with its contract.
    ///   - handler: what runs.
    @_disfavoredOverload
    public func onEvent<Owner: Contract>(
        _ event: ElementEvent<Owner, Void>,
        _ handler: @escaping EventHandler
    ) -> ModifiedContent {
        hearing(event, handler)
    }

    /// Hears one of this view's events, its value handed over as the type its
    /// contract declares.
    ///
    /// - Parameters:
    ///   - event: the member, written with its contract.
    ///   - handler: given the value.
    @_disfavoredOverload
    public func onEvent<Owner: Contract, Value: HostRepresentable>(
        _ event: ElementEvent<Owner, Value>,
        _ handler: @escaping ValueEventHandler<Value>
    ) -> ModifiedContent {
        hearing(event, handler)
    }

    /// Hears one of this view's events that carries two values, handed over
    /// as the types its contract declares, in its order.
    ///
    /// - Parameters:
    ///   - event: the member, written with its contract.
    ///   - handler: given the values.
    @_disfavoredOverload
    public func onEvent<Owner: Contract, First: HostRepresentable, Second: HostRepresentable>(
        _ event: ElementEvent<Owner, (First, Second)>,
        _ handler: @escaping ValueEventHandler<First, Second>
    ) -> ModifiedContent {
        hearing(event, handler)
    }

    /// Hears one of this view's events that carries three values, handed over
    /// as the types its contract declares, in its order.
    ///
    /// - Parameters:
    ///   - event: the member, written with its contract.
    ///   - handler: given the values.
    @_disfavoredOverload
    public func onEvent<
        Owner: Contract, First: HostRepresentable, Second: HostRepresentable, Third: HostRepresentable
    >(
        _ event: ElementEvent<Owner, (First, Second, Third)>,
        _ handler: @escaping ValueEventHandler<First, Second, Third>
    ) -> ModifiedContent {
        hearing(event, handler)
    }

    /// The space kept outside the view, between it and its neighbours.
    /// `contentPadding` is the space inside.
    ///
    ///     Text("Total").padding(16)                        // all four sides
    ///     Text("Total").padding(EdgeInsets(16, 0, 0, 0))   // the left edge only
    @_disfavoredOverload
    public func padding(_ value: EdgeInsets) -> ModifiedContent {
        setting(ViewContract.padding, value)
    }

    /// Left and right, then top and bottom.
    @_disfavoredOverload
    public func padding(_ horizontalSize: Double, _ verticalSize: Double) -> ModifiedContent {
        padding(EdgeInsets(horizontalSize, verticalSize))
    }

    /// Each side in turn: left, top, right, bottom.
    @_disfavoredOverload
    public func padding(_ left: Double, _ top: Double, _ right: Double, _ bottom: Double) -> ModifiedContent {
        padding(EdgeInsets(left, top, right, bottom))
    }

    /// The same space on all four sides.
    @_disfavoredOverload
    public func padding(_ all: Double) -> ModifiedContent {
        padding(EdgeInsets(all, all, all, all))
    }

    /// The same space on all four sides, as a number literal.
    @_disfavoredOverload
    public func padding(_ all: Int) -> ModifiedContent {
        padding(EdgeInsets(Double(all)))
    }

    /// `padding` from a state, `$x`: the host animates the property to each
    /// new value, and no view is rebuilt for it.
    @_disfavoredOverload
    public func padding(_ state: Binding<EdgeInsets>) -> ModifiedContent {
        revised { node in
            node.driveJourney(ViewContract.padding, by: state)
        }
    }

    /// The same space on all four sides, from a state, `$x`.
    @_disfavoredOverload
    public func padding(_ state: Binding<Double>) -> ModifiedContent {
        padding(state.convert { EdgeInsets($0, $0, $0, $0) })
    }

    /// The same space on all four sides, from a state holding a whole number, `$x`.
    @_disfavoredOverload
    public func padding(_ state: Binding<Int>) -> ModifiedContent {
        padding(state.convert { EdgeInsets(Double($0)) })
    }

    /// How the view uses the width its parent offers - filling it, or sitting
    /// at one end of it.
    ///
    ///     Button("Save").horizontalAlignment(.center)
    @_disfavoredOverload
    public func horizontalAlignment(_ value: Alignment) -> ModifiedContent {
        setting(ViewContract.horizontalAlignment, value)
    }

    /// The same, for the height.
    @_disfavoredOverload
    public func verticalAlignment(_ value: Alignment) -> ModifiedContent {
        setting(ViewContract.verticalAlignment, value)
    }

    /// `horizontalAlignment` from a state, `$x`: the host sets each new value
    /// as it stands, and no view is rebuilt for it.
    @_disfavoredOverload
    public func horizontalAlignment(_ state: Binding<Alignment>) -> ModifiedContent {
        revised { $0.drivePlain(ViewContract.horizontalAlignment, by: state) }
    }

    /// `verticalAlignment` from a state, `$x`: the host sets each new value as
    /// it stands, and no view is rebuilt for it.
    @_disfavoredOverload
    public func verticalAlignment(_ state: Binding<Alignment>) -> ModifiedContent {
        revised { $0.drivePlain(ViewContract.verticalAlignment, by: state) }
    }
}

extension View {
    /// A menu on the view itself, opened with a right-click.
    ///
    ///     Text(item.name)
    ///         .contextMenu {
    ///             MenuItem("Rename").onClicked { rename(item) }
    ///             Divider()
    ///             MenuItem("Delete").isDestructive(true).onClicked { remove(item) }
    ///         }
    ///
    /// The same entries a menu bar takes - `MenuItem`, `Menu`
    /// and `Divider` - attached to a view instead of to a page.
    ///
    /// Context menus are a desktop interaction. A host with no native context
    /// menu interaction leaves this modifier inert, so do not put the only way
    /// to perform an essential action behind it.
    ///
    /// - Parameter items: the entries, in the order they are shown.
    public func contextMenu(@ViewBuilder _ items: () -> any View) -> ModifiedContent {
        revised {
            // After the view's own children; the host finds it by type.
            // Design: docs/design/views/modifiers.md#slot-children
            $0.children.append(Node(contract: ContextMenuContract.self, children: items().node.asChildren))
        }
    }
}

extension View {
    /// How this view's values animate when they change.
    ///
    ///     VStack { … }.animation(.spring(response: 260))
    ///     Text(count).animation(.none)
    ///
    /// A changed value animates to its new setting by default; `.none` snaps,
    /// which is what a value rewritten every frame wants. It applies to this
    /// view only, not to the views inside it; `application.animation` sets the
    /// whole application.
    ///
    /// - Parameter animation: how its values animate.
    /// - Returns: the view, with the animation on it.
    public func animation(_ animation: Animation) -> ModifiedContent {
        revised { node in
            var plan = node.animation ?? AnimationPlan(base: nil)
            plan.base = animation
            node.animation = plan
        }
    }

    /// How some of this view's values animate, leaving the rest as they were.
    ///
    ///     VStack { … }
    ///         .animation(.spring(response: 240))
    ///         .animation(.none, .size)
    ///
    /// The last rule that names a value answers for it. The usual use is a view
    /// whose shape changes: it takes its new size at once while still
    /// animating to its new place.
    ///
    /// - Parameters:
    ///   - animation: how those values animate.
    ///   - values: which of them. See `AnimationValues` for what each name covers.
    /// - Returns: the view, with the rule on it.
    public func animation(_ animation: Animation, _ values: AnimationValues) -> ModifiedContent {
        revised { node in
            var plan = node.animation ?? AnimationPlan(base: nil)
            plan.rules.append((values: values, animation: animation))
            node.animation = plan
        }
    }

    /// Who this view is among its siblings: its key across renders.
    ///
    /// A view that comes back with the same key keeps its control, and only the
    /// properties that changed are written to it. Give one to anything whose
    /// position can change, so inserting, removing or reordering moves the
    /// existing controls instead of rewriting each into its neighbour:
    ///
    ///     VStack {
    ///         ForEach(items, id: \.id) { item in
    ///             Text(item.title)            // key from the loop
    ///         }
    ///
    ///         if showingTotal {
    ///             Text("Total").id("total")   // key written by hand
    ///         }
    ///     }
    ///
    /// An `.id()` written on the view wins over the one `ForEach` gives. Any
    /// `Hashable` is a key - a string, a number, a UUID, the author's own enum
    /// or struct - compared as `String(describing:)`: a description that says
    /// less than the value gives two values one key, and a class is keyed by
    /// something it holds (`.id(file.path)`).
    ///
    /// - Parameter value: who this view is - distinct among its siblings and
    ///   the same across renders.
    @_disfavoredOverload
    public func id(_ value: some Hashable) -> ModifiedContent {
        revised { $0.id = String(describing: value) }
    }

    /// Provides an object to this view and everything under it, resolved by
    /// type: any view below declaring `@Environment var context: MyContext`
    /// reads the nearest `MyContext` provided above it. A nearer
    /// `.environment()` of the same type overrides for its own branch.
    ///
    ///     @State var context = MyContext()   // a class of @State properties, usually
    ///
    ///     ChildView()
    ///         .environment(context)
    ///
    /// Providing reads no property, so a change in the object rebuilds the
    /// readers below and not the provider; replacing the object rebuilds the
    /// branch.
    public func environment<Value: AnyObject>(_ object: Value) -> ModifiedContent {
        revised { $0.environments.append((key: ObjectIdentifier(Value.self), object: object)) }
    }

    /// The keyed style from the application's style sheet that this view wears.
    ///
    ///     Text("Welcome").style("Headline")
    ///
    /// A style without a key applies to every control of its type by itself.
    public func style(_ key: String) -> ModifiedContent {
        setting(VisualElementContract.style, Name(key))
    }
}

extension View {
    /// Whether the platform has given this view the focus, written into the
    /// binding. Read-only: the platform moves the focus.
    ///
    ///     @State private var focused = false
    ///     TextField($name).isFocused($focused)
    public func isFocused(_ binding: Binding<Bool>) -> ModifiedContent {
        hearing(VisualElementContract.isFocusedChanged) { focused in
            binding.wrappedValue = focused
        }
    }

    /// Reads where a value the host is animating has got to, at most so many
    /// times a second, into a state of your own.
    ///
    ///     @State private var fade = 1.0
    ///     @State private var shown = 1.0
    ///
    ///     VStack {
    ///         Text("\(Int(shown * 100))%")
    ///     }
    ///     .opacity($fade)
    ///     .samples($fade, into: $shown, .every(100))
    ///
    /// Reading `fade` answers where it is going, and `$fade.journey.value` in a
    /// body rebuilds that body on every frame; this copies some of those frames
    /// into an ordinary state instead. It stops when the value lands, the last
    /// sample being where the value ended. A value that is only shown wants a
    /// driven text (`Text($fade.journey.convert { … })`), which costs no render.
    ///
    /// - Parameters:
    ///   - source: the value the host is animating, `$x` of a `@State`.
    ///   - target: the state to read it into, `$y`.
    ///   - asks: how often, at most.
    public func samples<Value: Walked>(
        _ source: Binding<Value>,
        into target: Binding<Value>,
        _ asks: Asks
    ) -> ModifiedContent {
        revised {
            guard let from = source.described, let image = from.walkedImage(),
                  let into = target.described
            else {
                complain("`.samples` was given a binding that borrows no @State the host "
                    + "walks - a closure binding, a part of a state, or a state carried as "
                    + "the value itself - so there is no journey to read. Hand it the "
                    + "state itself.")
                return
            }

            $0.samples.append((image: image, into: ObjectIdentifier(into), asks: asks, take: {
                // Off the lanes, not the journey's own read, so the element being
                // built does not become a reader of the value.
                guard let now = from.journeyLanes?.value else { return }

                guard StateImage.bytes(of: now.carried)
                    != StateImage.bytes(of: into.value.carried) else { return }

                target.wrappedValue = now
            }))
        }
    }
}
