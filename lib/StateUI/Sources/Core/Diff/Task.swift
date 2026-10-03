// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// `.task`: an async job tied to the view's life - started on appear, cancelled
// on disappear.
// Design: docs/design/core/identity-and-diffing.md#created-and-destroying

extension View {
    /// Runs an async job while the view is on screen: started when the view is
    /// first described, cancelled when it leaves the tree:
    ///
    ///     List { … }
    ///         .task { await items.load() }
    ///
    /// Once per element, the outermost first, as `.onAppear` is - and where
    /// the element leaves and comes back, a new job for a new element. The job
    /// outliving its view is cancelled, so a load in flight is dropped rather
    /// than written into state nobody shows.
    ///
    /// - Parameter work: what to run; cancelled as the view leaves.
    public func task(
        _ work: @escaping @Sendable () async -> Void
    ) -> ModifiedContent {
        let box = TaskBox()
        return onAppear {
            box.task = Task { await work() }
        }
        .onDisappear {
            box.task?.cancel()
        }
    }
}

/// The running job a `.task` started, so its disappear can cancel it.
private final class TaskBox: @unchecked Sendable {
    /// The job running for the view, or none yet or anymore.
    var task: Task<Void, Never>?
}
