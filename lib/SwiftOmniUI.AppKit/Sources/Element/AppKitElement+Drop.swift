// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
import ObjectiveC
@_spi(Host) import SwiftOmniUI
@_spi(Host) import SwiftOmniUIHost

// File drops: `allowDrop` registers a view for `.fileURL` and names its
// recipient. NSView declares `NSDraggingDestination` without implementing it,
// so the methods are added to it once, each asking `dropRecipient` - a class
// with methods of its own, a text field's among them, still hears its own,
// and only a view that registered for the types is asked at all.

extension AppKitElement {
    /// Whether `view` takes file drops: its dragged-types registration and
    /// its recipient, both ways.
    func configureDropTarget(for view: NSView) {
        if value(.allowDrop)?.bool == true {
            _ = Self.dropMethods
            view.registerForDraggedTypes([.fileURL])
            view.dropRecipient = self
        } else {
            view.unregisterDraggedTypes()
            view.dropRecipient = nil
        }
    }

    /// NSView's missing drop methods, added once.
    private static let dropMethods: Void = {
        class_addMethod(
            NSView.self, sel_getUid("draggingEntered:"), imp_implementationWithBlock(
                { (view: NSView, info: NSDraggingInfo) -> NSDragOperation in
                    guard let element = view.dropRecipient else { return [] }
                    element.send(.dragOver, [])
                    return .copy
                } as @convention(block) (NSView, NSDraggingInfo) -> NSDragOperation), "Q@:@")
        class_addMethod(
            NSView.self, sel_getUid("draggingUpdated:"), imp_implementationWithBlock(
                { (view: NSView, info: NSDraggingInfo) -> NSDragOperation in
                    view.dropRecipient == nil ? [] : .copy
                } as @convention(block) (NSView, NSDraggingInfo) -> NSDragOperation), "Q@:@")
        class_addMethod(
            NSView.self, sel_getUid("draggingExited:"), imp_implementationWithBlock(
                { (view: NSView, info: NSDraggingInfo?) -> Void in
                    view.dropRecipient?.send(.dragLeave, [])
                } as @convention(block) (NSView, NSDraggingInfo?) -> Void), "v@:@")
        class_addMethod(
            NSView.self, sel_getUid("prepareForDragOperation:"), imp_implementationWithBlock(
                { (view: NSView, info: NSDraggingInfo) -> Bool in
                    view.dropRecipient != nil
                } as @convention(block) (NSView, NSDraggingInfo) -> Bool), "B@:@")
        class_addMethod(
            NSView.self, sel_getUid("performDragOperation:"), imp_implementationWithBlock(
                { (view: NSView, info: NSDraggingInfo) -> Bool in
                    guard let element = view.dropRecipient else { return false }
                    let urls = info.draggingPasteboard
                        .readObjects(forClasses: [NSURL.self], options: nil)?
                        .compactMap { ($0 as? URL)?.path } ?? []
                    guard !urls.isEmpty else { return false }
                    let at = view.convert(info.draggingLocation, from: nil)
                    element.send(
                        .dropPaths,
                        [.strings(urls), .numbers([Double(at.x), Double(at.y)])])
                    return true
                } as @convention(block) (NSView, NSDraggingInfo) -> Bool), "B@:@")
    }()
}

/// The element a view's drops go to, weakly, so the view outliving its
/// element loses them rather than dangling.
private final class DropRecipientBox: NSObject {
    weak var element: AppKitElement?
}

nonisolated(unsafe) private var dropRecipientKey: UInt8 = 0

extension NSView {
    /// Which element this view's drop messages go to; nil for none.
    var dropRecipient: AppKitElement? {
        get {
            (objc_getAssociatedObject(self, &dropRecipientKey) as? DropRecipientBox)?.element
        }
        set {
            let box: DropRecipientBox? = newValue.map { element in
                let box = DropRecipientBox()
                box.element = element
                return box
            }
            objc_setAssociatedObject(self, &dropRecipientKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
#endif
