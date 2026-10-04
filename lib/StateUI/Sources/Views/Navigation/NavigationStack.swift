// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// The navigation stack: what is on the native stack is an array the author
// holds, and a back gesture the user completes shortens it.
// Design: docs/design/views/pages.md#the-stack-is-the-state

/// A page holding a native stack of pages, with a bar and a back affordance.
///
///     enum Route: Hashable {
///         case details(String)
///     }
///
///     struct MainWindow: WindowScene {
///         @State private var path: [Route] = []
///
///         var page: any Page {
///             NavigationStack($path) {
///                 HomePage(path: $path)
///             } destination: { route in
///                 switch route {
///                 case .details(let id): DetailsPage(id: id)
///                 }
///             }
///         }
///     }
///
///     struct HomePage: View {
///         @Binding var path: [Route]
///         @Environment private var page: PageSession
///
///         var content: any View {
///             Button("Open the first")
///                 .onClicked { path.append(.details("first")) }
///                 .onAppear { page.title = "Home" }
///         }
///     }
///
/// Push is `path.append(_:)`, pop is `path.removeLast()`, back to the root is
/// `path = []`, and a back gesture the user completes shortens the path. Hand
/// the root page the binding: a page that pushes has to be able to write it.
///
/// The first closure is the root, always there. The second is asked for a page
/// per element of `path`, in order; a `switch` over the route type makes the
/// compiler check that every route has a page.
///
/// The path can live anywhere a `Binding` can - `@State` on the window, as
/// above, or a model offered with `.environment(_:)` that names the moves:
///
///     final class Router {
///         @State var path: [Route] = []
///
///         func open(_ id: String) { path.append(.details(id)) }
///         func home() { path = [] }
///     }
///
///     NavigationStack(router.$path) { RoutedHomePage() } destination: { … }
///
/// A route may repeat: `[.level(1), .level(2), .level(2)]` holds two different
/// `.level(2)` pages. A route must be a value whose distinct values describe
/// differently (`String(describing:)`), so a class does not qualify.
///
/// `.onChange(of: path)` observes every committed arrival and departure. The
/// title on the bar belongs to the top page; `.title` and `.icon` on the
/// stack name the whole stack where another container presents it.
public struct NavigationStack: VisualElement, BarElement, PageElement, PageArrangement {
    /// The node this page describes.
    public var node: Node

    /// The node, as every element answers it.

    /// A stack over `path`, with `root` under it and `destination` above.
    ///
    /// - Parameter path: what is on the stack, ABOVE the root - the author's
    ///   own type, borrowed two-way. A completed back gesture truncates it.
    /// - Parameter root: the page under everything, built once and kept.
    /// - Parameter destination: the page for one route, asked in path order.
    public init<Route: Hashable>(
        _ path: Binding<[Route]>,
        root: () -> any Page,
        destination: (Route) -> any Page
    ) {
        var children: [Node] = [Self.identified(Node.page(root()), as: Self.rootIdentity)]

        for (depth, route) in path.wrappedValue.enumerated() {
            var pushed = Self.identified(
                Node.page(destination(route)), as: Self.identity(depth: depth, route: route))

            // `\.dismiss` inside a pushed page backs the stack out of it.
            pushed.environmentValues[keyPath: \.dismiss] = DismissAction { [path] in
                path.wrappedValue = Array(path.wrappedValue.prefix(depth))
            }

            children.append(pushed)
        }

        node = Node(contract: NavigationStackContract.self, children: children)

        // The platform's way back, once committed, reports how deep the stack
        // now is above the root; the path only ever shortens to match.
        // Design: docs/design/views/pages.md#a-pop-report-only-shortens
        node.addHandler(NavigationStackContract.popped.token) {
            guard let depth = EventBuffer.current.value()?.int else { return }

            let routes = path.wrappedValue
            guard depth >= 0, depth < routes.count else { return }

            path.wrappedValue = Array(routes.prefix(depth))
        }
    }

    /// A stack whose pushed pages come from the destinations registered on
    /// `root` - SwiftUI's
    /// `NavigationStack(path:) { … .navigationDestination(for:) { … } }`:
    ///
    ///     NavigationStack(path: $path) {
    ///         AgentView()
    ///             .navigationDestination(for: FilePage.self) {
    ///                 FileEdittingView(filePage: $0)
    ///             }
    ///     }
    ///
    /// A `\.dismiss` inside a pushed page backs the stack out of it, and a
    /// route registering no destination pushes an empty page - the stack's
    /// depth still says where it stands.
    public init<Route: Hashable>(
        path: Binding<[Route]>,
        root: () -> any Page
    ) {
        let rootNode = Self.identified(Node.page(root()), as: Self.rootIdentity)
        var children: [Node] = [rootNode]

        let destinations = Self.destinations(on: rootNode)
        for (depth, route) in path.wrappedValue.enumerated() {
            let made = destinations[ObjectIdentifier(Swift.type(of: route))]?(route)
                ?? EmptyView().node
            var pushed = Self.identified(
                Node.page(DestinationPage(node: made)), as: Self.identity(depth: depth, route: route))

            pushed.environmentValues[keyPath: \.dismiss] = DismissAction { [path] in
                path.wrappedValue = Array(path.wrappedValue.prefix(depth))
            }
            children.append(pushed)
        }

        if let pushed = Self.itemDestinationPage(from: rootNode) {
            children.append(pushed)
        }

        node = Node(contract: NavigationStackContract.self, children: children)

        // A back gesture past the path's depth drops the item-driven page:
        // the path holds the pushed routes, and the page above them all is
        // the one an item presents.
        let dismissItem = rootNode.itemDestination?.dismiss
            ?? rootNode.children.compactMap(\.itemDestination?.dismiss).first
        node.addHandler(NavigationStackContract.popped.token) {
            guard let depth = EventBuffer.current.value()?.int else { return }

            let routes = path.wrappedValue
            if depth >= 0, depth < routes.count {
                path.wrappedValue = Array(routes.prefix(depth))
            } else if depth == routes.count {
                dismissItem?()
            }
        }
    }

    /// A stack of one page - what SwiftUI's `NavigationStack { … }` says
    /// where no path is bound. A `.navigationDestination(item:)` on `root`
    /// still pushes and pops its page.
    public init(root: () -> any Page) {
        let rootNode = Self.identified(Node.page(root()), as: Self.rootIdentity)
        var children: [Node] = [rootNode]

        if let pushed = Self.itemDestinationPage(from: rootNode) {
            children.append(pushed)
        }

        node = Node(contract: NavigationStackContract.self, children: children)

        // With no path the only thing to pop is the item-driven page.
        let dismissItem = rootNode.itemDestination?.dismiss
            ?? rootNode.children.compactMap(\.itemDestination?.dismiss).first
        node.addHandler(NavigationStackContract.popped.token) {
            dismissItem?()
        }
    }

    /// The destinations `.navigationDestination` registered on the page - its
    /// own, or its content's where the modifier wrapped it inside.
    private static func destinations(on rootNode: Node) -> [ObjectIdentifier: (Any) -> Node] {
        var found = rootNode.destinations
        for child in rootNode.children {
            found.merge(child.destinations) { own, _ in own }
        }
        return found
    }

    /// The page an item-driven `.navigationDestination` on `rootNode`
    /// presents, or nil while its item is nil.
    private static func itemDestinationPage(from rootNode: Node) -> Node? {
        let itemDestination = rootNode.itemDestination
            ?? rootNode.children.compactMap(\.itemDestination).first
        guard let made = itemDestination?.make() else { return nil }

        var pushed = Self.identified(
            Node.page(DestinationPage(node: made)), as: "item")
        let dismissItem = itemDestination?.dismiss
        pushed.environmentValues[keyPath: \.dismiss] = DismissAction {
            dismissItem?()
        }
        return pushed
    }

    /// The root page's key, which no route's can equal: a route's carries its depth.
    private static let rootIdentity = "root"

    /// Who a pushed page is: its depth and its route together.
    /// Design: docs/design/views/pages.md#an-arrangement-keys-its-pages
    private static func identity(depth: Int, route: some Hashable) -> String {
        "\(depth)/\(String(describing: route))"
    }

    /// A page node wearing the key the stack gives it.
    private static func identified(_ node: Node, as identity: String) -> Node {
        var copy = node
        copy.id = identity
        return copy
    }
}

extension NavigationStack {
    /// The colour the bar draws on its background: the navigation title and
    /// the native navigation and toolbar affordances. Destructive actions keep
    /// the platform's warning colour.
    @_spi(Host) public func barForegroundColor(_ value: Color) -> NavigationStack {
        setValue(NavigationStackContract.barForegroundColor, value)
    }
}

/// A `Page` over an already-built node - what a `.navigationDestination`
/// factory makes once it has the value or item it was registered for.
private struct DestinationPage: Page {
    var node: Node
}

extension View {
    /// Registers the page the enclosing `NavigationStack` shows for a pushed
    /// value of `type` - SwiftUI's
    /// `.navigationDestination(for:content:)`:
    ///
    ///     NavigationStack(path: $path) {
    ///         HomeView()
    ///             .navigationDestination(for: FilePage.self) {
    ///                 FileEdittingView(filePage: $0)
    ///             }
    ///     }
    ///
    /// The registration rides on this view's node, where the stack reads it
    /// for each route on its path.
    public func navigationDestination<D: Hashable, C: View>(
        for type: D.Type = D.self,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> ModifiedContent {
        revised {
            $0.destinations[ObjectIdentifier(type)] = { value in
                destination(value as! D).node
            }
        }
    }

    /// Registers the page the enclosing `NavigationStack` pushes while
    /// `item` is set - SwiftUI's `.navigationDestination(item:destination:)`:
    ///
    ///     SettingsView()
    ///         .navigationDestination(item: $addRoute) { route in
    ///             ModelEditSheetView(defaultKind: route)
    ///         }
    ///
    /// Setting `item` pushes the destination; a way back off it - the
    /// platform's, or a `\.dismiss` - clears `item`.
    public func navigationDestination<D: Hashable, C: View>(
        item: Binding<D?>,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> ModifiedContent {
        revised {
            $0.itemDestination = Node.ItemDestination(
                make: { item.wrappedValue.map { destination($0).node } },
                dismiss: { item.wrappedValue = nil })
        }
    }
}
