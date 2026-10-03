// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.alert`: the platform's own dialog, driven by a bool - an act asked of the
// page that is showing.
// Design: docs/design/core/acts.md#dialogs

extension View {
    /// Presents the platform's alert while `isPresented` holds.
    ///
    ///     .alert("Sign in", isPresented: $failed) {
    ///         Button("OK", role: .cancel) {}
    ///     } message: {
    ///         Text("The token was refused.")
    ///     }
    ///
    /// The buttons are the views in `actions`: a `Button`'s caption names the
    /// choice and its action runs when it is pressed; a `.cancel` role
    /// dismisses and a `.destructive` role is marked dangerous. One cancel
    /// button is an announcement, one choice beside it a confirmation, and
    /// more an action list - the platform draws each as its own dialog.
    /// Answering writes `isPresented` back to false, whichever button took it.
    ///
    /// - Parameters:
    ///   - title: what the alert is about.
    ///   - isPresented: whether it is up, both ways.
    ///   - actions: the buttons to offer.
    ///   - message: the text under the title.
    public func alert<Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        AlertAnchor(
            base: self, title: title, presented: isPresented,
            actions: actions, message: message)
    }
}

/// The anchor `.alert` leaves in the tree: the view it was written on, plus a
/// watch that asks the dialog act when the binding turns up.
struct AlertAnchor<Actions: View, Message: View>: View {
    /// The view `.alert` was written on.
    let base: any View

    /// What the alert is about.
    let title: String

    /// Whether the alert is up.
    let presented: Binding<Bool>

    /// The buttons, as views.
    let actions: () -> Actions

    /// The message, as views.
    let message: () -> Message

    /// Guards a re-entry while the act is out: a bool flipping twice, a
    /// presented alert must not be asked again.
    @State private var asking = false

    var body: some View {
        Group {
            base
            EmptyView()
                .onChange(of: presented.wrappedValue) { _, shown in
                    guard shown, !asking else { return }
                    asking = true
                    defer { asking = false }
                    do {
                        try await ask()
                    } catch {
                        // No page to ask of, or the host could not: the answer
                        // is the alert is not up.
                    }
                    presented.wrappedValue = false
                }
        }
    }

    /// The buttons the actions describe, in the order they were written.
    private var buttons: [AlertButton] {
        var found: [AlertButton] = []
        collectButtons(in: actions().node.built, into: &found)
        return found
    }

    /// The message's words: the first text the message describes.
    private var messageText: String {
        words(in: message().node.built) ?? ""
    }

    /// Asks the dialog the buttons amount to, then runs the pressed one's
    /// action - the answer reaching nobody runs nothing.
    private nonisolated(nonsending) func ask() async throws {
        let cancels = buttons.filter { $0.role == .cancel }
        let pressed: String?
        if buttons.count <= 1, let cancel = cancels.first ?? buttons.first {
            try await Dialogs.alert(title, message: messageText, cancel: cancel.title)
            pressed = cancel.title
        } else if buttons.count == 2, let cancel = cancels.first,
                  let accept = buttons.first(where: { $0.role != .cancel }) {
            let yes = try await Dialogs.confirm(
                title, message: messageText, accept: accept.title, cancel: cancel.title)
            pressed = yes ? accept.title : cancel.title
        } else {
            pressed = try await Dialogs.chooseAction(
                title,
                cancel: cancels.first?.title,
                destruction: buttons.first { $0.role == .destructive }?.title,
                buttons: buttons.filter { $0.role == .normal }.map(\.title))
        }
        if let pressed, let handler = buttons.first(where: { $0.title == pressed })?.handler {
            try await handler()
        }
    }

    /// The words a button or a text carries, and the role marking a button.
    private var textProp: Prop { Prop("text") }
    private var roleProp: Prop { Prop("role") }

    /// One button extracted from the actions: its caption, its mark and what
    /// it does.
    private struct AlertButton {
        let title: String
        let role: ButtonRole
        let handler: EventHandler?
    }

    /// Every `Button` the node stands for, in the order it stands.
    private func collectButtons(in node: Node, into found: inout [AlertButton]) {
        if node.type.name == "Button", let title = node.props[textProp]?.string {
            let role = node.props[roleProp].flatMap(ButtonRole.init(propValue:)) ?? .normal
            found.append(AlertButton(title: title, role: role, handler: node.events[Event("clicked")]))
        }
        for child in node.children { collectButtons(in: child, into: &found) }
    }

    /// The first view's words the node stands for.
    private func words(in node: Node) -> String? {
        if ["Text", "Label"].contains(node.type.name), let words = node.props[textProp]?.string {
            return words
        }
        return node.children.lazy.compactMap(words).first
    }
}
