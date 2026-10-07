import SwiftOmniUI
import Observation

/// A model edited by a view that only borrows it: `@Observable` makes the
/// model's writes reach whoever read them, `@Bindable` lends a property as a
/// `Binding` a control can write.
@Observable
private final class Counter {
    var count = 0.0
    var label = "apples"
}

/// The row doing the editing - it never OWNS the counter, so it declares
/// `@Bindable`, and `$model.count` is a `Binding` straight into the model.
private struct CounterRow: View {
    @Bindable var model: Counter

    var body: some View {
        HStack {
            Stepper($model.count, in: 0 ... 99)
            TextField("name", text: $model.label)
        }
        .spacing(8)
    }
}

struct BindableSample: SampleContent, ExampleContent {
    /// The model. One owner; every row below borrows the same one.
    @State private var model = Counter()

    static let id = "bindable"
    static let title = "Bindable models"
    static let summary = "An @Observable model handed down, its properties lent to controls with @Bindable."

    static let code = """
        @Observable
        final class Counter {
            var count = 0.0
            var label = "apples"
        }

        struct CounterRow: View {
            // The row borrows the model: `@Bindable` says so, and
            // `$model.count` is a Binding into it.
            @Bindable var model: Counter

            var body: some View {
                HStack {
                    Stepper($model.count, in: 0 ... 99)
                    TextField("name", text: $model.label)
                }
            }
        }

        @State private var model = Counter()

        VStack {
            Text("\\(model.count) \\(model.label)")

            // Two rows, one model - a step in either is read by both, and by
            // the caption.
            CounterRow(model: model)
            CounterRow(model: model)
        }
        """

    var body: some View {
        VStack {
            Text("\(Int(model.count)) \(model.label)")
                .font(.system(size: 15))
                .accessibilityIdentifier("bindable.caption")

            CounterRow(model: model)
            CounterRow(model: model)
        }
        .spacing(10)
    }

    var notes: (any View)? {
        VStack {
            Text("The caption and both rows read the SAME `@Observable` model. "
                + "Step once in either row and the caption and the other row "
                + "move too - a body that read a property is built again when "
                + "that property is written, and nothing else is.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("`@Bindable` is what a borrowing view declares: the model "
                + "arrives in the view's initializer like any argument, and "
                + "`$model.count` / `$model.label` are `Binding`s the row "
                + "hands its controls. The owner is the `@State` on this "
                + "sample - the one place the model is kept.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }
}
