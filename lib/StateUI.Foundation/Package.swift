// swift-tools-version:6.4
import PackageDescription

// The Foundation-bound half of the API surface. The core target holds no
// Foundation, so the spellings an application writes in URL, Date or
// AttributedString live in this sibling: `.onOpenURL`, `TimelineView` and
// `Text(AttributedString)` over the core's Foundation-free machinery. It is
// part of the StateUI family - it may touch host SPI internally - but exposes
// only the public SwiftUI-compatible surface.
let package = Package(
    name: "StateUIFoundation",
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "StateUIFoundation", type: .dynamic, targets: ["StateUIFoundation"]),
    ],
    dependencies: [
        .package(name: "StateUIRoot", path: "../.."),
    ],
    targets: [
        .target(
            name: "StateUIFoundation",
            dependencies: [.product(name: "StateUI", package: "StateUIRoot")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "StateUIFoundationTests",
            dependencies: ["StateUIFoundation"],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
