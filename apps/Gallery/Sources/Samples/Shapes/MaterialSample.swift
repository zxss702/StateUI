import StateUI

/// The platform's materials and a `LinearGradient`, each worn as a
/// `ShapeStyle` on a background - translucency that shows the page through.
struct MaterialSample: SampleContent, ExampleContent {
    static let id = "materials"
    static let title = "Materials"
    static let summary = "Cards painted in the platform's own materials, over colour they show through."

    /// The materials a host draws - thinnest to thickest, then the one a
    /// toolbar wears.
    private static let materials: [(name: String, style: Material)] = [
        ("ultraThin", .ultraThinMaterial),
        ("thin", .thinMaterial),
        ("regular", .regularMaterial),
        ("thick", .thickMaterial),
        ("ultraThick", .ultraThickMaterial),
        ("bar", .barMaterial),
    ]

    static let code = """
        /// The materials a host draws - thinnest to thickest.
        static let materials: [(name: String, style: Material)] = [
            ("ultraThin", .ultraThinMaterial),
            ("thin", .thinMaterial),
            ("regular", .regularMaterial),
            ("thick", .thickMaterial),
            ("ultraThick", .ultraThickMaterial),
            ("bar", .barMaterial),
        ]

        ZStack {
            // Colour and a gradient, so the materials have something to show
            // through.
            VStack {
                Rectangle()
                    .fill(LinearGradient(colors: [.pink, .purple],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                Rectangle()
                    .fill(LinearGradient(colors: [.orange, .mint],
                                         startPoint: .leading,
                                         endPoint: .trailing))
            }

            VStack {
                ForEach(Self.materials, id: \\.name) { entry in
                    Text(entry.name)
                        .font(.system(size: 13))
                        .padding(EdgeInsets(16, 8))
                        .background(entry.style, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .spacing(6)
        }
        """

    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .fill(LinearGradient(colors: [.pink, .purple],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                Rectangle()
                    .fill(LinearGradient(colors: [.orange, .mint],
                                         startPoint: .leading,
                                         endPoint: .trailing))
            }

            VStack {
                ForEach(Self.materials, id: \.name) { entry in
                    Text(entry.name)
                        .font(.system(size: 13))
                        .padding(EdgeInsets(16, 8))
                        .background(entry.style, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .spacing(6)
            .padding(12)
        }
        .shape(.roundedRectangle(14))
        .clipped()
    }

    var notes: (any View)? {
        VStack {
            Text("A `Material` is a ShapeStyle, so it goes anywhere a colour or "
                + "a gradient does - here as `.background(_:in:)` behind each "
                + "row's words. Where the platform draws one, the room's light "
                + "and what sits behind the window come through it; elsewhere "
                + "it stands for a soft translucency in the room's tone.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)

            Text("`LinearGradient(colors:startPoint:endPoint:)` is the same "
                + "kind of style, so it fills a `Rectangle` the way a material "
                + "fills a shape - the two stripes under the rows are both "
                + "gradients.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.subtle)
        }
        .spacing(12)
    }
}
