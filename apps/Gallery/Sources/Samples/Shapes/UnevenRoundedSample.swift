import SwiftOmniUI

/// `UnevenRoundedRectangle`: each corner rounds by its own radius.
struct UnevenRoundedSample: SampleContent, ExampleContent {
    static let id = "uneven-rounded"
    static let title = "Uneven corners"
    static let summary = "A rectangle whose four corners each round their own way."

    static let code = """
        HStack {
            // A speech bubble's tail end - sharp where it points.
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 16,
                bottomTrailingRadius: 2, topTrailingRadius: 16,
                style: .continuous)
                .fill(.tint)

            // A tab - rounded above, square below.
            UnevenRoundedRectangle(
                topLeadingRadius: 12, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 12,
                style: .circular)
                .fill(.secondary)
        }
        """

    var notes: (any View)? {
        VStack {
            Text("A corner not named - or named 0 - stays square. `style:` is "
                + "`RoundedCornerStyle`: `.continuous` is the squircle where "
                + "the host has one, `.circular` the ordinary bend.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }

    var body: some View {
        VStack {
            HStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 16,
                    bottomTrailingRadius: 2, topTrailingRadius: 16,
                    style: .continuous)
                    .fill(Palette.brand)
                    .frame(width: 120, height: 64)

                UnevenRoundedRectangle(
                    topLeadingRadius: 12, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 12,
                    style: .circular)
                    .fill(Palette.accent)
                    .frame(width: 120, height: 64)
            }
            .spacing(16)

            Text("Bubble tail                        Tab")
                .font(.system(size: 11))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(8)
        .accessibilityIdentifier("unevenRounded.demo")
    }
}
