import Foundation
import StateUI
import StateUIJsonData

/// A row the sample's store keeps.
@Model
final class TrackedTask {
    var title: String
    var done: Bool

    init(title: String, done: Bool = false) {
        self.title = title
        self.done = done
    }
}

/// `@Query` and `.modelContainer`: the model layer's rows as view state.
struct ModelLayerSample: SampleContent, ExampleContent {
    static let id = "model-layer"
    static let title = "A model layer"
    static let summary = "@Query lists what the store holds; writes land through the context."

    static let code = """
        @Model
        final class TrackedTask {
            var title: String
            var done: Bool
        }

        struct TaskList: View {
            @Environment(\\.modelContext) private var context
            @Query(sort: \\TrackedTask.title) private var tasks: [TrackedTask]
            @State private var next = 1

            var body: some View {
                VStack {
                    ForEach(tasks) { task in
                        Toggle(task.title, isOn: binding(for: task.done))
                    }
                    Button("Add task", action: add)
                }
            }
        }

        TaskList()
            .modelContainer(for: TrackedTask.self, inMemory: true)
        """

    var notes: (any View)? {
        VStack {
            Text("`.modelContainer(for:inMemory:)` makes the container once and "
                + "hands its main context down; `@Query` resolves it from the "
                + "environment and re-fetches when the store reports a save.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("On Apple platforms `JsonData` IS SwiftData and the query "
                + "follows `ModelContext.didSave`; elsewhere it is JsonDataCore "
                + "and the store's own observation answers - the sample reads "
                + "the same either way.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }

    var body: some View {
        TaskList()
            .modelContainer(for: TrackedTask.self, inMemory: true)
    }
}

/// The list the sample shows: every stored task, an add and a clear-done.
private struct TaskList: View {
    /// The context `.modelContainer` wrote above.
    @Environment(\.modelContext) private var context

    /// What the store holds, ordered.
    @Query(sort: \TrackedTask.title) private var tasks: [TrackedTask]

    /// The next task's number.
    @State private var next = 1

    var body: some View {
        VStack {
            if tasks.isEmpty {
                Text("Nothing stored - add one.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.subtle)
            }

            ForEach(tasks) { task in
                HStack {
                    Text(task.title)
                        .font(.system(size: 14))
                        .strikethrough(task.done)
                }
            }

            HStack {
                Button("Add task") {
                    context.insert(TrackedTask(title: "Task \(next)"))
                    next += 1
                    try? context.save()
                }
                .accessibilityIdentifier("modelLayer.add")

                Button("Complete first") {
                    if let first = tasks.first {
                        first.done = true
                        try? context.save()
                    }
                }
                .font(.system(size: 13))
                .accessibilityIdentifier("modelLayer.complete")
            }
            .spacing(10)

            Text("\(tasks.count) stored")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Palette.accent)
                .accessibilityIdentifier("modelLayer.count")
        }
        .spacing(10)
    }
}
