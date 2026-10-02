import StateUI

/// A page presented OVER everything - the bars, the menu and the stack alike.
///
/// It carries its own way out because the modal presentation covers the page
/// that opened it.
struct ModalPage: View {
    /// Where the gallery is. A modal closes itself by shortening the array it
    /// is a member of, exactly as a pushed page pops itself.
    let nav: Navigation

    /// The page itself.
    @Environment private var page: PageSession

    var body: some View {
        VStack {
            SectionTitle("Over everything")

            Text("Native modal page")
                .fontSize(20)
                .fontAttributes(.bold)
                .multilineTextAlignment(.center)

            Text("The host chooses the presentation that belongs to this platform.")
                .fontSize(13)
                .foregroundStyle(Palette.subtle)
                .multilineTextAlignment(.center)

            Button("Close")
                .background(Palette.accent)
                .foregroundStyle(.white)
                .shape(.roundedRectangle(8))
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
                .onClicked { nav.dismiss() }

            Button("Present another")
                .contentPadding(20, 10)
                .horizontalAlignment(.center)
                .onClicked { nav.present(.page) }

            Text("Depth: \(nav.sheets.count)")
                .fontSize(12)
                .fontFamily("Menlo")
                .foregroundStyle(Palette.subtle)
                .multilineTextAlignment(.center)
        }
        .spacing(16)
        .contentPadding(24)
        .verticalAlignment(.center)
        .onAppear {
            page.title = "Presented"
            page.background = Palette.surface
        }
    }
}
