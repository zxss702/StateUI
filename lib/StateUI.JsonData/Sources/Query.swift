// SPDX-License-Identifier: Apache-2.0

// `@Query`, the model layer's table in a view: the rows matching a fetch
// descriptor, re-fetched when the context's store changes. It resolves the
// context from the environment like SwiftUI's - `.modelContainer` above -
// and drives rebuilds through `@Observable` tracking: a build that read
// `items` is rebuilt when the store changes them.
//
// The context observation is the one genuine platform difference: SwiftData
// reports a save through `ModelContext.didSave`, while JsonDataCore follows
// the store with `startObservation`.

import Foundation
import JsonData
import StateUI

/// A value `MainActor.assumeIsolated` hands back, whose result must be
/// `Sendable` though what the UI thread reads never leaves it.
private struct OnMain<T>: @unchecked Sendable {
    let value: T
}

/// The rows a `Query` holds: what was last fetched, refetched when the store
/// reports a change. Reading `items` during a build records the dependency.
@MainActor
@Observable
final class QueryResult<Element: PersistentModel> {
    /// What the last fetch answered.
    private(set) var items: [Element] = []

    /// What the query asks for.
    let descriptor: FetchDescriptor<Element>

    /// The context the query follows, once the environment answers.
    private(set) weak var context: ModelContext?

    /// The store's observation - a GRDB cancellable under JsonDataCore, a
    /// notification token under SwiftData. Written only on the main actor;
    /// `nonisolated` so `deinit` can release it wherever the object dies.
    nonisolated(unsafe) private var observation: Any?

    nonisolated init(descriptor: FetchDescriptor<Element>) {
        self.descriptor = descriptor
    }

    /// Binds the context the environment resolved; idempotent for one context.
    func attach(to context: ModelContext) {
        guard self.context !== context else { return }
        self.context = context
        refetch()

        #if canImport(SwiftData)
        observation = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: context, queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refetch() }
        }
        #else
        observation = context.startObservation(
            descriptor,
            onChange: { [weak self] newItems in
                self?.items = newItems
            })
        #endif
    }

    /// Fetches again and reports the rows.
    private func refetch() {
        guard let context else { return }
        items = (try? context.fetch(descriptor)) ?? []
    }

    deinit {
        #if canImport(SwiftData)
        if let token = observation as? NSObjectProtocol {
            NotificationCenter.default.removeObserver(token)
        }
        #endif
    }
}

/// A view's handle on the model layer's rows:
///
///     @Query private var records: [Record]
///     @Query(sort: \Folder.lastAccessedAt, order: .reverse)
///         private var folders: [Folder]
///
/// The context comes from the environment - `.modelContainer(...)` on an
/// ancestor, as SwiftUI's does. Reads re-render when the store changes.
@propertyWrapper
public struct Query<Element: PersistentModel> {
    /// The context `.modelContainer` wrote above - resolved before each build.
    @Environment(\.modelContext) private var context: ModelContext

    /// The rows, kept across rebuilds.
    @State private var result: QueryResult<Element>

    /// Every row of the type, unordered.
    public init() {
        _result = State(wrappedValue: QueryResult(descriptor: FetchDescriptor<Element>()))
    }

    /// The rows ordered by one key.
    public init<Value: Comparable & Sendable>(
        sort keyPath: KeyPath<Element, Value> & Sendable,
        order: SortOrder = .forward
    ) {
        _result = State(wrappedValue: QueryResult(
            descriptor: FetchDescriptor(sortBy: [SortDescriptor(keyPath, order: order)])))
    }

    /// The rows ordered by descriptors. Qualified off SwiftData's platforms:
    /// Foundation's own `SortDescriptor` otherwise shadows the model layer's.
    #if canImport(SwiftData)
    public init(sort descriptors: [SortDescriptor<Element>]) {
        _result = State(wrappedValue: QueryResult(
            descriptor: FetchDescriptor(sortBy: descriptors)))
    }
    #else
    public init(sort descriptors: [JsonDataCore.SortDescriptor<Element>]) {
        _result = State(wrappedValue: QueryResult(
            descriptor: FetchDescriptor(sortBy: descriptors)))
    }
    #endif

    /// The matching rows.
    public var wrappedValue: [Element] {
        // Builds run on the UI thread, which is the main actor for every host.
        let context = _context, result = _result
        return MainActor.assumeIsolated {
            result.wrappedValue.attach(to: context.wrappedValue)
            return OnMain(value: result.wrappedValue.items)
        }.value
    }
}
