// swift-tools-version:6.4
import PackageDescription

// The Foundation-bound half of the API surface. The core target holds no
// Foundation, so the spellings an application writes in URL, Date or
// AttributedString live in this sibling: `.onOpenURL`, `TimelineView` and
// `Text(AttributedString)` over the core's Foundation-free machinery. It is
// part of the SwiftOmniUI family - it may touch host SPI internally - but exposes
// only the public SwiftUI-compatible surface.
let package = Package(
    name: "SwiftOmniUIFoundation",
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SwiftOmniUIFoundation", type: .dynamic, targets: ["SwiftOmniUIFoundation"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIFoundation",
            dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUICore")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIFoundationTests",
            dependencies: ["SwiftOmniUIFoundation"],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
