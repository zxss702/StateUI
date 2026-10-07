// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `NSViewRepresentable`: a `View` backed by an AppKit view of the author's
// own, as SwiftUI spells it. The element is the host's `AppKitRepresentable`
// contract: a `factory` token names the slot the representable lives in, and a
// `version` that moves on every build is what brings `updateNSView` to the
// view.

#if os(macOS)
import AppKit
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

/// A `View` that wraps an AppKit view of the author's own.
///
///     struct Preview: NSViewRepresentable {
///         let url: URL
///
///         func makeNSView(context: Context) -> QLPreviewView {
///             let view = QLPreviewView()
///             view.previewItem = url as QLPreviewItem
///             return view
///         }
///
///         func updateNSView(_ view: QLPreviewView, context: Context) {}
///     }
///
/// `makeNSView` runs once, when the element's view is made; `updateNSView`
/// runs again every time the representable is rebuilt - the place to copy what
/// the struct now holds onto the view. `makeCoordinator` answers the object
/// both are handed through `context.coordinator`, made once per element.
@MainActor
public protocol NSViewRepresentable: View {
    /// The AppKit view this representable shows.
    associatedtype NSViewType: NSView

    /// The object `makeNSView` and `updateNSView` share through the context.
    associatedtype Coordinator = Void

    /// The coordinator this element keeps, made before its view is.
    func makeCoordinator() -> Coordinator

    /// Makes the view, once.
    func makeNSView(context: Context) -> NSViewType

    /// Copies what the representable now holds onto the view, every rebuild.
    func updateNSView(_ nsView: NSViewType, context: Context)

    /// The view is going away.
    func dismantleNSView(_ nsView: NSViewType, context: Context)

    /// What the callbacks are handed.
    typealias Context = NSViewRepresentableContext<Self>
}

extension NSViewRepresentable {
    /// The element this representable leaves in the tree. It is built wherever
    /// the differ builds - the representable's callbacks are the main actor's,
    /// its description is nobody's.
    nonisolated public var node: Node {
        RepresentableAnchor(content: self).node
    }

    /// `dismantleNSView` does nothing unless the representable says otherwise.
    public func dismantleNSView(_ nsView: NSViewType, context: Context) {}
}

extension NSViewRepresentable where Coordinator == Void {
    /// No coordinator: `context.coordinator` is `()`.
    public func makeCoordinator() -> Coordinator { () }
}

/// What `makeNSView`, `updateNSView` and `dismantleNSView` are handed: the
/// coordinator this element made.
public struct NSViewRepresentableContext<Representable: NSViewRepresentable> {
    /// The object `makeCoordinator` answered, kept for the element's life.
    public let coordinator: Representable.Coordinator

    init(coordinator: Representable.Coordinator) {
        self.coordinator = coordinator
    }
}

/// The contract the representable's element crosses by - one node type for
/// every representable, the slot token and the build's version for members.
enum RepresentableContract: ElementContract {
    /// The node type the contract declares.
    static let nodeType: NodeType = "AppKitRepresentable"

    /// A representable is a view.
    static let tiers: [any Contract.Type] = [ViewContract.self]

    /// The slot the element's representable lives in.
    static let factory = ElementProperty<Self, String>("factory")

    /// This build's number - a changed value is what brings `updateNSView`.
    static let version = ElementProperty<Self, Int>("version")

    /// The members declared here.
    static let members: [any ContractMember] = [factory, version]
}

/// One representable's place in the tree, as a value of it describes itself:
/// the element's slot - its coordinator and the value it now is - keyed to the
/// registry the host's container reads.
private struct RepresentableAnchor<Content: NSViewRepresentable>: View {
    /// The representable, as the last rebuild handed it down.
    let content: Content

    /// The element's slot, kept across rebuilds.
    @State private var slot = RepresentableSlot<Content>()

    var body: some View {
        RepresentableElement(slot: slot, content: content)
    }
}

/// The element node itself: the contract's node, carrying the slot's token and
/// the version this build numbers.
private struct RepresentableElement<Content: NSViewRepresentable>: View {
    /// The element's slot.
    let slot: RepresentableSlot<Content>

    /// The representable this build was handed - the value `updateNSView`
    /// reads back.
    let content: Content

    var node: Node {
        slot.latest = content
        RepresentableSlots.keep(slot)

        var element = Leaf()
        element = element
            .setValue(RepresentableContract.factory, slot.id.uuidString)
            .setValue(RepresentableContract.version, RepresentableVersions.take())
        return element.node
    }

    /// The view that draws: the contract's node and no more.
    struct Leaf: View, PropertyContainer {
        var node = Node(contract: RepresentableContract.self)
    }
}

/// A number no two builds share - what makes `version` a changed property on
/// every one.
private enum RepresentableVersions {
    nonisolated(unsafe) private static var next = 0

    /// The next number.
    static func take() -> Int {
        defer { next &+= 1 }
        return next
    }
}

/// The element's own half of a representable, as the host's container asks it:
/// make the view, update it, dismantle it. The representable itself is erased.
private protocol RepresentableBox: AnyObject {
    /// Makes the view, making the coordinator first where it is not yet made.
    @MainActor func makeView() -> NSView

    /// `updateNSView` for the value this slot was last handed.
    @MainActor func updateView(_ view: NSView)

    /// `dismantleNSView` for the view leaving the tree.
    @MainActor func dismantleView(_ view: NSView)
}

/// One element's representable: the value it now is, its coordinator, and the
/// callbacks the container calls.
private final class RepresentableSlot<Content: NSViewRepresentable>: RepresentableBox {
    /// Who the registry knows this slot by.
    let id = UUID()

    /// The value the last build handed down.
    var latest: Content?

    /// The coordinator, made before the first view.
    var coordinator: Content.Coordinator?

    /// Who this slot is, in `factory` form.
    var token: String { id.uuidString }

    private var context: NSViewRepresentableContext<Content> {
        NSViewRepresentableContext(coordinator: coordinator!)
    }

    @MainActor func makeView() -> NSView {
        guard let latest else { return NSView() }

        if coordinator == nil { coordinator = latest.makeCoordinator() }
        return latest.makeNSView(context: context)
    }

    @MainActor func updateView(_ view: NSView) {
        guard let latest, let typed = view as? Content.NSViewType else { return }

        latest.updateNSView(typed, context: context)
    }

    @MainActor func dismantleView(_ view: NSView) {
        guard let latest, let typed = view as? Content.NSViewType else { return }

        latest.dismantleNSView(typed, context: context)
    }
}

/// The slots by their `factory` token - written as each element builds, read
/// by the container the host makes for it. Every touch of it is on the UI
/// thread or a deinit; the dictionary itself is the only shared state.
private enum RepresentableSlots {
    /// Every live slot, by token.
    nonisolated(unsafe) private static var slots: [String: RepresentableBox] = [:]

    /// The slot a token names.
    static func box(for token: String?) -> RepresentableBox? {
        token.flatMap { slots[$0] }
    }

    /// Remembers a slot, as its element builds.
    static func keep<Content>(_ slot: RepresentableSlot<Content>) {
        slots[slot.token] = slot
    }

    /// Forgets a slot, as its container goes.
    static func drop(_ token: String?) {
        _ = token.map { slots.removeValue(forKey: $0) }
    }
}

/// The view the host makes for an `AppKitRepresentable` element: a container
/// that holds the representable's view at its own size.
@MainActor
final class RepresentableContainerView: NSView {
    /// The slot the element named, once `factory` lands.
    private var box: RepresentableBox?

    /// The token, so a container going away can drop the slot.
    private var token: String?

    /// The representable's view.
    private var mounted: NSView?

    /// `factory` applied: the slot is installed and its view made.
    func install(token: String?) {
        self.token = token
        box = RepresentableSlots.box(for: token)
        mounted?.removeFromSuperview()
        mounted = nil

        guard let box else { return }

        let view = box.makeView()
        view.autoresizingMask = [.width, .height]
        view.frame = bounds
        addSubview(view)
        mounted = view
    }

    /// `version` applied: the build moved, and `updateNSView` hears of it.
    func refresh() {
        guard let mounted else { return }

        box?.updateView(mounted)
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)

        guard newSuperview == nil, let mounted else { return }

        box?.dismantleView(mounted)
        self.mounted = nil
    }

    deinit {
        RepresentableSlots.drop(token)
    }
}

extension AppKitRegistrations {
    /// The `AppKitRepresentable` element: the container, its `factory`
    /// installing the slot's view and its `version` refreshing it.
    static func representable(_ registry: Registry<NSView>) {
        registry.add(RepresentableContract.self, create: { _ in
            RepresentableContainerView()
        }) { container in
            container.property(RepresentableContract.factory) { view, token in
                view.install(token: token)
            }
            container.property(RepresentableContract.version) { view, _ in
                view.refresh()
            }
        }
    }
}
#endif
