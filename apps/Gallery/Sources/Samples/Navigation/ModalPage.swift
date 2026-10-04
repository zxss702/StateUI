@_spi(Host) import StateUI

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
                .font(.system(size: 20))
                .bold()
                .multilineTextAlignment(.center)

            Text("The host chooses the presentation that belongs to this platform.")
                .font(.system(size: 13))
                .foregroundStyle(Palette.subtle)
                .multilineTextAlignment(.center)

            Button("Close", action: { nav.dismiss() })
                .background(Palette.accent)
                .foregroundStyle(.white)
                .shape(.roundedRectangle(8))
                .contentPadding(EdgeInsets(20, 10))
                .horizontalAlignment(.center)
                

            Button("Present another", action: { nav.present(.page) })
                .contentPadding(EdgeInsets(20, 10))
                .horizontalAlignment(.center)
                

            Text("Depth: \(nav.sheets.count)")
                .font(.system(size: 12, design: .monospaced))
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
