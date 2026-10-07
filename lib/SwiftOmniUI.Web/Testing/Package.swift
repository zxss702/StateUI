// swift-tools-version:6.4
import PackageDescription

// The Web host's own suite and its conformance run: XCTest compiled to WebAssembly, which .scripts/Web/test-web.sh
// runs in Node over a page with just enough of a DOM (JavaScript/page.mjs) - and, for the conformance suite, in a
// browser (JavaScript/run-in-browser.mjs) - the host's own relay beneath it, and the driver's functions reading what
// the page holds, which CWebTesting declares. It builds under SWIFTOMNIUI_HOST=web, which links every library into the
// one module.
let package = Package(
    name: "SwiftOmniUIWebTesting",
    // Fork: the host packages' macOS minimum, so the suite can also compile here. The WASI run ignores this.
    platforms: [.macOS("26.0")],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIHost", path: "../../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../../SwiftOmniUI.Conformance"),
        .package(name: "SwiftOmniUIWeb", path: ".."),
    ],
    targets: [
        // The driver's functions, and nothing else.
        .systemLibrary(name: "CWebTesting", path: "Sources/CWebTesting"),
        .testTarget(
            name: "SwiftOmniUIWebTests",
            dependencies: [
                "CWebTesting", .product(name: "SwiftOmniUIWeb", package: "SwiftOmniUIWeb"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"), .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
            ],
            path: "Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            // The stack a Web head links with: 8 MB, first in memory (docs/design/platforms/web/runtime.md#the-stack).
            linkerSettings: [.unsafeFlags([
                "-Xlinker", "--export-table", "-Xlinker", "--stack-first",
                "-Xlinker", "-z", "-Xlinker", "stack-size=8388608", "-Xlinker", "--global-base=8388608",
            ])]
        ),
    ]
)
