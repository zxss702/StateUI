// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

#if os(macOS)
import AppKit
@_spi(Host) @testable import StateUI
@_spi(Host) @testable import StateUIHost
@testable import StateUIAppKit
import XCTest

/// The view a representable stands for: it records what it is asked.
private final class ProbeView: NSView {
    /// What `makeNSView`/`updateNSView` last copied over.
    var appliedTitle = ""

    /// How often `updateNSView` ran.
    var updates = 0

    /// The coordinators both callbacks were handed.
    var coordinators: [AnyObject] = []
}

/// A representable of the plainest shape: a string in, copied onto the view.
private struct Probe: NSViewRepresentable {
    /// What the view should say.
    let title: String

    /// The coordinator: an object, so the test can count how many were made.
    final class Marker {}

    func makeCoordinator() -> Marker { Marker() }

    func makeNSView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.appliedTitle = title
        view.coordinators = [context.coordinator]
        return view
    }

    func updateNSView(_ nsView: ProbeView, context: Context) {
        nsView.updates += 1
        nsView.appliedTitle = title
        nsView.coordinators.append(context.coordinator)
    }
}

/// The page under test, lending the representable its input.
private struct RepresentingPage: View {
    @Binding var title: String

    var body: some View {
        Probe(title: title)
    }
}

/// An application's view, standing inside this host's tree.
final class AppKitRepresentableTests: XCTestCase {
    /// Pumps until `done` holds.
    @MainActor
    private func settle(_ renderer: AppKitRenderer, until done: () -> Bool) {
        for _ in 0..<150 where !done() {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
            renderer.runtime.pump.turn()
        }
    }

    /// The element's container, made through the contract's registration.
    @MainActor
    private func container(_ renderer: AppKitRenderer) -> RepresentableContainerView? {
        renderer.nativeViews(RepresentableContainerView.self).first
    }

    /// `makeNSView` ran where the element mounted, and the container holds
    /// the view it made.
    @MainActor
    func testAMountMakesTheRepresentableViewInsideItsContainer() {
        let title = State("first")

        let renderer = AppKitRenderer.running { RepresentingPage(title: title.projectedValue) }
        defer { renderer.closeForTesting() }
        settle(renderer) { container(renderer)?.subviews.first is ProbeView }

        let probe = container(renderer)?.subviews.first as? ProbeView
        XCTAssertEqual(probe?.appliedTitle, "first")
    }

    /// A rebuild hands `updateNSView` the value it now is, through the same
    /// coordinator `makeNSView` was given.
    @MainActor
    func testARebuildUpdatesTheViewWithTheSameCoordinator() {
        let title = State("first")

        let renderer = AppKitRenderer.running { RepresentingPage(title: title.projectedValue) }
        defer { renderer.closeForTesting() }
        settle(renderer) { container(renderer)?.subviews.first is ProbeView }
        let probe = container(renderer)?.subviews.first as? ProbeView
        let made = probe?.updates ?? 0

        title.wrappedValue = "second"
        settle(renderer) { (probe?.updates ?? 0) > made }

        XCTAssertEqual(probe?.appliedTitle, "second")
        XCTAssertEqual(probe?.coordinators.count, (probe?.updates ?? 0) + 1)
        XCTAssertTrue(probe?.coordinators.allSatisfy { $0 === probe?.coordinators.first } ?? false)
    }
}
#endif
