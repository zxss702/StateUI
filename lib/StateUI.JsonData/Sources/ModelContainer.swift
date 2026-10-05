// SPDX-License-Identifier: Apache-2.0

import JsonData
import StateUI

// The model context in the environment, as SwiftData hands it down in SwiftUI:
// `.modelContainer(...)` above, `@Environment(\.modelContext)` and `@Query`
// below. The types are whichever `JsonData` exports - SwiftData's where the
// platform has it, JsonDataCore's elsewhere.

/// The `\.modelContext` slot: the nearest container's main context.
private struct ModelContextKey: EnvironmentKey {
    /// As SwiftUI does, a read with no container above is a programming error.
    static var defaultValue: ModelContext {
        preconditionFailure(
            "No modelContext in the environment - write .modelContainer(...) on a view above.")
    }
}

extension EnvironmentValues {
    /// The model context views beneath read and `@Query` fetches through.
    public var modelContext: ModelContext {
        get { self[ModelContextKey.self] }
        set { self[ModelContextKey.self] = newValue }
    }
}

/// Carries a value out of `MainActor.assumeIsolated`, whose result must be
/// `Sendable` though the value read here never leaves the UI thread it was
/// read on.
private struct OnMain<T>: @unchecked Sendable {
    let value: T
}

extension ModelContainer {
    /// `mainContext`, read where the caller already stands on the UI thread -
    /// the main actor for every host. JsonDataCore's is a plain `let`;
    /// SwiftData's is main-actor-isolated, which is the hop this performs.
    var contextOnMain: ModelContext {
        MainActor.assumeIsolated { OnMain(value: mainContext) }.value
    }
}

extension View {
    /// Hands `container`'s main context to the views beneath, as the
    /// `\.modelContext` value and as an object `@Environment(ModelContext)`
    /// resolves.
    public func modelContainer(_ container: ModelContainer) -> some View {
        environment(container.contextOnMain)
            .environment(\.modelContext, container.contextOnMain)
    }

    /// A container made once for the views beneath - the form previews use,
    /// holding its store in memory when `inMemory`.
    public func modelContainer(
        for types: any PersistentModel.Type...,
        inMemory: Bool = false
    ) -> some View {
        ModelContainerHost(content: self, types: types, inMemory: inMemory)
    }
}

/// The view that owns a `.modelContainer(for:inMemory:)` container, so the
/// container is made once and kept while the view stands.
private struct ModelContainerHost<Content: View>: View {
    /// The container, made on first build and kept across rebuilds.
    @State private var container: ModelContainer?

    let content: Content
    let types: [any PersistentModel.Type]
    let inMemory: Bool

    var body: some View {
        if container == nil {
            let types = OnMain(value: self.types), inMemory = self.inMemory
            container = MainActor.assumeIsolated {
                OnMain(value: try! ModelContainer(
                    for: Schema(types.value),
                    configurations: [ModelConfiguration(isStoredInMemoryOnly: inMemory)]))
            }.value
        }

        return content.modelContainer(container!)
    }
}
