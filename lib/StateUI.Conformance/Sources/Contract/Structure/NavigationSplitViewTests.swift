// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

@_spi(Host) import StateUI
@_spi(Host) import StateUIHost

/// `NavigationSplitViewContract` on a host: the sidebar beside the detail shows as the binding says; the user hiding or showing
/// it is heard on the binding, the program's is shown.
@_spi(Host) public enum NavigationSplitViewTests: ConformanceFamily {
    public static let name = "NavigationSplitView"

    public static var cases: [ConformanceCase] {
        [
            ConformanceCase("standsAloneShowingItsDetail", proves: [
                Covered(NavigationSplitViewContract.self), Covered(ViewContract.frameChanged, on: "Text"),
            ]) { s in
                let frames = Received<[Double]>()
                s.start {
                    NavigationSplitView(State(wrappedValue: true).projectedValue) {
                        Text("Sidebar")
                    } detail: { WideDetail(Text("Detail").onEvent(ViewContract.frameChanged) { frames.values.append($0) }) }
                }
                s.settle { Aspects.laidOut(frames) }
                s.expect(Aspects.laidOut(frames), true, "its detail laid out in the window")
            },
            ConformanceCase("theSidebarStandsBesideTheDetail", proves: [
                Covered(NavigationSplitViewContract.isSidebarVisible),
            ]) { s in
                s.start {
                    NavigationSplitView(State(wrappedValue: true).projectedValue) {
                        Text("Sidebar").id("sidebar")
                    } detail: { WideDetail(Text("Detail").id("detail")) }
                }
                let split = try s.element(ofType: NavigationSplitViewContract.nodeType)

                try s.settle { try s.held(NavigationSplitViewContract.isSidebarVisible, on: split) == true }
                s.expect(try s.held(VisualElementContract.isVisible, on: s.element("detail")), true)
                s.expect(try s.held(NavigationSplitViewContract.isSidebarVisible, on: split), true)
            },
            ConformanceCase("theUsersHidingIsHeardOnTheBinding", proves: [
                Covered(NavigationSplitViewContract.isSidebarVisible), Covered(NavigationSplitViewContract.isSidebarVisibleChanged),
            ]) { s in
                let open = State(wrappedValue: true)
                s.start {
                    NavigationSplitView(open.projectedValue) { Text("Sidebar") } detail: { WideDetail(Text("Detail")) }
                }
                let split = try s.element(ofType: NavigationSplitViewContract.nodeType)
                try s.settle { try s.held(NavigationSplitViewContract.isSidebarVisible, on: split) == true }

                try s.perform(.toggle, on: split)
                s.settle { !open.wrappedValue }
                s.expect(open.wrappedValue, false, "the user hid it")
                s.expect(try s.held(NavigationSplitViewContract.isSidebarVisible, on: split), false)

                try s.perform(.toggle, on: split)
                s.settle { open.wrappedValue }
                s.expect(open.wrappedValue, true, "and showed it again")
            },
            ConformanceCase("theProgramsHidingIsShown", proves: [
                Covered(NavigationSplitViewContract.isSidebarVisible),
            ], needs: [Covered(ButtonContract.clicked)]) { s in
                let open = State(wrappedValue: true)
                s.start {
                    NavigationSplitView(open.projectedValue) {
                        Text("Sidebar")
                    } detail: {
                        WideDetail(VStack { Button("Hide").onClicked { open.wrappedValue = false }.id("hide") })
                    }
                }
                let split = try s.element(ofType: NavigationSplitViewContract.nodeType)
                try s.settle { try s.held(NavigationSplitViewContract.isSidebarVisible, on: split) == true }

                try s.perform(.activate, on: s.element("hide"))
                try s.settle { try s.held(NavigationSplitViewContract.isSidebarVisible, on: split) == false }
                s.expect(try s.held(NavigationSplitViewContract.isSidebarVisible, on: split), false)
            },
        ]
    }
}

/// A split view's detail in a window wide enough for every desktop host to stand the sidebar beside it: in a
/// narrower one a host may lay the sidebar over the detail, and closed.
private struct WideDetail: View {
    let detail: any View

    @Environment private var window: WindowSession

    init(_ detail: any View) {
        self.detail = detail
    }

    var body: some View {
        let window = self.window
        return VStack { detail }
            .onAppear {
                window.width = 1016
                window.height = 700
            }
    }
}
